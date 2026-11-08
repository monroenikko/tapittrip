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
        Schema::create('sync_cursors', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('device_key');
            $table->foreignUuid('trip_id')->nullable()->constrained('trips')->cascadeOnDelete();
            $table->bigInteger('last_server_sequence')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'device_key', 'trip_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sync_cursors');
    }
};
