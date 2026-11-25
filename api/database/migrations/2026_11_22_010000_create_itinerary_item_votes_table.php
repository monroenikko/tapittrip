<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('itinerary_item_votes', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('itinerary_item_id')->constrained('itinerary_items')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('vote', 8);
            $table->timestamps();

            $table->unique(['itinerary_item_id', 'user_id']);
            $table->index(['trip_id', 'itinerary_item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('itinerary_item_votes');
    }
};
