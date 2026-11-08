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
        Schema::create('reminders', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('itinerary_item_id')->nullable()->constrained('itinerary_items')->cascadeOnDelete();
            $table->foreignUuid('checklist_id')->nullable()->constrained('checklists')->cascadeOnDelete();
            $table->string('type'); // morning_summary, activity_reminder, departure_checklist, stay_checkin, stay_checkout, custom
            $table->string('title');
            $table->text('body');
            $table->timestampTz('trigger_at_utc');
            $table->string('timezone');
            $table->string('delivery_channel')->default('local'); // local, push, both
            $table->string('status')->default('scheduled'); // scheduled, cancelled, delivered, dismissed
            $table->string('dedupe_key')->index();
            $table->integer('source_version')->default(1);
            $table->timestamps();

            $table->index(['trip_id', 'status', 'trigger_at_utc']);
            $table->unique(['trip_id', 'dedupe_key']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reminders');
    }
};

