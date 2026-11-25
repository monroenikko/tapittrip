<?php

declare(strict_types=1);

namespace App\Services\Storage;

use Illuminate\Http\Response;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

final class EncryptedAttachmentService
{
    public const ALLOWED_MIME_TYPES = [
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
    ];

    public const MAX_BYTES = 10485760; // 10 MB

    /**
     * Validate, encrypt at rest, and persist an uploaded binary file to private local storage.
     *
     * @return array{file_path: string, original_filename: string, mime_type: string, file_size_bytes: int, file_encrypted: bool}
     */
    public function storeEncrypted(UploadedFile $file, string $directory): array
    {
        $mimeType = $file->getMimeType() ?: $file->getClientMimeType() ?: 'application/octet-stream';
        $sizeBytes = (int) ($file->getSize() ?: 0);

        if (! in_array($mimeType, self::ALLOWED_MIME_TYPES, true)) {
            throw ValidationException::withMessages([
                'file' => ['Unsupported file format. Allowed formats: PDF, JPG, PNG, WEBP, HEIC.'],
            ]);
        }

        if ($sizeBytes <= 0 || $sizeBytes > self::MAX_BYTES) {
            throw ValidationException::withMessages([
                'file' => ['File must be between 1 byte and 10 MB.'],
            ]);
        }

        $rawBytes = $file->get();
        $encryptedPayload = Crypt::encryptString($rawBytes);

        $safeDirectory = trim($directory, '/');
        $path = "{$safeDirectory}/".Str::uuid().'.enc';

        $written = Storage::disk('local')->put($path, $encryptedPayload);
        if (! $written) {
            throw new \RuntimeException('Failed to store encrypted attachment.');
        }

        return [
            'file_path' => $path,
            'original_filename' => $this->sanitizeFilename($file->getClientOriginalName()),
            'mime_type' => $mimeType,
            'file_size_bytes' => $sizeBytes,
            'file_encrypted' => true,
        ];
    }

    /**
     * Decrypt and return a private binary file HTTP response with strict security headers.
     */
    public function downloadDecrypted(
        string $filePath,
        string $originalFilename,
        string $mimeType,
        bool $isEncrypted = true,
    ): Response {
        if (! Storage::disk('local')->exists($filePath)) {
            abort(404, 'Encrypted attachment not found.');
        }

        $storedContents = (string) Storage::disk('local')->get($filePath);
        $rawBytes = $isEncrypted ? Crypt::decryptString($storedContents) : $storedContents;
        $safeFilename = $this->sanitizeFilename($originalFilename);

        return response($rawBytes, 200, [
            'Content-Type' => $mimeType,
            'Content-Disposition' => 'inline; filename="'.$safeFilename.'"',
            'Cache-Control' => 'private, no-store, max-age=0',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /**
     * Remove a stored encrypted attachment from private storage.
     */
    public function deleteFile(?string $filePath): void
    {
        if ($filePath !== null && $filePath !== '' && Storage::disk('local')->exists($filePath)) {
            Storage::disk('local')->delete($filePath);
        }
    }

    private function sanitizeFilename(string $filename): string
    {
        $base = basename($filename);
        $cleaned = preg_replace('/[^A-Za-z0-9._ -]/', '_', $base) ?? 'attachment';
        $cleaned = trim($cleaned);

        return $cleaned !== '' ? mb_substr($cleaned, 0, 200) : 'attachment';
    }
}
