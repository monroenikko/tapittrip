<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1\Journal;

use App\Domain\Trips\Models\Trip;
use Illuminate\Foundation\Http\FormRequest;

final class CreateJournalEntryRequest extends FormRequest
{
    public function authorize(): bool
    {
        /** @var Trip|null $trip */
        $trip = $this->route('trip');

        if (! $trip instanceof Trip) {
            return false;
        }

        $user = $this->user();
        if ($user === null) {
            return false;
        }

        return $trip->members()->where('user_id', $user->id)->exists();
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'entry_date' => ['required', 'date'],
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
