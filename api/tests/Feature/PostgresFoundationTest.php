<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class PostgresFoundationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->assertSame('pgsql', DB::getDriverName());
        $this->assertSame('tapittrip_test', DB::selectOne('select current_database() as name')->name);
        $this->assertSame('tapittrip_runtime', DB::selectOne('select current_user as name')->name);
        DB::beginTransaction();
    }

    protected function tearDown(): void
    {
        if (DB::transactionLevel() > 0) {
            DB::rollBack();
        }
        parent::tearDown();
    }

    public function test_runtime_can_persist_uuid_users_and_deletion_cascades_to_sessions(): void
    {
        $user = User::factory()->create();
        DB::table('sessions')->insert([
            'id' => 'synthetic-session', 'user_id' => $user->id,
            'payload' => '', 'last_activity' => 0,
        ]);

        $this->assertTrue(Str::isUuid($user->id));
        $this->assertModelExists($user);
        $user->update(['name' => 'Updated synthetic traveler']);
        $this->assertSame('Updated synthetic traveler', $user->fresh()->name);
        $user->forceDelete();

        $this->assertSame(0, DB::table('sessions')->where('id', 'synthetic-session')->count());
    }

    public function test_sessions_reject_unknown_users(): void
    {
        $this->expectException(QueryException::class);
        $this->expectExceptionCode('23503');
        DB::table('sessions')->insert([
            'id' => 'orphan-session', 'user_id' => (string) Str::uuid(),
            'payload' => '', 'last_activity' => 0,
        ]);
    }

    public function test_runtime_cannot_create_tables(): void
    {
        $this->expectException(QueryException::class);
        $this->expectExceptionCode('42501');
        DB::statement('CREATE TABLE public.forbidden_runtime_probe (id integer)');
    }

    public function test_runtime_cannot_assume_the_migration_role(): void
    {
        $this->expectException(QueryException::class);
        $this->expectExceptionCode('42501');
        DB::statement('SET ROLE tapittrip_migrator');
    }

    public function test_postgis_supports_geography_distance_queries(): void
    {
        $result = DB::selectOne('SELECT ST_DWithin(ST_SetSRID(ST_MakePoint(0, 0), 4326)::geography, ST_SetSRID(ST_MakePoint(0, 1), 4326)::geography, 112000) AS within_range');
        $this->assertTrue($result->within_range);
    }

    public function test_application_has_no_privileged_database_credentials(): void
    {
        $this->assertArrayNotHasKey('pgsql_migration', config('database.connections'));
        $this->assertStringNotContainsString('DB_ADMIN_PASSWORD=', file_get_contents(base_path('.env')));
        $this->assertStringNotContainsString('DB_MIGRATION_PASSWORD=', file_get_contents(base_path('.env')));
        $this->assertFalse(is_file(base_path('../.local/postgres.env')));
        $this->assertFalse(is_file(base_path('../.local/migrate.env')));
    }
}
