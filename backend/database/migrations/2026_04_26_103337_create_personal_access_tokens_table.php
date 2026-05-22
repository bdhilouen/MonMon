<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $collection = DB::connection('mongodb')->getCollection('personal_access_tokens');

        $collection->createIndex(['token' => 1], [
            'name' => 'personal_access_tokens_token_unique_idx',
            'unique' => true,
        ]);

        $collection->createIndex(['tokenable_type' => 1, 'tokenable_id' => 1], [
            'name' => 'personal_access_tokens_tokenable_idx',
        ]);

        $collection->createIndex(['expires_at' => 1], [
            'name' => 'personal_access_tokens_expires_at_idx',
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $collection = DB::connection('mongodb')->getCollection('personal_access_tokens');

        foreach ([
            'personal_access_tokens_token_unique_idx',
            'personal_access_tokens_tokenable_idx',
            'personal_access_tokens_expires_at_idx',
        ] as $index) {
            try {
                $collection->dropIndex($index);
            } catch (Throwable) {
                //
            }
        }
    }
};
