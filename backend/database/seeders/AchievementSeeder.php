<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Achievement;

class AchievementSeeder extends Seeder
{
    public function run()
    {
        $achievements = [
            // Streak-based
            [
                'title' => 'Konsisten Pemula',
                'description' => 'Login dan catat transaksi 7 hari berturut-turut',
                'condition_type' => 'streak',
                'condition_value' => 7,
                'icon' => '🔥',
            ],
            [
                'title' => 'Disiplin Finansial',
                'description' => 'Login dan catat transaksi 30 hari berturut-turut',
                'condition_type' => 'streak',
                'condition_value' => 30,
                'icon' => '💪',
            ],
            [
                'title' => 'Master Konsistensi',
                'description' => 'Login dan catat transaksi 100 hari berturut-turut',
                'condition_type' => 'streak',
                'condition_value' => 100,
                'icon' => '🏆',
            ],

            // Saving-based
            [
                'title' => 'Tabungan Pertama 100rb',
                'description' => 'Berhasil mengumpulkan tabungan sebesar Rp100.000',
                'condition_type' => 'first_saving',
                'condition_value' => 100000,
                'icon' => '💵',
            ],
            [
                'title' => 'Tabungan 1 Juta Pertama',
                'description' => 'Berhasil mengumpulkan tabungan sebesar Rp1.000.000',
                'condition_type' => 'first_saving',
                'condition_value' => 1000000,
                'icon' => '💰',
            ],
            [
                'title' => 'Jutawan Sejati',
                'description' => 'Berhasil mengumpulkan tabungan sebesar Rp5.000.000',
                'condition_type' => 'first_saving',
                'condition_value' => 5000000,
                'icon' => '🤑',
            ],

            // Saving Rate
            [
                'title' => 'Hemat Pangkal Kaya',
                'description' => 'Mencapai savings rate 20% dalam sebulan',
                'condition_type' => 'saving_rate',
                'condition_value' => 20,
                'icon' => '📊',
            ],
            [
                'title' => 'Penabung Handal',
                'description' => 'Mencapai savings rate 30% dalam sebulan',
                'condition_type' => 'saving_rate',
                'condition_value' => 30,
                'icon' => '🎯',
            ],
            [
                'title' => 'Dewa Penghematan',
                'description' => 'Mencapai savings rate 50% dalam sebulan',
                'condition_type' => 'saving_rate',
                'condition_value' => 50,
                'icon' => '👑',
            ],

            // Expense Ratio
            [
                'title' => 'Finansial Seimbang',
                'description' => 'Pengeluaran 2x lebih kecil dari pemasukan',
                'condition_type' => 'expense_ratio',
                'condition_value' => 2,
                'icon' => '⚖️',
            ],
            [
                'title' => 'Hidup Minimalis',
                'description' => 'Pengeluaran 3x lebih kecil dari pemasukan',
                'condition_type' => 'expense_ratio',
                'condition_value' => 3,
                'icon' => '🌱',
            ],

            // Transaction Count
            [
                'title' => 'Pencatat Rajin',
                'description' => 'Mencatat 50 transaksi',
                'condition_type' => 'transaction_count',
                'condition_value' => 50,
                'icon' => '📝',
            ],
            [
                'title' => 'Master Pencatatan',
                'description' => 'Mencatat 200 transaksi',
                'condition_type' => 'transaction_count',
                'condition_value' => 200,
                'icon' => '📚',
            ],
            [
                'title' => 'Legend MonMon',
                'description' => 'Mencatat 500 transaksi',
                'condition_type' => 'transaction_count',
                'condition_value' => 500,
                'icon' => '⭐',
            ],
        ];

        foreach ($achievements as $achievement) {
            Achievement::create($achievement);
        }

        $this->command->info('✅ Achievements created successfully!');
    }
}