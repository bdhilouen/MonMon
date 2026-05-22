<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>MonMon Transaction Report</title>
    <style>
        @page {
            margin: 20mm;
        }
        
        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            font-size: 10pt;
            color: #333;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 15px;
        }
        
        .header h1 {
            color: #4CAF50;
            margin: 0;
            font-size: 24pt;
        }
        
        .info-box {
            background-color: #f5f5f5;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
        
        .info-box p {
            margin: 5px 0;
        }
        
        .summary {
            background-color: #E8F5E9;
            padding: 15px;
            margin: 20px 0;
            border-left: 4px solid #4CAF50;
        }
        
        .summary h3 {
            margin-top: 0;
            color: #2E7D32;
        }
        
        .summary-grid {
            display: table;
            width: 100%;
        }
        
        .summary-item {
            display: table-row;
        }
        
        .summary-label {
            display: table-cell;
            font-weight: bold;
            padding: 5px 10px 5px 0;
        }
        
        .summary-value {
            display: table-cell;
            text-align: right;
            padding: 5px 0;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th {
            background-color: #4CAF50;
            color: white;
            padding: 10px;
            text-align: left;
            font-weight: bold;
        }
        
        td {
            border: 1px solid #ddd;
            padding: 8px;
        }
        
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        
        .income {
            color: #2E7D32;
            font-weight: bold;
        }
        
        .expense {
            color: #C62828;
            font-weight: bold;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 8pt;
            color: #999;
        }
        
        .page-break {
            page-break-after: always;
        }
    </style>
</head>
<body>
    <!-- Header -->
    <div class="header">
        <h1>💰 MonMon</h1>
        <p>Laporan Transaksi Keuangan</p>
    </div>
    
    <!-- User Info -->
    <div class="info-box">
        <p><strong>Nama:</strong> {{ $user->name }}</p>
        <p><strong>Email:</strong> {{ $user->email }}</p>
        <p><strong>Periode:</strong> {{ $start_date->format('d F Y') }} - {{ $end_date->format('d F Y') }}</p>
        <p><strong>Tanggal Cetak:</strong> {{ $generated_at }}</p>
    </div>
    
    <!-- Summary -->
    <div class="summary">
        <h3>📊 Ringkasan Keuangan</h3>
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-label">Total Pemasukan:</div>
                <div class="summary-value income">Rp {{ number_format($total_income, 0, ',', '.') }}</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Total Pengeluaran:</div>
                <div class="summary-value expense">Rp {{ number_format($total_expense, 0, ',', '.') }}</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Saldo Bersih:</div>
                <div class="summary-value" style="font-weight: bold; font-size: 12pt;">
                    Rp {{ number_format($net, 0, ',', '.') }}
                </div>
            </div>
            @if($total_income > 0)
            <div class="summary-item">
                <div class="summary-label">Savings Rate:</div>
                <div class="summary-value">
                    {{ number_format(($net / $total_income) * 100, 1) }}%
                </div>
            </div>
            @endif
        </div>
    </div>
    
    <!-- Transactions Table -->
    <h3>📝 Detail Transaksi ({{ $transactions->count() }} transaksi)</h3>
    
    <table>
        <thead>
            <tr>
                <th style="width: 15%">Tanggal</th>
                <th style="width: 12%">Tipe</th>
                <th style="width: 18%">Kategori</th>
                <th style="width: 20%">Jumlah</th>
                <th style="width: 35%">Catatan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($transactions as $transaction)
            <tr>
                <td>{{ $transaction->date->format('d/m/Y H:i') }}</td>
                <td>
                    @if($transaction->type === 'income')
                        <span class="income">Pemasukan</span>
                    @else
                        <span class="expense">Pengeluaran</span>
                    @endif
                </td>
                <td>
                    {{ $transaction->category_snapshot['icon'] ?? '📦' }}
                    {{ $transaction->category_snapshot['name'] ?? 'N/A' }}
                </td>
                <td class="{{ $transaction->type === 'income' ? 'income' : 'expense' }}">
                    Rp {{ number_format($transaction->amount, 0, ',', '.') }}
                </td>
                <td>{{ $transaction->note ?? '-' }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="5" style="text-align: center; padding: 20px; color: #999;">
                    Tidak ada transaksi pada periode ini
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
    
    <!-- Footer -->
    <div class="footer">
        <p>Dokumen ini dibuat secara otomatis oleh MonMon - Aplikasi Pengelolaan Keuangan Pribadi</p>
        <p>© {{ now()->year }} MonMon. All rights reserved.</p>
    </div>
</body>
</html>