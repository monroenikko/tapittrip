<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('friend_code', 16)->nullable()->unique()->after('display_name');
            $table->boolean('accepts_direct_invites')->default(true)->after('friend_code');
        });

        // Backfill deterministic unique friend codes for any existing users
        $alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
        $alphabetLen = strlen($alphabet);
        $usedCodes = [];

        $existingUsers = DB::table('users')->select('id', 'friend_code')->get();
        foreach ($existingUsers as $existingUser) {
            if (! empty($existingUser->friend_code)) {
                $usedCodes[(string) $existingUser->friend_code] = true;

                continue;
            }

            do {
                $code = 'TRP-';
                for ($i = 0; $i < 6; $i++) {
                    $code .= $alphabet[random_int(0, $alphabetLen - 1)];
                }
            } while (isset($usedCodes[$code]));

            $usedCodes[$code] = true;
            DB::table('users')
                ->where('id', $existingUser->id)
                ->update(['friend_code' => $code]);
        }

        Schema::table('trip_invitations', function (Blueprint $table): void {
            $table->string('invite_type', 16)->default('link')->after('inviter_id');
            $table->string('token_hash', 64)->nullable()->change();
            $table->foreignUuid('target_user_id')->nullable()->after('token_hash')->constrained('users')->cascadeOnDelete();
            $table->timestampTz('responded_at')->nullable()->after('revoked_at');

            $table->index(['target_user_id', 'status']);
            $table->index(['trip_id', 'invite_type', 'status']);
        });

        Schema::create('user_blocks', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('blocker_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('blocked_id')->constrained('users')->cascadeOnDelete();
            $table->timestampsTz();

            $table->unique(['blocker_id', 'blocked_id']);
            $table->index('blocked_id');
        });

        Schema::create('trip_ownership_transfers', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('from_user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('to_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('former_owner_role', 32)->default('editor');
            $table->string('status', 32)->default('pending');
            $table->timestampTz('expires_at');
            $table->timestampTz('responded_at')->nullable();
            $table->timestampsTz();
            $table->softDeletes();

            $table->index(['trip_id', 'status']);
            $table->index(['to_user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_ownership_transfers');
        Schema::dropIfExists('user_blocks');

        Schema::table('trip_invitations', function (Blueprint $table): void {
            $table->dropIndex(['target_user_id', 'status']);
            $table->dropIndex(['trip_id', 'invite_type', 'status']);
            $table->dropForeign(['target_user_id']);
            $table->dropColumn(['invite_type', 'target_user_id', 'responded_at']);
        });

        DB::table('trip_invitations')->whereNull('token_hash')->delete();

        Schema::table('trip_invitations', function (Blueprint $table): void {
            $table->string('token_hash', 64)->nullable(false)->change();
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->dropUnique(['friend_code']);
            $table->dropColumn(['friend_code', 'accepts_direct_invites']);
        });
    }
};
