<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            throw new RuntimeException('The TapItTrip schema requires PostgreSQL.');
        }

        // Injective mapping of legacy bigint IDs preserves existing session references.
        DB::statement('ALTER TABLE users ALTER COLUMN id DROP DEFAULT');
        DB::statement("ALTER TABLE users ALTER COLUMN id TYPE uuid USING lpad(to_hex(id), 32, '0')::uuid");
        DB::statement("ALTER TABLE sessions ALTER COLUMN user_id TYPE uuid USING lpad(to_hex(user_id), 32, '0')::uuid");
        DB::statement('ALTER TABLE sessions ADD CONSTRAINT sessions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        throw new RuntimeException('UUID identities cannot safely return to bigint after new writes; use a forward migration.');
    }
};
