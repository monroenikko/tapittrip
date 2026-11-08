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
        Schema::create('visit_events', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('itinerary_item_id')->constrained('itinerary_items')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('event_type'); // suggested, confirmed, revoked
            $table->string('method')->default('manual'); // manual, geofence
            $table->timestampTz('detected_at');
            $table->float('accuracy_m')->nullable();
            $table->timestamps();

            $table->index(['itinerary_item_id', 'event_type']);
            $table->index(['user_id', 'detected_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('visit_events');
    }
};

