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
        Schema::create('itinerary_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('trip_day_id')->nullable()->constrained('trip_days')->nullOnDelete();
            $table->foreignUuid('place_id')->nullable()->constrained('places')->nullOnDelete();
            $table->string('kind', 32)->default('attraction');
            $table->string('title');
            $table->text('notes')->nullable();
            $table->timestamp('starts_at_utc')->nullable();
            $table->timestamp('ends_at_utc')->nullable();
            $table->string('timezone', 64)->default('UTC');
            $table->integer('sort_order')->default(0);
            $table->string('status', 32)->default('planned');
            $table->unsignedBigInteger('version')->default(1);
            $table->timestamps();
            $table->softDeletes();

            $table->index('trip_id');
            $table->index('trip_day_id');
            $table->index('place_id');
            $table->index('sort_order');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('itinerary_items');
    }
};
