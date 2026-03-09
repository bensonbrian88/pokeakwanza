# Laravel Backend Registration Setup

This document provides the complete Laravel backend setup for the registration flow with OTP verification.

## 1. Database Migrations

### Create users table with OTP fields
```bash
php artisan make:migration create_users_table
```

The migration should include OTP fields:
```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->string('phone')->unique();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password');
    $table->string('otp_code')->nullable(); // Store OTP
    $table->timestamp('otp_expires_at')->nullable(); // OTP expiration
    $table->boolean('is_verified')->default(false); // User verification status
    $table->rememberToken();
    $table->timestamps();
    
    $table->index('phone');
    $table->index('email');
});
```

## 2. User Model

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'otp_code',
        'otp_expires_at',
        'is_verified',
    ];

    protected $hidden = [
        'password',
        'otp_code',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'otp_expires_at' => 'datetime',
        'is_verified' => 'boolean',
    ];

    /**
     * Generate and store OTP
     */
    public function generateOtp()
    {
        $this->otp_code = rand(100000, 999999);
        $this->otp_expires_at = now()->addMinutes(10); // OTP valid for 10 minutes
        $this->save();
        return $this->otp_code;
    }

    /**
     * Verify OTP
     */
    public function verifyOtp(string $otpCode)
    {
        if ($this->otp_code !== $otpCode) {
            return false;
        }

        if ($this->otp_expires_at < now()) {
            return false; // OTP expired
        }

        $this->is_verified = true;
        $this->otp_code = null;
        $this->otp_expires_at = null;
        $this->email_verified_at = now();
        $this->save();

        return true;
    }
}
```

## 3. Registration Controller

Place this in `app/Http/Controllers/Api/Auth/RegisterController.php`

```php
<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Queue;
use App\Jobs\SendOtpEmail;

class RegisterController extends Controller
{
    /**
     * Register a new user and generate OTP
     * 
     * @route POST /api/register
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
        try {
            Log::info('Registration attempt', [
                'email' => $request->email,
                'phone' => $request->phone,
            ]);

            // Validate input
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'required|string|email|max:255|unique:users',
                'phone' => 'required|string|unique:users',
                'password' => 'required|string|min:8|confirmed',
            ]);

            if ($validator->fails()) {
                Log::warning('Validation failed for registration', [
                    'email' => $request->email,
                    'errors' => $validator->errors(),
                ]);

                return response()->json([
                    'message' => 'Validation failed',
                    'errors' => $validator->errors(),
                ], 422);
            }

            // Create user (not verified yet)
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'phone' => $request->phone,
                'password' => Hash::make($request->password),
                'is_verified' => false,
            ]);

            Log::info('User created, generating OTP', [
                'user_id' => $user->id,
                'email' => $user->email,
            ]);

            // Generate OTP
            $otp = $user->generateOtp();

            // Queue email job (non-blocking)
            Queue::dispatch(new SendOtpEmail($user, $otp));
            // Alternative (sync - for testing):
            // \Mail::queue(new SendOtpMail($user, $otp));

            Log::info('Registration successful, OTP sent', [
                'user_id' => $user->id,
            ]);

            return response()->json([
                'message' => 'Registration successful. OTP has been sent to your email.',
                'success' => true,
                'next' => 'otp_verification', // Tell client to go to OTP screen
                'user_id' => $user->id,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                ],
            ], 201);

        } catch (\Exception $e) {
            Log::error('Registration error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'message' => 'Registration failed. Please try again later.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Verify OTP code
     * 
     * @route POST /api/verify-otp
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyOtp(Request $request)
    {
        try {
            Log::info('OTP verification attempt', [
                'user_id' => $request->user_id,
            ]);

            $validator = Validator::make($request->all(), [
                'user_id' => 'required|exists:users,id',
                'otp_code' => 'required|string|size:6|regex:/^\d+$/',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'message' => 'Invalid OTP format',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $user = User::findOrFail($request->user_id);

            // Verify OTP
            if (!$user->verifyOtp($request->otp_code)) {
                Log::warning('OTP verification failed', [
                    'user_id' => $user->id,
                ]);

                return response()->json([
                    'message' => 'Invalid or expired OTP code',
                ], 401);
            }

            // Generate authentication token
            $token = $user->createToken('auth_token')->plainTextToken;

            Log::info('OTP verification successful', [
                'user_id' => $user->id,
            ]);

            return response()->json([
                'message' => 'Email verified successfully',
                'success' => true,
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'is_verified' => $user->is_verified,
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('OTP verification error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'message' => 'Verification failed. Please try again.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Resend OTP code
     * 
     * @route POST /api/resend-otp
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function resendOtp(Request $request)
    {
        try {
            Log::info('Resend OTP attempt', [
                'user_id' => $request->user_id,
            ]);

            $validator = Validator::make($request->all(), [
                'user_id' => 'required|exists:users,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'message' => 'Invalid user',
                    'errors' => $validator->errors(),
                ], 422);
            }

            $user = User::findOrFail($request->user_id);

            // Check if user is already verified
            if ($user->is_verified) {
                return response()->json([
                    'message' => 'User already verified',
                ], 400);
            }

            // Generate new OTP
            $otp = $user->generateOtp();

            // Queue email job
            Queue::dispatch(new SendOtpEmail($user, $otp));

            Log::info('OTP resent', [
                'user_id' => $user->id,
            ]);

            return response()->json([
                'message' => 'OTP has been resent to your email',
                'success' => true,
            ], 200);

        } catch (\Exception $e) {
            Log::error('Resend OTP error', [
                'message' => $e->getMessage(),
            ]);

            return response()->json([
                'message' => 'Failed to resend OTP',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
```

## 4. Routes Configuration

Add to `routes/api.php`:

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Auth\RegisterController;
use App\Http\Controllers\Api\Auth\LoginController;

Route::middleware('api')->prefix('api')->group(function () {
    // Public auth routes
    Route::post('/register', [RegisterController::class, 'register']);
    Route::post('/verify-otp', [RegisterController::class, 'verifyOtp']);
    Route::post('/resend-otp', [RegisterController::class, 'resendOtp']);
    Route::post('/login', [LoginController::class, 'login']);

    // Protected routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/user', function (Request $request) {
            return $request->user();
        });
        Route::post('/logout', [LoginController::class, 'logout']);
    });
});
```

## 5. CORS Configuration

Update `config/cors.php`:

```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => ['*'], // For development. Use specific URLs in production

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,
];
```

## 6. Mail Job (for OTP)

Create `app/Jobs/SendOtpEmail.php`:

```php
<?php

namespace App\Jobs;

use App\Mail\OtpMail;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class SendOtpEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $user;
    protected $otp;

    public function __construct(User $user, $otp)
    {
        $this->user = $user;
        $this->otp = $otp;
    }

    public function handle()
    {
        try {
            Mail::to($this->user->email)->send(new OtpMail($this->user, $this->otp));
            Log::info('OTP email sent', ['user_id' => $this->user->id]);
        } catch (\Exception $e) {
            Log::error('Failed to send OTP email', [
                'user_id' => $this->user->id,
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }
}
```

## 7. Mail Template

Create `app/Mail/OtpMail.php`:

```php
<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable, SerializesModels;

    protected $user;
    protected $otp;

    public function __construct(User $user, $otp)
    {
        $this->user = $user;
        $this->otp = $otp;
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Your OTP Code - ' . config('app.name'),
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.otp',
            with: [
                'user' => $this->user,
                'otp' => $this->otp,
            ],
        );
    }
}
```

Create view `resources/views/emails/otp.blade.php`:

```blade
<h2>Welcome, {{ $user->name }}!</h2>

<p>Your OTP code is: <strong>{{ $otp }}</strong></p>

<p>This code will expire in 10 minutes.</p>

<p>If you did not request this code, please ignore this email.</p>
```

## 8. Environment Configuration

Update `.env`:

```env
QUEUE_CONNECTION=database  # Or redis for production
MAIL_DRIVER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your_username
MAIL_PASSWORD=your_password
MAIL_ENCRYPTION=tls
```

## 9. Database Seeder for Phone Codes

Create migration for phone codes:

```bash
php artisan make:migration create_phone_codes_table
```

```php
Schema::create('phone_codes', function (Blueprint $table) {
    $table->id();
    $table->string('country_name');
    $table->string('country_code');
    $table->string('phone_code');
    $table->string('flag')->nullable();
    $table->timestamps();
    
    $table->unique(['country_code', 'phone_code']);
});
```

Seed it with countries data in `database/seeders/PhoneCodeSeeder.php`.

## 10. API Testing with Postman

### Register:
```
POST http://localhost:8000/api/register
Content-Type: application/json

{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "255700000000",
    "password": "password123",
    "password_confirmation": "password123"
}
```

### Verify OTP:
```
POST http://localhost:8000/api/verify-otp
Content-Type: application/json

{
    "user_id": 1,
    "otp_code": "123456"
}
```

### Resend OTP:
```
POST http://localhost:8000/api/resend-otp
Content-Type: application/json

{
    "user_id": 1
}
```

## 11. Key Optimization Points

1. **Non-blocking Email**: Use `Queue::dispatch()` for sending OTPs instead of synchronous Mail::send()
2. **Database Indexing**: Added indexes on email and phone for faster lookups
3. **OTP Expiration**: OTP expires after 10 minutes for security
4. **Error Logging**: All operations are logged for debugging
5. **Validation**: Input validation before database queries
6. **Password Hashing**: Use Laravel's Hash facade
7. **Token Generation**: Use Laravel Sanctum for API tokens
8. **CORS**: Properly configured for mobile clients

## 12. Running the Application

```bash
# Run migrations
php artisan migrate

# Start queue worker (if using database queue)
php artisan queue:work

# Run development server
php artisan serve
```

For better performance in production, use Redis queue worker:

```bash
php artisan queue:work redis --queue=default
```
