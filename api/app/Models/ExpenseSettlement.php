<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class ExpenseSettlement extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $table = 'expense_settlements';

    protected $fillable = [
        'trip_id',
        'payer_id',
        'payee_id',
        'created_by_user_id',
        'amount_minor',
        'currency',
        'exchange_rate',
        'base_amount_minor',
        'rate_source',
        'rate_captured_at',
        'settled_at',
        'notes',
        'client_operation_id',
    ];

    protected $casts = [
        'amount_minor' => 'integer',
        'exchange_rate' => 'decimal:6',
        'base_amount_minor' => 'integer',
        'rate_captured_at' => 'datetime',
        'settled_at' => 'datetime',
    ];

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'trip_id');
    }

    public function payer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'payer_id');
    }

    public function payee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'payee_id');
    }
}
