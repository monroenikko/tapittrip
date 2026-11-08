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
        Schema::create('expense_splits', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('expense_id')->constrained('expenses')->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->integer('amount_minor'); // amount this user owes in the expense currency
            $table->integer('base_amount_minor')->nullable(); // amount in trip base currency
            $table->integer('shares')->default(1);
            $table->boolean('settled')->default(false);
            $table->timestamps();

            $table->unique(['expense_id', 'user_id']);
            $table->index(['user_id', 'settled']);
        });

        Schema::create('expense_settlements', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('trip_id')->constrained('trips')->cascadeOnDelete();
            $table->foreignUuid('payer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('payee_id')->constrained('users')->cascadeOnDelete();
            $table->integer('amount_minor'); // settled amount in base currency
            $table->char('currency', 3);
            $table->timestamp('settled_at');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['trip_id', 'settled_at']);
            $table->index(['trip_id', 'payer_id']);
            $table->index(['trip_id', 'payee_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('expense_settlements');
        Schema::dropIfExists('expense_splits');
    }
};
