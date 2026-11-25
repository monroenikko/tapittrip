<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notification_preferences', function (Blueprint $table): void {
            $table->boolean('circle_announcements_enabled')->default(true)->after('expense_updates_enabled');
        });

        Schema::create('trip_announcements', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('author_id')->constrained('users')->cascadeOnDelete();
            $table->string('title', 160);
            $table->text('body');
            $table->boolean('is_pinned')->default(false);
            $table->uuid('client_operation_id')->nullable();
            $table->unsignedBigInteger('version')->default(1);
            $table->timestampsTz();
            $table->softDeletes();

            $table->unique(['trip_id', 'client_operation_id']);
            $table->index(['trip_id', 'is_pinned', 'created_at']);
        });

        Schema::create('trip_notifications', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('announcement_id')->nullable()->constrained('trip_announcements')->cascadeOnDelete();
            $table->string('category', 64);
            $table->string('title', 180);
            $table->text('body');
            $table->timestampTz('scheduled_for_utc')->nullable();
            $table->string('timezone', 64)->default('UTC');
            $table->string('trip_local_time_label', 64)->nullable();
            $table->string('status', 32)->default('pending');
            $table->string('dedupe_key', 160);
            $table->timestampTz('read_at')->nullable();
            $table->timestampsTz();
            $table->softDeletes();

            $table->unique(['user_id', 'dedupe_key']);
            $table->index(['user_id', 'status', 'created_at']);
            $table->index(['trip_id', 'user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trip_notifications');
        Schema::dropIfExists('trip_announcements');

        Schema::table('notification_preferences', function (Blueprint $table): void {
            $table->dropColumn('circle_announcements_enabled');
        });
    }
};
