<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run()
    {
        User::create([
            'name' => 'Admin MonMon',
            'email' => 'admin@monmon.app',
            'password' => Hash::make('password123'),
            'balance' => 0,
            'points' => 0,
            'level' => 1,
            'streak' => 0,
            'last_active_date' => now(),
        ]);

        $this->command->info('✅ Admin user created: admin@monmon.app / password123');
    }
}