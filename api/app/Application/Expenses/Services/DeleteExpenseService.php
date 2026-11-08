<?php

declare(strict_types=1);

namespace App\Application\Expenses\Services;

use App\Domain\Expenses\Models\Expense;
use Illuminate\Support\Facades\DB;

final class DeleteExpenseService
{
    /**
     * Soft delete an expense.
     */
    public function execute(Expense $expense): bool
    {
        return DB::transaction(function () use ($expense) {
            return (bool) $expense->delete();
        });
    }
}
