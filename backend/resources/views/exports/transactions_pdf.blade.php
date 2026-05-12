<!DOCTYPE html>
<html>
<head>
    <title>MonMon Transaction Report</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .summary { background-color: #f9f9f9; padding: 15px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>MonMon Transaction Report</h1>
    <p><strong>User:</strong> {{ $user->name }}</p>
    <p><strong>Period:</strong> {{ $start_date->format('d M Y') }} - {{ $end_date->format('d M Y') }}</p>
    
    <div class="summary">
        <p><strong>Total Income:</strong> Rp{{ number_format($total_income, 0, ',', '.') }}</p>
        <p><strong>Total Expense:</strong> Rp{{ number_format($total_expense, 0, ',', '.') }}</p>
        <p><strong>Net:</strong> Rp{{ number_format($net, 0, ',', '.') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>Date</th>
                <th>Type</th>
                <th>Category</th>
                <th>Amount</th>
                <th>Note</th>
            </tr>
        </thead>
        <tbody>
            @foreach($transactions as $transaction)
            <tr>
                <td>{{ $transaction->date->format('d M Y') }}</td>
                <td>{{ ucfirst($transaction->type) }}</td>
                <td>{{ $transaction->category->name ?? 'N/A' }}</td>
                <td>Rp{{ number_format($transaction->amount, 0, ',', '.') }}</td>
                <td>{{ $transaction->note ?? '-' }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>