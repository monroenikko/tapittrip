<?php

declare(strict_types=1);

namespace App\Domain\Expenses;

use InvalidArgumentException;

final class ExpenseSplitCalculator
{
    /** @var list<string> */
    public const SPLIT_TYPES = ['single', 'equal', 'selected', 'custom'];

    /** @var list<string> */
    public const VISIBILITIES = ['private', 'shared'];

    /**
     * Split a positive integer minor-unit total equally across ordered unique participant IDs.
     * Any integer remainder is distributed +1 minor unit at a time to the earliest participants.
     *
     * @param  list<string>  $participantIds
     * @return array<string, int>
     */
    public static function allocateEqual(int $totalMinor, array $participantIds): array
    {
        if ($totalMinor <= 0) {
            throw new InvalidArgumentException('Total minor amount must be greater than zero.');
        }

        $orderedIds = array_values(array_unique(array_filter(
            array_map('strval', $participantIds),
            static fn (string $id): bool => $id !== '',
        )));

        $count = count($orderedIds);
        if ($count === 0) {
            throw new InvalidArgumentException('At least one participant is required for an expense split.');
        }

        $baseShare = intdiv($totalMinor, $count);
        $remainder = $totalMinor % $count;

        $result = [];
        foreach ($orderedIds as $index => $userId) {
            $result[$userId] = $baseShare + ($index < $remainder ? 1 : 0);
        }

        return $result;
    }

    /**
     * Proportionally convert per-participant minor-unit shares into a target base-currency total
     * using largest-remainder allocation so that array_sum($allocated) === $targetTotalMinor.
     *
     * @param  array<string, int>  $sourceSharesByUser
     * @return array<string, int>
     */
    public static function allocateProportional(int $targetTotalMinor, array $sourceSharesByUser): array
    {
        if ($sourceSharesByUser === []) {
            throw new InvalidArgumentException('Source shares cannot be empty.');
        }

        $sourceTotal = array_sum($sourceSharesByUser);
        if ($sourceTotal <= 0) {
            throw new InvalidArgumentException('Source shares must sum to a positive amount.');
        }

        if ($targetTotalMinor < 0) {
            throw new InvalidArgumentException('Target total minor amount cannot be negative.');
        }

        if ($targetTotalMinor === 0) {
            return array_fill_keys(array_keys($sourceSharesByUser), 0);
        }

        $allocated = [];
        $remainders = [];
        $orderIndex = 0;

        foreach ($sourceSharesByUser as $userId => $share) {
            $exactNumerator = $share * $targetTotalMinor;
            $floorValue = intdiv($exactNumerator, $sourceTotal);
            $allocated[(string) $userId] = $floorValue;
            $remainders[] = [
                'user_id' => (string) $userId,
                'remainder' => $exactNumerator % $sourceTotal,
                'order' => $orderIndex++,
            ];
        }

        $remainingMinor = $targetTotalMinor - array_sum($allocated);
        if ($remainingMinor > 0) {
            usort($remainders, static function (array $a, array $b): int {
                if ($b['remainder'] !== $a['remainder']) {
                    return $b['remainder'] <=> $a['remainder'];
                }

                return $a['order'] <=> $b['order'];
            });

            for ($i = 0; $i < $remainingMinor; $i++) {
                $uid = $remainders[$i]['user_id'];
                $allocated[$uid]++;
            }
        }

        return $allocated;
    }
}
