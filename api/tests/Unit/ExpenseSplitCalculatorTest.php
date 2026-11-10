<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Domain\Expenses\ExpenseSplitCalculator;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

final class ExpenseSplitCalculatorTest extends TestCase
{
    public function test_equal_allocation_distributes_remainder_without_losing_minor_units(): void
    {
        $shares = ExpenseSplitCalculator::allocateEqual(1000, ['u1', 'u2', 'u3']);

        $this->assertSame([
            'u1' => 334,
            'u2' => 333,
            'u3' => 333,
        ], $shares);
        $this->assertSame(1000, array_sum($shares));
    }

    public function test_proportional_allocation_preserves_exact_target_minor_total(): void
    {
        // Two 1000-unit shares scaled into an odd 1351-cent target must sum to 1351, not 1352.
        $baseShares = ExpenseSplitCalculator::allocateProportional(1351, [
            'alice' => 1000,
            'bob' => 1000,
        ]);

        $this->assertSame(1351, array_sum($baseShares));
        $this->assertSame(['alice' => 676, 'bob' => 675], $baseShares);
    }

    public function test_proportional_allocation_breaks_fractional_ties_deterministically(): void
    {
        $baseShares = ExpenseSplitCalculator::allocateProportional(2027, [
            'alice' => 2000,
            'bob' => 1000,
        ]);

        // 2000/3000 * 2027 = 1351.333..., 1000/3000 * 2027 = 675.666... -> 1351 + 676 = 2027
        $this->assertSame(['alice' => 1351, 'bob' => 676], $baseShares);
        $this->assertSame(2027, array_sum($baseShares));
    }

    public function test_empty_participants_throw_invalid_argument_exception(): void
    {
        $this->expectException(InvalidArgumentException::class);
        ExpenseSplitCalculator::allocateEqual(500, []);
    }
}
