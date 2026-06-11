<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>MonMon Transaction Report</title>
    <style>
        @page {
            margin: 16mm;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: DejaVu Sans, Arial, sans-serif;
            font-size: 10pt;
            color: #1f2937;
            background: #fff8ff;
        }

        .brand-row {
            display: table;
            width: 100%;
            margin-bottom: 18px;
        }

        .brand-left,
        .brand-right {
            display: table-cell;
            vertical-align: middle;
        }

        .brand-right {
            text-align: right;
            color: #6b7280;
            font-size: 8.5pt;
        }

        .logo-mark {
            display: inline-block;
            width: 30px;
            height: 30px;
            line-height: 30px;
            margin-right: 8px;
            border-radius: 10px;
            background: #2196f3;
            color: #ffffff;
            text-align: center;
            font-weight: bold;
        }

        .brand-name {
            color: #111827;
            font-size: 20pt;
            font-weight: bold;
        }

        .hero {
            padding: 24px 28px;
            border-radius: 24px;
            background: #2196f3;
            color: #ffffff;
        }

        .hero-label {
            margin-bottom: 8px;
            color: #dbeafe;
            font-size: 11pt;
        }

        .hero-balance {
            margin-bottom: 8px;
            font-size: 28pt;
            font-weight: bold;
            letter-spacing: 0;
        }

        .hero-subtitle {
            color: #e0f2fe;
            font-size: 10pt;
        }

        .meta-card {
            margin-top: 14px;
            padding: 14px 16px;
            border-radius: 18px;
            background: #ffffff;
            border: 1px solid #eef2f7;
        }

        .meta-row {
            display: table;
            width: 100%;
            margin: 3px 0;
        }

        .meta-label,
        .meta-value {
            display: table-cell;
        }

        .meta-label {
            width: 26%;
            color: #6b7280;
            font-weight: bold;
        }

        .section-title {
            margin: 24px 0 12px;
            font-size: 16pt;
            font-weight: bold;
            color: #111827;
        }

        .summary-row {
            display: table;
            width: 100%;
            border-spacing: 0;
        }

        .summary-card {
            display: table-cell;
            width: 50%;
            padding: 16px;
            border-radius: 18px;
        }

        .summary-gap {
            display: table-cell;
            width: 14px;
        }

        .summary-income {
            background: #eef8f1;
        }

        .summary-expense {
            background: #fde8ee;
        }

        .summary-label {
            margin-bottom: 10px;
            color: #6b7280;
            font-size: 10pt;
        }

        .summary-value {
            font-size: 15pt;
            font-weight: bold;
        }

        .income {
            color: #2eae58;
        }

        .expense {
            color: #ef4444;
        }

        .net-card {
            margin-top: 14px;
            padding: 16px;
            border-radius: 18px;
            background: #ffffff;
            border: 1px solid #e5e7eb;
        }

        .net-grid {
            display: table;
            width: 100%;
        }

        .net-item {
            display: table-cell;
            width: 50%;
        }

        .net-label {
            color: #6b7280;
            font-size: 9pt;
        }

        .net-value {
            margin-top: 4px;
            font-size: 14pt;
            font-weight: bold;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            overflow: hidden;
            background: #ffffff;
        }

        thead {
            display: table-header-group;
        }

        th {
            padding: 11px 10px;
            background: #2196f3;
            color: #ffffff;
            text-align: left;
            font-size: 9pt;
        }

        td {
            padding: 10px;
            border-bottom: 1px solid #edf2f7;
            vertical-align: top;
            font-size: 9pt;
        }

        tr:nth-child(even) td {
            background: #f8fafc;
        }

        .amount {
            white-space: nowrap;
            text-align: right;
            font-weight: bold;
        }

        .type-pill {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 999px;
            font-size: 8pt;
            font-weight: bold;
        }

        .type-income {
            background: #dcfce7;
            color: #15803d;
        }

        .type-expense {
            background: #fee2e2;
            color: #dc2626;
        }

        .empty {
            padding: 26px;
            color: #6b7280;
            text-align: center;
        }

        .footer {
            margin-top: 24px;
            color: #9ca3af;
            text-align: center;
            font-size: 8pt;
        }
    </style>
</head>
<body>
    @php
        $savingsRate = $total_income > 0 ? ($net / $total_income) * 100 : null;
    @endphp

    <div class="brand-row">
        <div class="brand-left">
            <span class="logo-mark">M</span>
            <span class="brand-name">MonMon</span>
        </div>
        <div class="brand-right">
            Laporan Transaksi Keuangan<br>
            Dicetak {{ $generated_at }}
        </div>
    </div>

    <div class="hero">
        <div class="hero-label">Saldo Bersih Periode Ini</div>
        <div class="hero-balance">Rp {{ number_format($net, 0, ',', '.') }}</div>
        <div class="hero-subtitle">
            {{ $start_date->format('d F Y') }} - {{ $end_date->format('d F Y') }}
        </div>
    </div>

    <div class="meta-card">
        <div class="meta-row">
            <div class="meta-label">Nama</div>
            <div class="meta-value">{{ $user->name }}</div>
        </div>
        <div class="meta-row">
            <div class="meta-label">Email</div>
            <div class="meta-value">{{ $user->email }}</div>
        </div>
        <div class="meta-row">
            <div class="meta-label">Total Transaksi</div>
            <div class="meta-value">{{ $transactions->count() }} transaksi</div>
        </div>
    </div>

    <div class="section-title">Ringkasan Keuangan</div>

    <div class="summary-row">
        <div class="summary-card summary-income">
            <div class="summary-label">Pemasukan</div>
            <div class="summary-value income">Rp {{ number_format($total_income, 0, ',', '.') }}</div>
        </div>
        <div class="summary-gap"></div>
        <div class="summary-card summary-expense">
            <div class="summary-label">Pengeluaran</div>
            <div class="summary-value expense">Rp {{ number_format($total_expense, 0, ',', '.') }}</div>
        </div>
    </div>

    <div class="net-card">
        <div class="net-grid">
            <div class="net-item">
                <div class="net-label">Saldo Bersih</div>
                <div class="net-value">Rp {{ number_format($net, 0, ',', '.') }}</div>
            </div>
            <div class="net-item" style="text-align: right;">
                <div class="net-label">Savings Rate</div>
                <div class="net-value">
                    {{ $savingsRate === null ? '-' : number_format($savingsRate, 1) . '%' }}
                </div>
            </div>
        </div>
    </div>

    <div class="section-title">Detail Transaksi</div>

    <table>
        <thead>
            <tr>
                <th style="width: 17%">Tanggal</th>
                <th style="width: 15%">Tipe</th>
                <th style="width: 20%">Kategori</th>
                <th style="width: 20%; text-align: right;">Jumlah</th>
                <th style="width: 28%">Catatan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($transactions as $transaction)
            <tr>
                <td>{{ $transaction->date->format('d/m/Y') }}</td>
                <td>
                    @if($transaction->type === 'income')
                        <span class="type-pill type-income">Pemasukan</span>
                    @else
                        <span class="type-pill type-expense">Pengeluaran</span>
                    @endif
                </td>
                <td>{{ $transaction->category_snapshot['name'] ?? 'N/A' }}</td>
                <td class="amount {{ $transaction->type === 'income' ? 'income' : 'expense' }}">
                    Rp {{ number_format($transaction->amount, 0, ',', '.') }}
                </td>
                <td>{{ $transaction->note ?? '-' }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="5" class="empty">
                    Tidak ada transaksi pada periode ini.
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        Dokumen ini dibuat otomatis oleh MonMon. Simpan sebagai arsip pribadi kamu.
    </div>
</body>
</html>
