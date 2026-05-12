<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ExportController extends Controller
{
    /**
     * Export transactions to CSV
     */
    public function exportCSV(Request $request)
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        $userId = $request->user()->id;
        $startDate = Carbon::parse($request->start_date)->startOfDay();
        $endDate = Carbon::parse($request->end_date)->endOfDay();

        $transactions = Transaction::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->orderBy('date', 'desc')
            ->get();

        $filename = 'monmon_transactions_' . now()->format('Y-m-d') . '.csv';
        
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $callback = function() use ($transactions) {
            $file = fopen('php://output', 'w');
            
            // Header
            fputcsv($file, ['Date', 'Type', 'Category', 'Amount', 'Note']);
            
            // Data
            foreach ($transactions as $transaction) {
                fputcsv($file, [
                    $transaction->date->format('Y-m-d H:i:s'),
                    ucfirst($transaction->type),
                    $transaction->category->name ?? 'N/A',
                    $transaction->amount,
                    $transaction->note ?? '',
                ]);
            }
            
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Export transactions to PDF
     * Requires: composer require barryvdh/laravel-dompdf
     */
    public function exportPDF(Request $request)
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        $userId = $request->user()->id;
        $user = $request->user();
        $startDate = Carbon::parse($request->start_date)->startOfDay();
        $endDate = Carbon::parse($request->end_date)->endOfDay();

        $transactions = Transaction::where('user_id', $userId)
            ->whereBetween('date', [$startDate, $endDate])
            ->with('category')
            ->orderBy('date', 'desc')
            ->get();

        $totalIncome = $transactions->where('type', 'income')->sum('amount');
        $totalExpense = $transactions->where('type', 'expense')->sum('amount');

        $data = [
            'user' => $user,
            'transactions' => $transactions,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_income' => $totalIncome,
            'total_expense' => $totalExpense,
            'net' => $totalIncome - $totalExpense,
        ];

        // Simple HTML template (bisa dibuat lebih bagus)
        $html = view('exports.transactions_pdf', $data)->render();

        // If using DomPDF
        // $pdf = \PDF::loadHTML($html);
        // return $pdf->download('monmon_report.pdf');

        // For now, return HTML (bisa di-convert di frontend)
        return response($html, 200, [
            'Content-Type' => 'text/html',
        ]);
    }
}