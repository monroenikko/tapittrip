<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Journal;

use App\Domain\Journal\Models\JournalEntry;
use Illuminate\Foundation\Http\FormRequest;

final class UploadJournalPhotoRequest extends FormRequest
{
    public function authorize(): bool
    {
        /** @var JournalEntry|null $entry */
        $entry = $this->route('entry');

        if (! $entry instanceof JournalEntry) {
            return false;
        }

        $user = $this->user();
        if ($user === null) {
            return false;
        }

        return $entry->trip->members()->where('user_id', $user->id)->exists();
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'photo' => ['required', 'file', 'mimes:jpeg,png,webp,jpg', 'max:10240'],
        ];
    }
}
