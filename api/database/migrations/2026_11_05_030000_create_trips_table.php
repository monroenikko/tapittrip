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
        Schema::create('trips', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('title');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->string('primary_timezone', 64)->default('UTC');
            $table->string('origin_country', 2)->nullable();
            $table->string('destination_country', 2)->nullable();
            $table->string('trip_type', 32)->default('leisure');
            $table->string('planning_mode', 32)->default('diy');
            $table->string('status', 32)->default('planned');
            $table->unsignedBigInteger('version')->default(1);
            $table->timestamps();
            $table->softDeletes();

            $table->index('owner_id');
            $table->index('status');
            $table->index('planning_mode');
        });

        Schema::create('trip_members', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('role', 32)->default('viewer');
            $table->string('invitation_status', 32)->default('accepted');
            $table->timestamps();

            $table->unique(['trip_id', 'user_id']);
            $table->index('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trip_members');
        Schema::dropIfExists('trips');
    }
};
