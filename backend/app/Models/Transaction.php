<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Transaction extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'transactions';

    protected $fillable = [
        'user_id',
        'type',
        'amount',
        'category_id',
        'category_snapshot',
        'note',
        'receipt_url',
        'currency',
        'converted_amount',
        'date',
    ];

    protected $casts = [
        'amount' => 'float',
        'converted_amount' => 'float',
        'date' => 'datetime',
        'created_at' => 'datetime',
        'category_snapshot' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}