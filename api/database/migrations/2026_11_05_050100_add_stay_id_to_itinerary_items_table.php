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
        Schema::table('itinerary_items', function (Blueprint $table) {
            $table->foreignUuid('stay_id')->nullable()->after('place_id')->constrained('stays')->nullOnDelete();
            $table->index('stay_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('itinerary_items', function (Blueprint $table) {
            $table->dropForeign(['stay_id']);
            $table->dropIndex(['stay_id']);
            $table->dropColumn('stay_id');
        });
    }
};
