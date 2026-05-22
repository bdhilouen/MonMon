<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $collection = DB::connection('mongodb')->getCollection('email_verifications');

        $collection->createIndex(['email' => 1], [
            'name' => 'email_verifications_email_idx',
        ]);

        $collection->createIndex(['expires_at' => 1], [
            'name' => 'email_verifications_expires_at_ttl_idx',
            'expireAfterSeconds' => 0,
        ]);
    }

    public function down(): void
    {
        $collection = DB::connection('mongodb')->getCollection('email_verifications');

        foreach ([
            'email_verifications_email_idx',
            'email_verifications_expires_at_ttl_idx',
        ] as $index) {
            try {
                $collection->dropIndex($index);
            } catch (Throwable) {
                //
            }
        }
    }
};
