<?php

declare(strict_types=1);

namespace App\Application\Media\Services;

use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Media\Models\MediaAttachment;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

final class DeleteMediaService
{
    /**
     * Delete a media attachment and remove the physical file.
     */
    public function handle(MediaAttachment $attachment): void
    {
        DB::transaction(function () use ($attachment): void {
            if ($attachment->attachable_type === 'checklist_item' && $attachment->attachable_id !== null) {
                /** @var ChecklistItem|null $item */
                $item = ChecklistItem::query()->find($attachment->attachable_id);
                if ($item && $item->photo_url === $attachment->url) {
                    $item->update([
                        'photo_url' => null,
                        'version' => $item->version + 1,
                    ]);
                }
            }

            // Remove file from disk
            Storage::disk('local')->delete($attachment->file_path);

            $attachment->delete();
        });
    }
}
