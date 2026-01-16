# Unified Investment Portfolio App

A mobile application for personal investment portfolio tracking. Log all assets in one place, get real-time pricing where available, set alerts and reminders, and unlock premium risk analysis.

**Not a trading app. A portfolio intelligence dashboard.**

-----

## Scope Lock

- **Auth:** Supabase Auth is the source of truth. Backend validates Supabase JWT. No custom password auth.
- **Asset math:** Ticker assets store `quantity`, value derived from `quantity * price`. Non-ticker assets store `manualValue`.
- **Pricing:** Polygon, CoinGecko, Metals-API only in v1. No broker integrations.
- **Tier enforcement:** Server-side (not UI-only).
- **Export:** CSV only in v1. No PDF.

-----

## Features

### Free Tier

- Manual asset logging (10 assets max, server-enforced)
- Live pricing for stocks, ETFs, crypto, commodities
- Portfolio dashboard with total value
- Daily/weekly change tracking
- Basic allocation view
- Date-based reminders (server-side only)

### Premium Tier

- Unlimited assets
- Country exposure analysis
- Sector exposure analysis
- Concentration warnings
- Risk score and recommendations
- Price threshold alerts (server-enforced)
- CSV export only (no PDF in v1)

-----

## MVP Definition of Done

MVP is complete when a user can install the app via TestFlight or Play Internal, create an account, manually log at least five asset types, see a consolidated dashboard with cached live pricing, receive a push alert, and successfully purchase and unlock premium analytics via RevenueCat.

**Critical:** Entitlement state survives reinstall and restore purchases works.

-----

## Analytics Constraints

Analytics are **descriptive only**:

- ❌ No forecasting
- ❌ No performance prediction
- ❌ No tax advice
- ❌ No optimization recommendations beyond diversification heuristics
- ❌ No investment advice of any kind

Risk scores and exposure charts show current state only.

-----

## Supported Asset Types

|Asset Type                |Pricing            |
|--------------------------|-------------------|
|Stocks / ETFs             |Live via market API|
|Cryptocurrency            |Live via crypto API|
|Commodities (Gold, Silver)|Live spot price    |
|Mutual Funds              |Manual             |
|Bonds                     |Manual             |
|Real Estate               |Manual             |
|Cash / Savings            |Manual             |

-----

## Tech Stack

### Mobile

- Flutter
- Riverpod (state management)
- Hive (local storage)
- fl_chart (charts, v1 only)

### Backend

- Node.js + TypeScript
- NestJS
- Prisma ORM
- PostgreSQL (Supabase)

### Services

- Supabase Auth (source of truth)
- Firebase Cloud Messaging
- RevenueCat
- PostHog
- Sentry

### Pricing APIs (Locked for v1)

- Polygon.io (stocks/ETFs)
- CoinGecko (crypto)
- Metals-API (commodities)

Provider swaps are v2.

-----

## Project Structure

```
/
├── portfolio_app/          # Flutter mobile app
│   ├── lib/
│   ├── ios/
│   ├── android/
│   └── pubspec.yaml
│
├── portfolio-api/          # NestJS backend
│   ├── src/
│   ├── prisma/
│   └── package.json
│
└── docs/
    ├── BUILD.md
    └── README.md
```

-----

## Environment Variables

### Backend (.env)

```
DATABASE_URL=
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=
JWT_SECRET=
POLYGON_API_KEY=
COINGECKO_API_KEY=
METALS_API_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=
REVENUECAT_WEBHOOK_SECRET=
SENTRY_DSN=
```

### Flutter (lib/config/environment.dart)

```dart
class Environment {
  static const apiUrl = String.fromEnvironment('API_URL');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const revenueCatApiKey = String.fromEnvironment('REVENUECAT_API_KEY');
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
```

-----

## Running Locally

### Backend

```bash
cd portfolio-api
npm install
npx prisma migrate dev
npm run start:dev
```

### Flutter

```bash
cd portfolio_app
flutter pub get
flutter run
```

-----

## Building for Release

### iOS

```bash
flutter build ipa --release
# Upload to App Store Connect via Transporter
```

### Android

```bash
flutter build appbundle --release
# Upload to Play Console
```

-----

## API Endpoints

### Auth

- `GET /auth/me` (returns current user from Supabase token)

*Note: Auth handled by Supabase directly. Backend validates JWT only.*

### Assets

- `GET /assets`
- `GET /assets/:id`
- `POST /assets`
- `PATCH /assets/:id`
- `DELETE /assets/:id`

### Dashboard

- `GET /dashboard`

### Prices

- `GET /prices/:ticker`
- `GET /search/ticker?q=`

### Alerts

- `GET /alerts`
- `POST /alerts`
- `PATCH /alerts/:id`
- `DELETE /alerts/:id`

### Analytics (Premium)

- `GET /analytics/exposure`
- `GET /analytics/risk`

### Webhooks

- `POST /webhooks/revenuecat`

-----

## Database Schema

### Users

```sql
- id (uuid, primary key)
- supabaseId (unique)
- email (unique)
- createdAt
- updatedAt
- subscriptionStatus
- fcmToken (nullable)
```

### Assets

```sql
- id (uuid, primary key)
- userId (foreign key)
- type
- name
- ticker (nullable)
- quantity (nullable, for ticker assets)
- manualValue (nullable, for non-ticker assets)
- costBasis (nullable, premium feature)
- currency
- country
- sector
- riskCategory
- notes
- createdAt
- updatedAt
```

### Prices

```sql
- id (uuid, primary key)
- ticker
- assetType
- currency
- provider
- price
- fetchedAt
- unique(ticker, assetType, currency)
```

### Alerts

```sql
- id (uuid, primary key)
- userId (foreign key)
- assetId (foreign key, nullable)
- type
- triggerValue
- message
- nextFire
- recurring
- rrule (for recurring)
- enabled
- createdAt
```

### Subscriptions

```sql
- id (uuid, primary key)
- userId (foreign key, unique)
- revenuecatId (unique)
- status
- plan
- expiresAt
- createdAt
- updatedAt
```

-----

## Exclusions

This MVP explicitly does NOT include:

- ❌ Broker integrations
- ❌ Plaid / OAuth financial access
- ❌ Tax reporting
- ❌ AI forecasting
- ❌ Web dashboard
- ❌ Social features
- ❌ Advisor tools

-----

## Security

- HTTPS everywhere
- JWT authentication
- Encrypted local storage
- No financial credentials stored
- No brokerage connections
- RevenueCat handles all payments
- Out of PCI scope
- Out of financial custody regulations

-----

## Testing Credentials

### Demo User

```
Email: demo@example.com
Password: [provided separately]
```

### Sandbox Subscriptions

- iOS: Use sandbox Apple ID
- Android: Use license testing account

-----

## Delivery

- iOS: TestFlight (internal testing)
- Android: Play Console Internal Testing
- No public app store release required

-----

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
