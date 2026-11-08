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
        Schema::create('trip_budgets', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->unique()->constrained('trips')->cascadeOnDelete();
            $table->string('currency', 3);
            $table->bigInteger('total_budget_minor');
            $table->bigInteger('daily_budget_minor')->nullable();
            $table->timestamps();
        });

        Schema::create('expenses', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('payer_id')->constrained('users')->cascadeOnDelete();
            $table->string('category', 30);
            $table->string('title');
            $table->bigInteger('amount_minor');
            $table->string('currency', 3);
            $table->decimal('exchange_rate', 12, 6)->default(1.0);
            $table->bigInteger('base_amount_minor');
            $table->date('expense_date');
            $table->foreignUuid('itinerary_item_id')->nullable()->constrained('itinerary_items')->nullOnDelete();
            $table->foreignUuid('stay_id')->nullable()->constrained('stays')->nullOnDelete();
            $table->string('split_type', 20)->default('single');
            $table->text('notes')->nullable();
            $table->string('receipt_url', 2048)->nullable();
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['trip_id', 'expense_date']);
            $table->index(['trip_id', 'category']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('expenses');
        Schema::dropIfExists('trip_budgets');
    }
};
