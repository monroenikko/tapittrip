<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
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

#[Fillable(['name', 'display_name', 'friend_code', 'accepts_direct_invites', 'email', 'avatar_url', 'locale', 'home_timezone', 'home_country', 'permanent_address', 'home_currency', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasUuids, Notifiable, SoftDeletes;

    protected static function booted(): void
    {
        static::creating(function (User $user): void {
            if (empty($user->friend_code)) {
                $user->friend_code = self::generateUniqueFriendCode();
            }
            if ($user->accepts_direct_invites === null) {
                $user->accepts_direct_invites = true;
            }
        });
    }

    /**
     * Generate a unique, privacy-safe friend code (`TRP-XXXXXX`).
     */
    public static function generateUniqueFriendCode(): string
    {
        $alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
        $alphabetLength = strlen($alphabet);

        do {
            $code = 'TRP-';
            for ($i = 0; $i < 6; $i++) {
                $code .= $alphabet[random_int(0, $alphabetLength - 1)];
            }
        } while (self::withTrashed()->where('friend_code', $code)->exists());

        return $code;
    }

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
            ->wherePivot('invitation_status', 'accepted')
            ->wherePivotNull('deleted_at')
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
     * Direct trip invitations targeted to this user.
     *
     * @return HasMany<TripInvitation, $this>
     */
    public function targetedInvitations(): HasMany
    {
        return $this->hasMany(TripInvitation::class, 'target_user_id')
            ->orderByDesc('created_at');
    }

    /**
     * Ownership transfer handovers offered to this user.
     *
     * @return HasMany<TripOwnershipTransfer, $this>
     */
    public function incomingOwnershipTransfers(): HasMany
    {
        return $this->hasMany(TripOwnershipTransfer::class, 'to_user_id')
            ->orderByDesc('created_at');
    }

    /**
     * Ownership transfer handovers initiated by this user.
     *
     * @return HasMany<TripOwnershipTransfer, $this>
     */
    public function outgoingOwnershipTransfers(): HasMany
    {
        return $this->hasMany(TripOwnershipTransfer::class, 'from_user_id')
            ->orderByDesc('created_at');
    }

    /**
     * Encrypted travel documents owned by this user.
     *
     * @return HasMany<TravelDocument, $this>
     */
    public function travelDocuments(): HasMany
    {
        return $this->hasMany(TravelDocument::class, 'owner_id')
            ->orderByDesc('created_at');
    }

    /**
     * Booking imports initiated by this user.
     *
     * @return HasMany<BookingImport, $this>
     */
    public function bookingImports(): HasMany
    {
        return $this->hasMany(BookingImport::class)
            ->orderByDesc('created_at');
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
            'accepts_direct_invites' => 'boolean',
        ];
    }
}
