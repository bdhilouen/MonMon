<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class UserAchievement extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'user_achievements';

    protected $fillable = [
        'user_id',
        'achievement_id',
        'unlocked_at',
    ];

    protected $casts = [
        'unlocked_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function achievement()
    {
        return $this->belongsTo(Achievement::class);
    }
}