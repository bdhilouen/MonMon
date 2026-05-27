<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: linear-gradient(135deg, #FF5722 0%, #FF9800 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px 10px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 30px;
            border-radius: 0 0 10px 10px;
        }
        .otp-box {
            background: white;
            border: 2px dashed #FF5722;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
            border-radius: 8px;
        }
        .otp-code {
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 5px;
            color: #FF5722;
        }
        .warning {
            background: #FFF3E0;
            border-left: 4px solid #FF9800;
            padding: 12px;
            margin: 15px 0;
            border-radius: 4px;
            font-size: 14px;
        }
        .footer {
            text-align: center;
            margin-top: 20px;
            color: #999;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>💰 MonMon</h1>
        <p>Reset Password</p>
    </div>

    <div class="content">
        <p>Halo <strong>{{ $userName }}</strong>!</p>

        <p>Kami menerima permintaan reset password untuk akun MonMon kamu. Masukkan kode OTP berikut:</p>

        <div class="otp-box">
            <div class="otp-code">{{ $otp }}</div>
        </div>

        <p><strong>Kode ini akan kadaluarsa dalam 10 menit.</strong></p>

        <div class="warning">
            ⚠️ Jika kamu tidak meminta reset password, abaikan email ini. Password kamu tidak akan berubah.
        </div>

        <p>Salam,<br>Tim MonMon</p>
    </div>

    <div class="footer">
        <p>© {{ date('Y') }} MonMon. All rights reserved.</p>
        <p>Email otomatis, mohon tidak membalas email ini.</p>
    </div>
</body>
</html>