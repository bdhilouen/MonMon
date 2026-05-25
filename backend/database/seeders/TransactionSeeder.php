<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;
use App\Models\Transaction;
use Carbon\Carbon;

class TransactionSeeder extends Seeder
{
    public function run(): void
    {
        $userId = '6a10b518f367c411fc039202';

        $validCategories = Category::whereNull('user_id')
            ->orWhere('user_id', $userId)
            ->get();

        if ($validCategories->isEmpty()) {
            $this->command->error('Tidak ada kategori ditemukan.');
            return;
        }

        $totalDataToGenerate = 100;
        $count = 0;

        for ($i = 0; $i < $totalDataToGenerate; $i++) {
            $randomCategory = $validCategories->random();
            $type = $randomCategory->type ?? 'expense';
            $amount = rand(2, 400) * 5000;

            $date = Carbon::create(
                2026, 4,
                rand(1, 30),
                rand(0, 23),
                rand(0, 59),
                0
            );

            // ✅ Pakai Model::create() biar category_snapshot ikut tersimpan
            Transaction::create([
                'type' => $type,
                'amount' => (int) $amount,
                'category_id' => (string) $randomCategory->_id,
                'category_snapshot' => [  // ✅ Include snapshot
                    'id' => (string) $randomCategory->_id,
                    'name' => $randomCategory->name,
                    'icon' => $randomCategory->icon,
                    'color' => $randomCategory->color,
                    'type' => $randomCategory->type,
                ],
                'note' => 'Dummy Seeder - ' . ($randomCategory->name ?? 'Transaksi'),
                'date' => $date,
                'currency' => 'IDR',
                'user_id' => $userId,
                'converted_amount' => (int) $amount,
            ]);

            $count++;
        }

        $this->command->info("$count transaksi berhasil di-seed.");
    }
}