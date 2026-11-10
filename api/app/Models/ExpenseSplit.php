<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class ExpenseSplit extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $table = 'expense_splits';

    protected $fillable = [
        'expense_id',
        'user_id',
        'amount_minor',
        'base_amount_minor',
        'shares',
        'settled',
    ];

    protected $casts = [
        'amount_minor' => 'integer',
        'base_amount_minor' => 'integer',
        'shares' => 'integer',
        'settled' => 'boolean',
    ];

    public function expense(): BelongsTo
    {
        return $this->belongsTo(Expense::class, 'expense_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
