<?php

declare(strict_types=1);

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
        Schema::create('trip_location_shares', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->boolean('enabled')->default(false);
            $table->unsignedInteger('duration_minutes')->default(60);
            $table->timestampTz('expires_at')->nullable();
            $table->string('audience', 32)->default('circle');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->timestampTz('last_shared_at')->nullable();
            $table->timestamps();

            $table->unique(['trip_id', 'user_id']);
        });

        DB::statement(
            'ALTER TABLE trip_location_shares
                ADD CONSTRAINT trip_location_shares_duration_check
                CHECK (duration_minutes IN (60, 240, 480, 1440))',
        );
        DB::statement(
            "ALTER TABLE trip_location_shares
                ADD CONSTRAINT trip_location_shares_audience_check
                CHECK (audience IN ('circle', 'organizer_only'))",
        );
        DB::statement(
            'ALTER TABLE trip_location_shares
                ADD CONSTRAINT trip_location_shares_coordinate_pair_check
                CHECK (
                    (latitude IS NULL AND longitude IS NULL)
                    OR (latitude IS NOT NULL AND longitude IS NOT NULL)
                )',
        );
        DB::statement(
            'ALTER TABLE trip_location_shares
                ADD CONSTRAINT trip_location_shares_coordinate_bounds_check
                CHECK (
                    latitude BETWEEN -90 AND 90
                    AND longitude BETWEEN -180 AND 180
                    OR (latitude IS NULL AND longitude IS NULL)
                )',
        );
        DB::statement(
            'ALTER TABLE trip_location_shares
                ADD CONSTRAINT trip_location_shares_enabled_coordinates_check
                CHECK (enabled = false OR (latitude IS NOT NULL AND longitude IS NOT NULL))',
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trip_location_shares');
    }
};
