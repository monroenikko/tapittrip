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
        Schema::create('media_attachments', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')
                ->constrained('trips')
                ->cascadeOnDelete();
            $table->string('attachable_type')->nullable(); // checklist_item, stay, itinerary_item, trip_document
            $table->uuid('attachable_id')->nullable();
            $table->foreignUuid('uploaded_by_id')
                ->constrained('users')
                ->cascadeOnDelete();
            $table->string('original_filename');
            $table->string('file_path');
            $table->string('mime_type');
            $table->unsignedBigInteger('file_size_bytes');
            $table->string('title')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index('trip_id');
            $table->index(['attachable_type', 'attachable_id']);
            $table->index('uploaded_by_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('media_attachments');
    }
};
