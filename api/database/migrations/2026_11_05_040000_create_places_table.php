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
        Schema::create('places', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('provider', 32)->default('manual');
            $table->string('provider_place_id')->nullable();
            $table->string('name');
            $table->text('formatted_address')->nullable();
            $table->string('country_code', 2)->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('photo_reference')->nullable();
            $table->text('attribution')->nullable();
            $table->timestamp('last_refreshed_at')->nullable();
            $table->timestamps();

            $table->index(['provider', 'provider_place_id']);
            $table->index('name');
            $table->index('country_code');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('places');
    }
};
