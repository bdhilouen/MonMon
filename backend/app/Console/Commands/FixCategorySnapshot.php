<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Transaction;
use App\Models\Category;

class FixCategorySnapshot extends Command
{
    protected $signature = 'fix:category-snapshot';
    protected $description = 'Fix transactions missing category_snapshot';

    public function handle()
    {
        $transactions = Transaction::whereNull('category_snapshot')->get();

        $this->info("Found: {$transactions->count()} transactions to fix");

        $fixed = 0;
        $notFound = 0;

        foreach ($transactions as $trx) {
            $category = Category::find($trx->category_id);

            if ($category) {
                $trx->category_snapshot = [
                    'id' => (string) $category->_id,
                    'name' => $category->name,
                    'icon' => $category->icon,
                    'color' => $category->color,
                    'type' => $category->type,
                ];
                $trx->save();
                $fixed++;
                $this->line("✅ Fixed: {$trx->id} → {$category->name}");
            } else {
                $notFound++;
                $this->warn("⚠️ Category not found: {$trx->id}");
            }
        }

        $this->info("Done! Fixed: {$fixed}, Not found: {$notFound}");
    }
}