# Food Delivery — Rider App (Flutter)

The rider side of the multi-vendor food delivery demo. Riders see available
orders, accept one, follow a map from the restaurant to the customer, and mark
it **Picked Up → Delivered**. While delivering, the app shares the rider's GPS
with the backend every 10 seconds.

It talks to the same Laravel backend as the customer app (Dio + JWT, Provider).

## What's inside

```
lib/
├── main.dart                  # providers + named routes
├── config/                    # api_config, app_theme (deep teal #00695C), routes
├── models/                    # User, Order (with restaurant + delivery locations), OrderItem
├── services/
│   ├── api_service.dart       # shared Dio + JWT interceptor (same as customer app)
│   ├── auth_service.dart      # rider login / me / logout
│   ├── rider_service.dart     # available / accept / picked-up / delivered / history / location
│   └── location_service.dart  # GPS + "share my location every 10s" timer
├── providers/                 # AuthProvider (rider-only), RiderOrderProvider
├── widgets/                   # StatusBadge, PrimaryButton
└── screens/                   # Splash, RiderLogin, AvailableOrders, ActiveOrder, OrderHistory
```

## 1. Create the platform folders

```bash
cd food_delivery_rider
flutter create --platforms=android,ios,web .   # adds platform folders only; keeps lib/ + pubspec
flutter pub get
flutter analyze
flutter run
```

## 2. Point the app at your backend

Edit `lib/config/api_config.dart` → `baseUrl` (default `http://10.0.2.2:8000/api`
for the Android emulator). See the customer app's README for the full host table.

## 3. Android setup (important)

In `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- above <application> -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>

<!-- on the <application> tag (dev API is http, not https) -->
android:usesCleartextTraffic="true"

<!-- inside <application> (for the map) -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

iOS: add `NSLocationWhenInUseUsageDescription` to `Info.plist` and your Maps key
in `AppDelegate.swift`.

## 4. Create a rider account + a test order

The app needs (a) a **rider** account and (b) an order in **ready_for_pickup**
status. Until the restaurant app exists, set these up quickly with tinker:

```bash
php artisan migrate --seed     # roles, categories, an admin, etc.
php artisan tinker
```
```php
// a rider account (email: rider@test.com / password)
$rider = \App\Models\User::create([
    'name' => 'Test Rider', 'email' => 'rider@test.com',
    'password' => 'password', 'role' => 'rider', 'phone' => '111222',
]);
$rider->assignRole(\Spatie\Permission\Models\Role::findOrCreate('rider', 'api'));

// take an existing order (id 1) and push it to "ready_for_pickup"
$o = \App\Models\Order::find(1);
$o->transitionTo(\App\Enums\OrderStatus::ACCEPTED);
$o->transitionTo(\App\Enums\OrderStatus::PREPARING);
$o->transitionTo(\App\Enums\OrderStatus::READY_FOR_PICKUP);
```

(Place an order first from the customer app if you don't have one.)

## 5. Flow

Login (rider) → **Available Orders** → *Accept* → **Active Order**
(map + Picked Up → Delivered) → **History**.

## Notes
- **Rider-only login:** after signing in, the app checks `user.role == 'rider'`
  and refuses other accounts.
- **Live location:** `LocationService` posts `POST /api/rider/location` every 10
  seconds while the Active Order screen is open (backend endpoint added in this
  phase; stored on the rider's user row).
- **The map** shows a restaurant pin + a customer pin with a straight polyline
  between them, and centers on the rider's GPS. A real road route would use the
  Google Directions API.
- **Re-opening mid-delivery:** the active order is passed in memory from the
  accept step, so closing the app loses the active screen (a demo simplification).
