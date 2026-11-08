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
        Schema::create('user_devices', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('platform'); // ios, android, web
            $table->string('device_key');
            $table->text('push_token')->nullable();
            $table->timestampTz('last_seen_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'device_key']);
            $table->index(['platform', 'device_key']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_devices');
    }
};

