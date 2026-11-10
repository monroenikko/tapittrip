<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trip_travelers', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('linked_member_id')->nullable()->constrained('trip_members')->nullOnDelete();
            $table->foreignUuid('managing_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('display_name', 120);
            $table->string('traveler_category', 32)->default('child');
            $table->text('restricted_notes')->nullable();
            $table->unsignedBigInteger('version')->default(1);
            $table->timestampsTz();
            $table->softDeletes();

            $table->index(['trip_id', 'deleted_at']);
            $table->index(['trip_id', 'managing_user_id']);
        });

        Schema::table('checklist_items', function (Blueprint $table): void {
            $table->foreignUuid('assigned_user_id')->nullable()->after('trip_id')->constrained('users')->nullOnDelete();
            $table->foreignUuid('assigned_traveler_id')->nullable()->after('assigned_user_id')->constrained('trip_travelers')->nullOnDelete();
            $table->foreignUuid('completed_by_user_id')->nullable()->after('packed_at')->constrained('users')->nullOnDelete();

            $table->index(['trip_id', 'assigned_user_id']);
            $table->index(['trip_id', 'assigned_traveler_id']);
        });
    }

    public function down(): void
    {
        Schema::table('checklist_items', function (Blueprint $table): void {
            $table->dropIndex(['trip_id', 'assigned_user_id']);
            $table->dropIndex(['trip_id', 'assigned_traveler_id']);
            $table->dropForeign(['assigned_user_id']);
            $table->dropForeign(['assigned_traveler_id']);
            $table->dropForeign(['completed_by_user_id']);
            $table->dropColumn(['assigned_user_id', 'assigned_traveler_id', 'completed_by_user_id']);
        });

        Schema::dropIfExists('trip_travelers');
    }
};
