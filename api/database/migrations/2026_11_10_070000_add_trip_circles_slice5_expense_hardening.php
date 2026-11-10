<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('expenses', function (Blueprint $table): void {
            $table->foreignUuid('created_by_user_id')
                ->nullable()
                ->after('payer_id')
                ->constrained('users')
                ->nullOnDelete();
            $table->string('visibility', 20)
                ->default('private')
                ->after('split_type');
            $table->string('rate_source', 40)
                ->nullable()
                ->after('exchange_rate');
            $table->timestamp('rate_captured_at')
                ->nullable()
                ->after('rate_source');
            $table->string('conversion_status', 20)
                ->default('converted')
                ->after('rate_captured_at');
            $table->uuid('client_operation_id')
                ->nullable()
                ->after('version');

            $table->decimal('exchange_rate', 12, 6)->nullable()->change();
            $table->bigInteger('base_amount_minor')->nullable()->change();

            $table->unique(['trip_id', 'client_operation_id'], 'expenses_trip_client_op_unique');
            $table->index(['trip_id', 'visibility', 'created_by_user_id'], 'expenses_trip_visibility_creator_idx');
        });

        // Preserve existing group-split expenses as shared and set creator attribution.
        DB::table('expenses')
            ->whereNull('created_by_user_id')
            ->update([
                'created_by_user_id' => DB::raw('payer_id'),
            ]);

        DB::table('expenses')
            ->where('split_type', '!=', 'single')
            ->update(['visibility' => 'shared']);

        DB::table('expenses')
            ->whereNull('rate_source')
            ->update([
                'rate_source' => DB::raw("CASE WHEN exchange_rate = 1 THEN 'identity' ELSE 'snapshot' END"),
                'conversion_status' => 'converted',
            ]);

        Schema::table('expense_settlements', function (Blueprint $table): void {
            $table->foreignUuid('created_by_user_id')
                ->nullable()
                ->after('payee_id')
                ->constrained('users')
                ->nullOnDelete();
            $table->decimal('exchange_rate', 12, 6)
                ->nullable()
                ->after('currency');
            $table->bigInteger('base_amount_minor')
                ->nullable()
                ->after('exchange_rate');
            $table->string('rate_source', 40)
                ->nullable()
                ->after('base_amount_minor');
            $table->timestamp('rate_captured_at')
                ->nullable()
                ->after('rate_source');
            $table->uuid('client_operation_id')
                ->nullable()
                ->after('notes');

            $table->unique(['trip_id', 'client_operation_id'], 'settlements_trip_client_op_unique');
        });

        DB::table('expense_settlements')
            ->whereNull('base_amount_minor')
            ->update([
                'exchange_rate' => 1.0,
                'base_amount_minor' => DB::raw('amount_minor'),
                'rate_source' => 'identity',
            ]);
    }

    public function down(): void
    {
        Schema::table('expense_settlements', function (Blueprint $table): void {
            $table->dropUnique('settlements_trip_client_op_unique');
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn([
                'exchange_rate',
                'base_amount_minor',
                'rate_source',
                'rate_captured_at',
                'client_operation_id',
            ]);
        });

        Schema::table('expenses', function (Blueprint $table): void {
            $table->dropUnique('expenses_trip_client_op_unique');
            $table->dropIndex('expenses_trip_visibility_creator_idx');
            $table->dropConstrainedForeignId('created_by_user_id');
            $table->dropColumn([
                'visibility',
                'rate_source',
                'rate_captured_at',
                'conversion_status',
                'client_operation_id',
            ]);
        });
    }
};
