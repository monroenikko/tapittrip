<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_imports', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('source', 32)->default('paste_text');
            $table->string('booking_type', 32)->default('flight');
            $table->text('raw_text')->nullable();
            $table->string('extraction_status', 32)->default('extracted');
            $table->text('extracted_data')->nullable();
            $table->decimal('confidence_score', 4, 2)->default(0.95);
            $table->string('confirmed_entity_type', 32)->nullable();
            $table->uuid('confirmed_entity_id')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('error_message')->nullable();
            $table->uuid('client_operation_id')->nullable();
            $table->unsignedBigInteger('version')->default(1);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['trip_id', 'created_at']);
            $table->index(['trip_id', 'user_id']);
            $table->unique(['trip_id', 'client_operation_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_imports');
    }
};
