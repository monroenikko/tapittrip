<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('airports', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('iata_code', 3)->unique();
            $table->string('name');
            $table->string('city');
            $table->string('country');
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('timezone')->default('UTC');
            $table->timestamps();
        });

        Schema::create('airport_terminals', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('airport_id')->constrained('airports')->cascadeOnDelete();
            $table->string('name');
            $table->string('code', 10);
            $table->timestamps();

            $table->unique(['airport_id', 'code']);
        });

        Schema::create('airport_lounges', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('airport_id')->constrained('airports')->cascadeOnDelete();
            $table->foreignUuid('terminal_id')->constrained('airport_terminals')->cascadeOnDelete();
            $table->string('name');
            $table->string('operator');
            $table->text('location_description');
            $table->boolean('is_airside')->default(true);
            $table->jsonb('opening_hours')->nullable();
            $table->jsonb('amenities')->nullable();
            $table->jsonb('access_methods')->nullable();
            $table->jsonb('estimated_price')->nullable();
            $table->string('booking_url')->nullable();
            $table->text('transit_warning')->nullable();
            $table->text('disclaimer')->nullable();
            $table->timestamps();

            $table->index(['airport_id', 'terminal_id']);
            $table->index(['airport_id', 'is_airside']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('airport_lounges');
        Schema::dropIfExists('airport_terminals');
        Schema::dropIfExists('airports');
    }
};
