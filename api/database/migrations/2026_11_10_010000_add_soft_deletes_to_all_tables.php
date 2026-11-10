<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Application tables that receive soft deletes support.
     *
     * @var array<int, string>
     */
    private array $tables = [
        'trip_members',
        'places',
        'trip_days',
        'checklists',
        'checklist_items',
        'media_attachments',
        'user_devices',
        'notification_preferences',
        'reminders',
        'visit_events',
        'sync_operations',
        'sync_cursors',
        'airports',
        'airport_terminals',
        'airport_lounges',
        'trip_budgets',
        'expense_splits',
        'expense_settlements',
        'countries',
    ];

    /**
     * Run the migrations.
     */
    public function up(): void
    {
        foreach ($this->tables as $tableName) {
            if (Schema::hasTable($tableName) && ! Schema::hasColumn($tableName, 'deleted_at')) {
                Schema::table($tableName, function (Blueprint $table): void {
                    $table->softDeletes();
                });
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        foreach ($this->tables as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'deleted_at')) {
                Schema::table($tableName, function (Blueprint $table): void {
                    $table->dropSoftDeletes();
                });
            }
        }
    }
};
