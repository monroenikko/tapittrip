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
        Schema::create('notification_preferences', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->unique()->constrained('users')->cascadeOnDelete();
            $table->boolean('morning_summary_enabled')->default(true);
            $table->string('morning_summary_time')->default('08:00');
            $table->boolean('activity_reminders_enabled')->default(true);
            $table->integer('activity_reminder_lead_minutes')->default(30);
            $table->boolean('checklist_reminders_enabled')->default(true);
            $table->boolean('stay_reminders_enabled')->default(true);
            $table->boolean('quiet_hours_enabled')->default(false);
            $table->string('quiet_hours_start')->nullable()->default('22:00');
            $table->string('quiet_hours_end')->nullable()->default('07:00');
            $table->boolean('geofence_arrival_enabled')->default(true);
            $table->string('timezone_behavior')->default('destination');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification_preferences');
    }
};

