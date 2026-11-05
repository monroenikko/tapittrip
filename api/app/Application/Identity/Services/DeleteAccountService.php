<?php

declare(strict_types=1);

namespace App\Application\Identity\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;

final class DeleteAccountService
{
    public function handle(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $user->tokens()->delete();
            $user->delete();
        });
    }
}
