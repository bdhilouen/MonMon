<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;
use Illuminate\Auth\Authenticatable;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;

class User extends Model implements AuthenticatableContract
{
    use HasApiTokens, Notifiable, Authenticatable;

    protected $connection = 'mongodb';
    protected $collection = 'users';

    protected $fillable = [
        'name',
        'email',
        'password',
        'balance',
        'points',
        'level',
        'streak',
        'last_active_date',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'balance' => 'float',
        'points' => 'integer',
        'level' => 'integer',
        'streak' => 'integer',
        'last_active_date' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relationships
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function categories()
    {
        return $this->hasMany(Category::class);
    }

    public function userAchievements()
    {
        return $this->hasMany(UserAchievement::class);
    }

    public function monthlyWrapped()
    {
        return $this->hasMany(MonthlyWrapped::class);
    }
}