<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\MailMessage;

class OTPVerification extends Notification
{
    use Queueable;

    protected $otp;

    public function __construct($otp)
    {
        $this->otp = $otp;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Verifikasi Email MonMon')
            ->greeting('Halo ' . $notifiable->name . '!')
            ->line('Terima kasih telah mendaftar di MonMon.')
            ->line('Kode OTP kamu adalah:')
            ->line('**' . $this->otp . '**')
            ->line('Kode ini akan kadaluarsa dalam 10 menit.')
            ->line('Jika kamu tidak merasa mendaftar, abaikan email ini.')
            ->salutation('Salam, Tim MonMon');
    }
}