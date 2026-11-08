<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Domain\Notifications\Models\NotificationPreference;
use App\Domain\Notifications\Models\UserDevice;
use App\Domain\Trips\Models\Trip;
use App\Domain\Trips\Models\TripMember;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'display_name', 'email', 'avatar_url', 'locale', 'home_timezone', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasUuids, Notifiable, SoftDeletes;

    /**
     * Trips owned by this user.
     *
     * @return HasMany<Trip, $this>
     */
    public function ownedTrips(): HasMany
    {
        return $this->hasMany(Trip::class, 'owner_id');
    }

    /**
     * Trip memberships for this user.
     *
     * @return HasMany<TripMember, $this>
     */
    public function tripMemberships(): HasMany
    {
        return $this->hasMany(TripMember::class);
    }

    /**
     * All trips this user is a member of.
     *
     * @return BelongsToMany<Trip, $this>
     */
    public function trips(): BelongsToMany
    {
        return $this->belongsToMany(Trip::class, 'trip_members')
            ->withPivot(['role', 'invitation_status'])
            ->withTimestamps();
    }

    /**
     * All registered devices for this user.
     *
     * @return HasMany<UserDevice, $this>
     */
    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    /**
     * Notification preferences for this user.
     *
     * @return HasOne<NotificationPreference, $this>
     */
    public function notificationPreference(): HasOne
    {
        return $this->hasOne(NotificationPreference::class);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
