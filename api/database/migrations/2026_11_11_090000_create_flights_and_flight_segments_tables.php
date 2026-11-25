<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('flights', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->text('airline')->nullable();
            $table->text('booking_reference')->nullable();
            $table->uuid('client_operation_id')->nullable();
            $table->unsignedBigInteger('version')->default(1);
            $table->timestamps();
            $table->index(['trip_id', 'created_at']);
            $table->unique(['trip_id', 'client_operation_id']);
        });

        Schema::create('flight_segments', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('flight_id')->constrained('flights')->cascadeOnDelete();
            $table->text('flight_number');
            $table->string('origin_airport', 3);
            $table->string('destination_airport', 3);
            $table->timestampTz('scheduled_departure_utc');
            $table->timestampTz('scheduled_arrival_utc');
            $table->text('origin_timezone');
            $table->text('destination_timezone');
            $table->text('terminal')->nullable();
            $table->text('gate')->nullable();
            $table->timestamps();
            $table->index(['flight_id', 'scheduled_departure_utc']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('flight_segments');
        Schema::dropIfExists('flights');
    }
};
