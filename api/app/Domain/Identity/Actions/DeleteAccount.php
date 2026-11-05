<?php

declare(strict_types=1);

namespace App\Domain\Identity\Actions;

use App\Models\User;
use Illuminate\Support\Facades\DB;

final class DeleteAccount
{
    /**
     * Delete user account and revoke all tokens.
     */
    public function handle(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $user->tokens()->delete();
            $user->delete();
        });
    }
}

