<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement('CREATE SEQUENCE IF NOT EXISTS sync_server_sequence START WITH 1 INCREMENT BY 1');

        Schema::create('sync_operations', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->uuid('operation_id')->unique();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('trip_id')->nullable()->constrained('trips')->cascadeOnDelete();
            $table->string('device_key');
            $table->string('entity_type'); // trip, itinerary_item, stay, checklist_item
            $table->uuid('entity_id');
            $table->string('operation_type'); // create, update, delete
            $table->jsonb('payload')->nullable();
            $table->integer('base_version')->default(1);
            $table->bigInteger('server_sequence')->default(DB::raw("nextval('sync_server_sequence')"))->index();
            $table->string('status')->default('accepted'); // accepted, conflict, rejected
            $table->jsonb('conflict_details')->nullable();
            $table->timestampTz('processed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'trip_id', 'server_sequence']);
            $table->index(['entity_type', 'entity_id']);
        });

        // Grant permissions to runtime user
        try {
            DB::statement('GRANT USAGE, SELECT ON SEQUENCE sync_server_sequence TO tapittrip_runtime');
        } catch (Throwable $e) {
            // Ignore if role does not exist in local/CI environment
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sync_operations');
        DB::statement('DROP SEQUENCE IF EXISTS sync_server_sequence');
    }
};
