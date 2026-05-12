<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class MonthlyWrapped extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'monthly_wrapped';

    protected $fillable = [
        'user_id',
        'month',
        'total_income',
        'total_expense',
        'saving_rate',
        'top_category',
        'total_transactions',
        'streak',
        'generated_image_url',
    ];

    protected $casts = [
        'total_income' => 'float',
        'total_expense' => 'float',
        'saving_rate' => 'float',
        'total_transactions' => 'integer',
        'streak' => 'integer',
        'created_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}