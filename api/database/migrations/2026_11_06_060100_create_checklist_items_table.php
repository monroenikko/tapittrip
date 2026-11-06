<?php

declare(strict_types=1);

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
        Schema::create('checklist_items', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('checklist_id')
                ->constrained('checklists')
                ->cascadeOnDelete();
            $table->foreignUuid('trip_id')
                ->constrained('trips')
                ->cascadeOnDelete();
            $table->string('title');
            $table->string('category')->default('other'); // documents, clothing, electronics, toiletries, health, gear, other
            $table->boolean('is_packed')->default(false);
            $table->unsignedInteger('quantity')->default(1);
            $table->text('notes')->nullable();
            $table->string('photo_url')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamp('packed_at')->nullable();
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();

            $table->index('trip_id');
            $table->index('checklist_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('checklist_items');
    }
};
