<?php

namespace Tests\Migration;

use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class UserUuidMigrationTest extends TestCase
{
    public function test_upgrade_preserves_existing_user_and_session_relationships(): void
    {
        $this->assertSame('tapittrip_test', DB::selectOne('select current_database() as name')->name);
        $this->assertSame('tapittrip_migrator', DB::selectOne('select current_user as name')->name);
        DB::beginTransaction();

        try {
            DB::statement('SET LOCAL search_path TO uuid_upgrade_probe');
            DB::statement('CREATE TABLE users (id bigserial PRIMARY KEY, name text NOT NULL)');
            DB::statement('CREATE TABLE sessions (id text PRIMARY KEY, user_id bigint)');
            DB::table('users')->insert(['id' => 42, 'name' => 'Synthetic traveler']);
            DB::table('sessions')->insert(['id' => 'legacy-session', 'user_id' => 42]);

            $migration = require database_path('migrations/2026_11_04_150410_convert_scaffold_user_keys_to_uuid.php');
            $migration->up();

            $user = DB::table('users')->first();
            $this->assertSame('00000000-0000-0000-0000-00000000002a', $user->id);
            $this->assertSame('Synthetic traveler', $user->name);
            $this->assertSame($user->id, DB::table('sessions')->first()->user_id);
        } finally {
            DB::rollBack();
        }
    }
}
