<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('travel_documents', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('document_type', 40);
            $table->string('display_name', 160);
            $table->string('issuer', 160)->nullable();
            $table->text('reference_number')->nullable();
            $table->text('notes_private')->nullable();
            $table->date('expires_on')->nullable();
            $table->string('access_policy', 32)->default('owner_only');
            $table->uuid('client_operation_id')->nullable();
            $table->unsignedBigInteger('version')->default(1);
            $table->timestamps();

            $table->index(['trip_id', 'owner_id']);
            $table->unique(['trip_id', 'client_operation_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('travel_documents');
    }
};
