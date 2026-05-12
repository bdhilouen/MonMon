<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run()
    {
        $categories = [
            // Income Categories
            [
                'user_id' => null, // null = default category
                'name' => 'Gaji',
                'icon' => '💰',
                'color' => '#4CAF50',
                'type' => 'income',
            ],
            [
                'user_id' => null,
                'name' => 'Bonus',
                'icon' => '🎁',
                'color' => '#8BC34A',
                'type' => 'income',
            ],
            [
                'user_id' => null,
                'name' => 'Investasi',
                'icon' => '📈',
                'color' => '#FFC107',
                'type' => 'income',
            ],
            [
                'user_id' => null,
                'name' => 'Freelance',
                'icon' => '💼',
                'color' => '#FF9800',
                'type' => 'income',
            ],
            [
                'user_id' => null,
                'name' => 'Lainnya',
                'icon' => '💵',
                'color' => '#9E9E9E',
                'type' => 'income',
            ],

            // Expense Categories
            [
                'user_id' => null,
                'name' => 'Makan & Minum',
                'icon' => '🍔',
                'color' => '#FF5722',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Transportasi',
                'icon' => '🚗',
                'color' => '#2196F3',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Belanja',
                'icon' => '🛍️',
                'color' => '#E91E63',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Hiburan',
                'icon' => '🎮',
                'color' => '#9C27B0',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Tagihan',
                'icon' => '📄',
                'color' => '#F44336',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Kesehatan',
                'icon' => '⚕️',
                'color' => '#00BCD4',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Pendidikan',
                'icon' => '📚',
                'color' => '#3F51B5',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Pulsa & Internet',
                'icon' => '📱',
                'color' => '#009688',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Kopi & Nongkrong',
                'icon' => '☕',
                'color' => '#795548',
                'type' => 'expense',
            ],
            [
                'user_id' => null,
                'name' => 'Lainnya',
                'icon' => '📦',
                'color' => '#607D8B',
                'type' => 'expense',
            ],
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }

        $this->command->info('✅ Default categories created successfully!');
    }
}