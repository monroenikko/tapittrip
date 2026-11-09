<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Journal;

use App\Domain\Journal\Models\JournalEntry;
use Illuminate\Foundation\Http\FormRequest;

final class UpdateJournalEntryRequest extends FormRequest
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
            'title' => ['nullable', 'string', 'max:255'],
            'content' => ['nullable', 'string'],
            'entry_date' => ['nullable', 'date'],
            'location_name' => ['nullable', 'string', 'max:255'],
            'weather' => ['nullable', 'string', 'max:64'],
            'mood' => ['nullable', 'string', 'max:32'],
            'is_shared' => ['nullable', 'boolean'],
            'itinerary_item_id' => ['nullable', 'uuid', 'exists:itinerary_items,id'],
            'photos' => ['nullable', 'array'],
            'photos.*' => ['string'],
        ];
    }
}
