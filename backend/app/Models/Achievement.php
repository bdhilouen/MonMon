<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Achievement extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'achievements';

    protected $fillable = [
        'title',
        'description',
        'condition_type',
        'condition_value',
        'icon',
    ];

    protected $casts = [
        'condition_value' => 'float',
    ];

    public function userAchievements()
    {
        return $this->hasMany(UserAchievement::class);
    }
}