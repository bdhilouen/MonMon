<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Category extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'categories';

    protected $fillable = [
        'user_id',
        'name',
        'icon',
        'color',
        'type',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    // Scope untuk kategori default (global)
    public function scopeDefault($query)
    {
        return $query->whereNull('user_id');
    }

    // Scope untuk kategori custom user
    public function scopeCustom($query, $userId)
    {
        return $query->where('user_id', $userId);
    }
}