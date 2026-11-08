<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Application\Expenses\Data\RecordSettlementData;
use App\Domain\Expenses\Models\ExpenseSettlement;
use App\Domain\Trips\Models\Trip;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Validation\ValidationException;

final class RecordSettlementService
{
    /**
     * Record a debt settlement between two trip companions.
     */
    public function execute(Trip $trip, User $actor, RecordSettlementData $data): ExpenseSettlement
    {
        // 1. Authorize actor
        if (! $trip->hasMember($actor) && $trip->owner_id !== $actor->id) {
            throw new AuthorizationException('You are not authorized to record settlements for this trip.');
        }

        // 2. Validate payer and payee are distinct
        if ($data->payerId === $data->payeeId) {
            throw ValidationException::withMessages([
                'payee_id' => ['The payer and payee must be different travelers.'],
            ]);
        }

        // 3. Validate payer is a trip member
        if (! $trip->hasMember($data->payerId) && $trip->owner_id !== $data->payerId) {
            throw ValidationException::withMessages([
                'payer_id' => ['The selected payer is not a member of this trip.'],
            ]);
        }

        // 4. Validate payee is a trip member
        if (! $trip->hasMember($data->payeeId) && $trip->owner_id !== $data->payeeId) {
            throw ValidationException::withMessages([
                'payee_id' => ['The selected payee is not a member of this trip.'],
            ]);
        }

        // 5. Amount validation
        if ($data->amountMinor <= 0) {
            throw ValidationException::withMessages([
                'amount_minor' => ['The settlement amount must be greater than zero.'],
            ]);
        }

        /** @var ExpenseSettlement $settlement */
        $settlement = ExpenseSettlement::create([
            'trip_id' => $trip->id,
            'payer_id' => $data->payerId,
            'payee_id' => $data->payeeId,
            'amount_minor' => $data->amountMinor,
            'currency' => $data->currency,
            'settled_at' => $data->settledAt,
            'notes' => $data->notes,
        ]);

        return $settlement->load(['payer', 'payee']);
    }
}
