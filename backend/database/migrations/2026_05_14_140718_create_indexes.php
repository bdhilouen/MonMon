<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        DB::connection('mongodb')
            ->getCollection('transactions')
            ->createIndex(['user_id' => 1, 'date' => -1], ['name' => 'transactions_user_date_idx']);

        DB::connection('mongodb')
            ->getCollection('transactions')
            ->createIndex(['user_id' => 1, 'type' => 1], ['name' => 'transactions_user_type_idx']);

        DB::connection('mongodb')
            ->getCollection('transactions')
            ->createIndex(['category_id' => 1], ['name' => 'transactions_category_idx']);

        DB::connection('mongodb')
            ->getCollection('user_achievements')
            ->createIndex(['user_id' => 1], ['name' => 'user_achievements_user_idx']);

        DB::connection('mongodb')
            ->getCollection('user_achievements')
            ->createIndex(
                ['user_id' => 1, 'achievement_id' => 1],
                ['name' => 'user_achievements_user_achievement_unique_idx', 'unique' => true]
            );

        DB::connection('mongodb')
            ->getCollection('monthly_wrapped')
            ->createIndex(
                ['user_id' => 1, 'month' => -1],
                ['name' => 'monthly_wrapped_user_month_unique_idx', 'unique' => true]
            );

        DB::connection('mongodb')
            ->getCollection('categories')
            ->createIndex(['user_id' => 1], ['name' => 'categories_user_idx']);

        DB::connection('mongodb')
            ->getCollection('categories')
            ->createIndex(['type' => 1], ['name' => 'categories_type_idx']);
    }

    public function down()
    {
        $this->dropIndexes('transactions', [
            'transactions_user_date_idx',
            'transactions_user_type_idx',
            'transactions_category_idx',
        ]);

        $this->dropIndexes('user_achievements', [
            'user_achievements_user_idx',
            'user_achievements_user_achievement_unique_idx',
        ]);

        $this->dropIndexes('monthly_wrapped', [
            'monthly_wrapped_user_month_unique_idx',
        ]);

        $this->dropIndexes('categories', [
            'categories_user_idx',
            'categories_type_idx',
        ]);
    }

    private function dropIndexes(string $collection, array $indexes): void
    {
        $mongoCollection = DB::connection('mongodb')->getCollection($collection);

        foreach ($indexes as $index) {
            try {
                $mongoCollection->dropIndex($index);
            } catch (Throwable) {
                //
            }
        }
    }
};
