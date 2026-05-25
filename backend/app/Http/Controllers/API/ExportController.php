<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Barryvdh\DomPDF\Facade\Pdf;

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
            ->orderBy('date', 'desc')
            ->get();

        $filename = 'monmon_transactions_' . now()->format('Y-m-d') . '.csv';
        
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        $callback = function() use ($transactions) {
            $file = fopen('php://output', 'w');
            
            // Header CSV
            fputcsv($file, ['Tanggal', 'Tipe', 'Kategori', 'Jumlah (Rp)', 'Catatan']);
            
            // Data rows
            foreach ($transactions as $transaction) {
                fputcsv($file, [
                    $transaction->date->format('d/m/Y H:i'),
                    $transaction->type === 'income' ? 'Pemasukan' : 'Pengeluaran',
                    $transaction->category_snapshot['name'] ?? 'N/A',
                    number_format($transaction->amount, 0, ',', '.'),
                    $transaction->note ?? '',
                ]);
            }
            
            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Export transactions to PDF (using DomPDF)
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
            'generated_at' => now()->format('d/m/Y H:i'),
        ];

        // Generate PDF pakai DomPDF
        $pdf = Pdf::loadView('exports.transactions_pdf', $data);
        
        // Set paper size & orientation
        $pdf->setPaper('a4', 'portrait');
        
        $filename = 'monmon_report_' . now()->format('Y-m-d') . '.pdf';
        
        // Download langsung
        return $pdf->download($filename);
        
        // Atau kalau mau stream di browser (preview):
        // return $pdf->stream($filename);
    }
}