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
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('itinerary_item_id')->nullable()->constrained('itinerary_items')->nullOnDelete();
            $table->string('title');
            $table->text('content');
            $table->date('entry_date');
            $table->string('location_name')->nullable();
            $table->string('weather', 64)->nullable();
            $table->string('mood', 32)->nullable();
            $table->boolean('is_shared')->default(false);
            $table->jsonb('photos')->default('[]');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['trip_id', 'entry_date']);
            $table->index(['user_id', 'is_shared']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('journal_entries');
    }
};
