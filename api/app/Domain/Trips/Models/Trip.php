<?php

declare(strict_types=1);

namespace App\Domain\Trips\Models;

use App\Domain\Checklists\Models\Checklist;
use App\Domain\Checklists\Models\ChecklistItem;
use App\Domain\Itinerary\Models\ItineraryItem;
use App\Domain\Itinerary\Models\TripDay;
use App\Domain\Stays\Models\Stay;
use App\Models\User;
use Database\Factories\TripFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'owner_id',
    'title',
    'start_date',
    'end_date',
    'primary_timezone',
    'origin_country',
    'destination_country',
    'trip_type',
    'planning_mode',
    'status',
    'version',
])]
final class Trip extends Model
{
    /** @use HasFactory<TripFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    /**
     * Create a new factory instance for the model.
     */
    protected static function newFactory(): TripFactory
    {
        return TripFactory::new();
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'start_date' => 'date:Y-m-d',
            'end_date' => 'date:Y-m-d',
            'version' => 'integer',
        ];
    }

    /**
     * The trip creator/owner.
     *
     * @return BelongsTo<User, $this>
     */
    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * All member records for this trip.
     *
     * @return HasMany<TripMember, $this>
     */
    public function members(): HasMany
    {
        return $this->hasMany(TripMember::class);
    }

    /**
     * Users that are members of this trip.
     *
     * @return BelongsToMany<User, $this>
     */
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'trip_members')
            ->withPivot(['role', 'invitation_status'])
            ->withTimestamps();
    }

    /**
     * Check if a given user is a member of this trip.
     */
    public function hasMember(User|string $user): bool
    {
        $userId = $user instanceof User ? $user->id : $user;

        return $this->members()->where('user_id', $userId)->exists();
    }

    /**
     * Get the role of a given user for this trip.
     */
    public function memberRole(User|string $user): ?string
    {
        $userId = $user instanceof User ? $user->id : $user;

        /** @var TripMember|null $member */
        $member = $this->members()->where('user_id', $userId)->first();

        return $member?->role;
    }

    /**
     * All scheduled days for this trip.
     *
     * @return HasMany<TripDay, $this>
     */
    public function days(): HasMany
    {
        return $this->hasMany(TripDay::class)->orderBy('local_date');
    }

    /**
     * All itinerary items and stops planned for this trip.
     *
     * @return HasMany<ItineraryItem, $this>
     */
    public function itineraryItems(): HasMany
    {
        return $this->hasMany(ItineraryItem::class)
            ->orderBy('sort_order')
            ->orderBy('starts_at_utc')
            ->orderBy('created_at');
    }

    /**
     * All accommodations and stays saved for this trip.
     *
     * @return HasMany<Stay, $this>
     */
    public function stays(): HasMany
    {
        return $this->hasMany(Stay::class)
            ->orderBy('check_in_at')
            ->orderBy('created_at');
    }

    /**
     * All checklists created for this trip.
     *
     * @return HasMany<Checklist, $this>
     */
    public function checklists(): HasMany
    {
        return $this->hasMany(Checklist::class)
            ->orderBy('sort_order')
            ->orderBy('created_at');
    }

    /**
     * All checklist items created for this trip.
     *
     * @return HasMany<ChecklistItem, $this>
     */
    public function checklistItems(): HasMany
    {
        return $this->hasMany(ChecklistItem::class)
            ->orderBy('sort_order')
            ->orderBy('created_at');
    }
}
