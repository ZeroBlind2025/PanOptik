# Unified Investment Portfolio App - Step by Step Build Guide

## Overview

Mobile app for personal portfolio aggregation. Manual asset logging, live pricing where available, alerts, premium risk analytics. RevenueCat subscriptions. TestFlight + Play Internal only.

-----

## Scope Lock (Read First)

- **Auth:** Supabase Auth is the source of truth. Backend validates Supabase JWT via JWKS. No custom password auth in NestJS. No passwordHash stored.
- **Asset math:** Ticker assets store `quantity`, value derived from `quantity * latestPrice`. Non-ticker assets store `manualValue` directly.
- **Pricing:** Polygon, CoinGecko, Metals-API only in v1. No broker integrations. No provider swaps until v2.
- **Tier enforcement:** Enforced server-side (not UI-only). Backend rejects asset create when free user has 10 assets. Backend rejects price alerts for free tier. Export endpoints premium-only.
- **Export:** CSV only in v1. No PDF.
- **Alerts:** Server-side only. No local-only reminders.
- **Cron:** Fixed intervals (15m stocks, 5m crypto, 30m commodities). No market-hours logic in v1.

-----

## Tech Stack

### Frontend (Mobile)

- **Framework:** Flutter
- **State Management:** Riverpod
- **Charts:** fl_chart (lighter, fewer surprises, v1 only)
- **Local Storage:** Hive

### Backend

- **Runtime:** Node.js + TypeScript
- **Framework:** NestJS
- **ORM:** Prisma
- **Database:** PostgreSQL (Supabase preferred)

### Auth

- Supabase Auth (source of truth)
- Email + password, reset, JWT
- Backend validates Supabase JWT via JWKS
- No custom password auth in NestJS
- Biometric unlock client-side

### Pricing APIs (Locked for v1)

- **Stocks/ETFs:** Polygon.io
- **Crypto:** CoinGecko
- **Commodities:** Metals-API

Provider swaps are v2.

### Notifications

- Firebase Cloud Messaging (FCM)
- Backend cron jobs / Supabase Edge Functions

### Monetization

- RevenueCat (iOS + Android subscriptions)

### Analytics & Observability

- **Product:** PostHog or Amplitude
- **Errors:** Sentry

### Infrastructure

- Supabase (API + DB + Edge Functions)
- GitHub + GitHub Actions (CI/CD)
- Manual promotion to TestFlight / Play Console

-----

## MVP Definition of Done

MVP is complete when a user can install the app via TestFlight or Play Internal, create an account, manually log at least five asset types, see a consolidated dashboard with cached live pricing, receive a push alert, and successfully purchase and unlock premium analytics via RevenueCat.

**Critical:** Entitlement state survives reinstall and restore purchases works.

This is the finish line. This is the acceptance criteria. This is the shield against scope creep.

-----

## Tier Limits

### Free Tier

- 10 assets maximum (server-enforced)
- Basic dashboard
- Date-based reminders only
- No price alerts (server-enforced)
- No export

### Premium Tier

- Unlimited assets
- Full analytics (country, sector, risk)
- Price threshold alerts
- CSV export only (no PDF in v1)

### Export Scope (Premium)

- CSV export includes assets list and latest prices only
- No transaction history (not stored)

-----

## Analytics Constraints (Legal Protection)

Analytics are **descriptive only**. The following are explicitly excluded:

- ❌ No forecasting
- ❌ No performance prediction
- ❌ No tax advice
- ❌ No optimization recommendations beyond diversification heuristics
- ❌ No investment advice of any kind

Risk scores and exposure charts show current state only.

-----

## Phase 1: Foundation

### 1.1 Flutter Project Setup

- [ ] Install Flutter SDK (latest stable)
- [ ] Create new Flutter project: `flutter create portfolio_app`
- [ ] Configure minimum iOS deployment target (iOS 13+)
- [ ] Configure minimum Android SDK (API 24+)
- [ ] Add core dependencies to pubspec.yaml:
  - flutter_riverpod
  - hive
  - hive_flutter
  - go_router
  - dio
  - flutter_secure_storage

### 1.2 Project Structure (Frontend)

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── environment.dart
│   └── theme.dart
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── assets/
│   ├── alerts/
│   └── premium/
├── models/
├── providers/
├── services/
├── widgets/
└── utils/
```

### 1.3 Backend Project Setup

- [ ] Create new directory: `portfolio-api`
- [ ] Initialize NestJS project: `nest new portfolio-api`
- [ ] Install dependencies:
  - @nestjs/config
  - @prisma/client
  - prisma
  - @nestjs/jwt
  - @nestjs/passport
  - passport-jwt
  - class-validator
  - class-transformer

### 1.4 Project Structure (Backend)

```
src/
├── main.ts
├── app.module.ts
├── config/
├── modules/
│   ├── auth/
│   ├── users/
│   ├── assets/
│   ├── prices/
│   ├── alerts/
│   └── subscriptions/
├── prisma/
│   └── schema.prisma
└── common/
    ├── guards/
    ├── decorators/
    └── interceptors/
```

### 1.5 Database Setup

- [ ] Create Supabase project
- [ ] Retrieve connection string
- [ ] Configure Prisma datasource
- [ ] Create initial schema (see schema below)
- [ ] Run first migration: `npx prisma migrate dev --name init`

### 1.6 Prisma Schema

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id                 String         @id @default(uuid())
  supabaseId         String         @unique
  email              String         @unique
  createdAt          DateTime       @default(now())
  updatedAt          DateTime       @updatedAt
  subscriptionStatus String         @default("free")
  fcmToken           String?
  assets             Asset[]
  alerts             Alert[]
  subscription       Subscription?
}

model Asset {
  id           String    @id @default(uuid())
  userId       String
  user         User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  type         String
  name         String
  ticker       String?
  quantity     Decimal?  // For ticker assets: value = quantity * price
  manualValue  Decimal?  // For non-ticker assets: real estate, cash, etc.
  costBasis    Decimal?  // Optional, premium feature later
  currency     String    @default("USD")
  country      String?
  sector       String?
  riskCategory String?
  notes        String?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  alerts       Alert[]
}

model Price {
  id        String   @id @default(uuid())
  ticker    String
  assetType String   // stock, crypto, commodity
  currency  String   @default("USD")
  provider  String   // polygon, coingecko, metalsapi
  price     Decimal
  fetchedAt DateTime @default(now())

  @@unique([ticker, assetType, currency])
}

model Alert {
  id             String    @id @default(uuid())
  userId         String
  user           User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  assetId        String?
  asset          Asset?    @relation(fields: [assetId], references: [id], onDelete: Cascade)
  type           String    // price_above, price_below, date_reminder, recurring_reminder
  triggerValue   String?
  message        String
  nextFire       DateTime?
  recurring      Boolean   @default(false)
  rrule          String?   // RRULE for recurring (weekly/monthly)
  enabled        Boolean   @default(true)
  createdAt      DateTime  @default(now())
}

model Subscription {
  id           String    @id @default(uuid())
  userId       String    @unique
  user         User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  revenuecatId String    @unique
  status       String
  plan         String?
  expiresAt    DateTime?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
}
```

### 1.7 Auth Setup

- [ ] Configure Supabase Auth in Supabase dashboard
- [ ] Enable email/password provider
- [ ] Configure password reset email template
- [ ] Create NestJS auth module (JWT validation only)
- [ ] Implement Supabase JWT verification via JWKS
- [ ] Create auth guard (validates Supabase token)
- [ ] Implement endpoint:
  - GET /auth/me (returns current user from Supabase token)

### 1.8 Flutter Auth Integration

- [ ] Add supabase_flutter package
- [ ] Configure Supabase client
- [ ] Create AuthService
- [ ] Create AuthProvider (Riverpod)
- [ ] Build login screen
- [ ] Build registration screen
- [ ] Build forgot password screen
- [ ] Implement biometric unlock with flutter_secure_storage
- [ ] Create auth state listener
- [ ] Implement auto-logout on token expiry

-----

## Phase 2: Core Asset Management

### 2.1 Backend Asset Module

- [ ] Generate NestJS module: `nest g module assets`
- [ ] Generate controller: `nest g controller assets`
- [ ] Generate service: `nest g service assets`
- [ ] Implement DTOs:
  - CreateAssetDto
  - UpdateAssetDto
  - AssetResponseDto
- [ ] Implement endpoints:
  - GET /assets (list user assets)
  - GET /assets/:id (single asset)
  - POST /assets (create, reject if free user has 10 assets)
  - PATCH /assets/:id (update)
  - DELETE /assets/:id (delete)
- [ ] Add validation pipes
- [ ] Add user ownership guard
- [ ] Add tier enforcement guard (server-side, not UI-only)

### 2.2 Asset Types Configuration

```typescript
enum AssetType {
  STOCK = 'stock',
  ETF = 'etf',
  CRYPTO = 'crypto',
  FUND = 'fund',
  BOND = 'bond',
  REAL_ESTATE = 'real_estate',
  CASH = 'cash',
  COMMODITY = 'commodity'
}
```

### 2.3 Flutter Asset Models

- [ ] Create Asset model class
- [ ] Create AssetType enum
- [ ] Implement JSON serialization
- [ ] Implement Hive type adapters

### 2.4 Flutter Asset Service

- [ ] Create AssetsService
- [ ] Implement API calls (Dio)
- [ ] Implement local caching (Hive)
- [ ] Create AssetsProvider (Riverpod)
- [ ] Implement optimistic updates

### 2.5 Flutter Asset Screens

- [ ] Asset list screen
  - Pull to refresh
  - Empty state
  - Loading state
  - Error state
- [ ] Add asset flow:
  - Step 1: Select asset type
  - Step 2: Search ticker OR manual entry
  - Step 3: Enter value, currency
  - Step 4: Assign metadata (country, sector, risk)
  - Step 5: Confirm and save
- [ ] Asset detail screen
  - Current value display
  - Percentage of portfolio
  - Price change (if live)
  - Edit button
  - Delete button
  - Reminder settings
- [ ] Edit asset screen
  - Pre-populated form
  - Validation
  - Save/cancel

### 2.6 Ticker Search

- [ ] Backend endpoint: GET /search/ticker?q=
- [ ] Integrate with Polygon symbol search API
- [ ] Return: symbol, name, type, exchange
- [ ] Flutter: implement search-as-you-type
- [ ] Debounce input (300ms)
- [ ] Display results in list

-----

## Phase 3: Dashboard

### 3.1 Backend Dashboard Endpoint

- [ ] Create dashboard module
- [ ] Implement GET /dashboard
- [ ] Return:
  - totalValue
  - dailyChange
  - dailyChangePercent
  - weeklyChange
  - weeklyChangePercent
  - allocationByType
  - allocationByCountry
  - allocationBySector
- [ ] Calculate from user assets + cached prices

### 3.2 Flutter Dashboard Screen

- [ ] Total portfolio value (large, prominent)
- [ ] Daily/weekly change with color coding
- [ ] Allocation pie chart (by asset type)
- [ ] Allocation bar chart (by country)
- [ ] Allocation bar chart (by sector)
- [ ] Premium CTA banner (if free user)
- [ ] Pull to refresh
- [ ] Last updated timestamp

### 3.3 Charts Implementation

- [ ] Add fl_chart package
- [ ] Create reusable PieChart widget
- [ ] Create reusable BarChart widget
- [ ] Implement color coding per category
- [ ] Add chart legends
- [ ] Add touch interactions (show value on tap)

### 3.4 Offline Support

- [ ] Cache dashboard data in Hive
- [ ] Show cached data immediately on app open
- [ ] Fetch fresh data in background
- [ ] Show “last updated” indicator
- [ ] Handle offline state gracefully

-----

## Phase 4: Pricing

### 4.1 Pricing Service (Backend)

- [ ] Create prices module
- [ ] Create pricing providers:
  - PolygonProvider (stocks/ETFs)
  - CoinGeckoProvider (crypto)
  - MetalsApiProvider (gold/silver)
- [ ] Implement PricingService
  - getPrice(ticker, type)
  - getBatchPrices(tickers[])
  - getCachedPrice(ticker)
- [ ] Implement caching logic:
  - Check cache first
  - If stale (>15 min), fetch fresh
  - Update cache
  - Return price

### 4.2 Price Cache Strategy

```typescript
const CACHE_TTL = {
  stock: 15 * 60 * 1000,     // 15 minutes
  crypto: 5 * 60 * 1000,     // 5 minutes
  commodity: 30 * 60 * 1000  // 30 minutes
}
```

### 4.3 Scheduled Price Updates

- [ ] Create cron job: update active tickers
- [ ] Stocks/ETFs: every 15 minutes (always)
- [ ] Crypto: every 5 minutes (always)
- [ ] Commodities: every 30 minutes (always)
- [ ] No market-hours logic in v1
- [ ] Batch API calls to minimize costs
- [ ] Log failures, retry with backoff

### 4.4 Flutter Price Integration

- [ ] Display live prices on assets with tickers
- [ ] Show price change indicator (up/down arrow)
- [ ] Show “manual” badge for non-priced assets
- [ ] Refresh prices on pull-to-refresh
- [ ] Cache prices locally for offline

-----

## Phase 5: Alerts & Reminders

### 5.1 Backend Alerts Module

- [ ] Create alerts module
- [ ] Implement endpoints:
  - GET /alerts
  - POST /alerts (reject price alerts for free tier)
  - PATCH /alerts/:id
  - DELETE /alerts/:id
- [ ] Alert types:
  - price_above (premium only)
  - price_below (premium only)
  - date_reminder (one-time, fires at timestamp)
  - recurring_reminder (RRULE: weekly/monthly)
- [ ] All alerts server-side only (no local-only)
- [ ] Delivery: push notification only (no email)

### 5.2 Alert Processing Service

- [ ] Create AlertProcessorService
- [ ] Cron job: check alerts every 5 minutes
- [ ] For price alerts:
  - Compare current price vs trigger
  - If triggered, queue notification
  - Mark alert as triggered (or reset if recurring)
- [ ] For date alerts:
  - Compare current time vs nextFire
  - If due, queue notification
  - Calculate next fire if recurring

### 5.3 Firebase Cloud Messaging Setup

- [ ] Create Firebase project
- [ ] Enable Cloud Messaging
- [ ] Download google-services.json (Android)
- [ ] Download GoogleService-Info.plist (iOS)
- [ ] Add firebase_messaging package to Flutter
- [ ] Configure iOS push capabilities
- [ ] Configure Android notification channel

### 5.4 FCM Backend Integration

- [ ] Install firebase-admin SDK
- [ ] Create NotificationService
- [ ] Store FCM tokens per user
- [ ] Implement sendPushNotification(userId, title, body)
- [ ] Handle token refresh

### 5.5 Flutter Alerts UI

- [ ] Alerts list screen
- [ ] Create alert flow:
  - Select type
  - Select asset (if price alert)
  - Set trigger value or date
  - Set recurrence (optional)
  - Enable/disable toggle
- [ ] Edit alert screen
- [ ] Delete confirmation
- [ ] In-app notification display

-----

## Phase 6: Premium Analytics

### 6.1 Backend Analytics Endpoints

- [ ] Create analytics module
- [ ] Implement GET /analytics/exposure
  - countryExposure[]
  - sectorExposure[]
- [ ] Implement GET /analytics/risk
  - riskScore (0-100)
  - riskFactors[]
  - recommendations[]
- [ ] Add premium guard (check subscription)

### 6.2 Risk Score Calculation

```typescript
function calculateRiskScore(assets: Asset[]): number {
  let score = 50;

  // Single asset dominance (>50% in one asset)
  if (hasConcentration(assets, 0.5)) score += 20;

  // Sector overexposure (>40% in one sector)
  if (hasSectorOverexposure(assets, 0.4)) score += 15;

  // Low diversification (<5 assets)
  if (assets.length < 5) score += 10;

  // High cash allocation (>30%)
  if (getCashAllocation(assets) > 0.3) score -= 10;

  // No bonds/fixed income
  if (!hasFixedIncome(assets)) score += 5;

  return Math.min(100, Math.max(0, score));
}
```

### 6.3 Flutter Premium Screens

- [ ] Country exposure screen
  - World map visualization (optional)
  - Bar chart by country
  - Percentage breakdown
- [ ] Sector exposure screen
  - Pie chart by sector
  - List with percentages
- [ ] Risk analysis screen
  - Risk score gauge (0-100)
  - Risk category (Low/Medium/High)
  - Risk factors list
  - Recommendations list
- [ ] Concentration warnings
  - Alert badges on overweight positions
  - Suggestions to diversify

### 6.4 Paywall Implementation

- [ ] Create PremiumGuard widget
- [ ] Wrap premium screens
- [ ] Show upgrade prompt for free users
- [ ] Deep link to subscription screen

-----

## Phase 7: RevenueCat

### 7.1 RevenueCat Setup

- [ ] Create RevenueCat account
- [ ] Create project
- [ ] Configure iOS App Store Connect:
  - Add in-app purchases
  - Create subscription group
  - Add monthly product
  - Add annual product
- [ ] Configure Google Play Console:
  - Create subscriptions
  - Add monthly product
  - Add annual product
- [ ] Link stores in RevenueCat
- [ ] Create entitlement: “premium”
- [ ] Create offering: “default”

### 7.2 Flutter RevenueCat Integration

- [ ] Add purchases_flutter package
- [ ] Initialize RevenueCat on app start
- [ ] Create SubscriptionService
- [ ] Create SubscriptionProvider (Riverpod)
- [ ] Implement:
  - getOfferings()
  - purchasePackage()
  - restorePurchases()
  - checkEntitlement()

### 7.3 Subscription UI

- [ ] Subscription screen
  - Feature comparison (free vs premium)
  - Monthly price
  - Annual price (with savings %)
  - Purchase buttons
  - Restore purchases link
  - Terms and privacy links
- [ ] Loading state during purchase
- [ ] Success state
- [ ] Error handling

### 7.4 Backend Webhook

- [ ] Create POST /webhooks/revenuecat
- [ ] Verify webhook signature
- [ ] Handle events:
  - INITIAL_PURCHASE
  - RENEWAL
  - CANCELLATION
  - EXPIRATION
- [ ] Update user subscription status
- [ ] Log all events

### 7.5 Entitlement Sync

- [ ] On app open: check RevenueCat entitlements
- [ ] Sync status to backend
- [ ] Cache entitlement locally
- [ ] Refresh on subscription screen visit

-----

## Phase 8: Observability

### 8.1 PostHog Setup

- [ ] Create PostHog account
- [ ] Create project
- [ ] Add posthog_flutter package
- [ ] Initialize on app start
- [ ] Identify user on login

### 8.2 Event Tracking

- [ ] Track events:
  - app_opened
  - user_registered
  - user_logged_in
  - asset_added
  - asset_deleted
  - dashboard_viewed
  - premium_screen_viewed
  - purchase_started
  - purchase_completed
  - purchase_failed
  - alert_created

### 8.3 Sentry Setup

- [ ] Create Sentry account
- [ ] Create Flutter project
- [ ] Create Node.js project
- [ ] Add sentry_flutter package
- [ ] Configure DSN
- [ ] Initialize on app start
- [ ] Add to NestJS:
  - Install @sentry/node
  - Configure global error filter
  - Add request context

### 8.4 Error Boundaries

- [ ] Create Flutter error boundary widget
- [ ] Catch and report unhandled exceptions
- [ ] Show user-friendly error screen
- [ ] Include “Report Issue” button

-----

## Phase 9: Deploy

### 9.1 Backend Deployment

- [ ] Create Supabase Edge Functions (if needed)
- [ ] Or deploy NestJS to:
  - Railway
  - Render
  - AWS ECS
- [ ] Configure environment variables
- [ ] Set up production database
- [ ] Run migrations
- [ ] Verify endpoints with Postman

### 9.2 CI/CD Setup

- [ ] Create GitHub repository
- [ ] Create GitHub Actions workflow:
  - On push to main: run tests
  - On tag: build and deploy
- [ ] Flutter workflow:
  - Build iOS
  - Build Android
  - Upload artifacts

### 9.3 iOS TestFlight

- [ ] Create App Store Connect app
- [ ] Configure app identifier
- [ ] Generate provisioning profiles
- [ ] Build release: `flutter build ipa`
- [ ] Upload to App Store Connect
- [ ] Submit for TestFlight review
- [ ] Add internal testers

### 9.4 Android Internal Testing

- [ ] Create Google Play Console app
- [ ] Configure signing key
- [ ] Build release: `flutter build appbundle`
- [ ] Upload to Play Console
- [ ] Create internal testing track
- [ ] Add testers

### 9.5 Demo Data

- [ ] Create seed script
- [ ] Generate sample user
- [ ] Add diverse assets:
  - 3 stocks
  - 2 crypto
  - 1 real estate
  - 1 cash account
  - 1 gold position
- [ ] Add sample alerts
- [ ] Document demo credentials

### 9.6 Final Testing

- [ ] Test on physical iOS device
- [ ] Test on physical Android device
- [ ] Test offline mode
- [ ] Test push notifications
- [ ] Test subscription flow (sandbox)
- [ ] Test all CRUD operations
- [ ] Performance check (<2s launch, <1s dashboard)

### 9.7 Handoff

- [ ] Transfer GitHub repository
- [ ] Document all environment variables
- [ ] Document API keys and accounts
- [ ] Provide Supabase access
- [ ] Provide RevenueCat access
- [ ] Provide Firebase access
- [ ] Provide PostHog access
- [ ] Provide Sentry access
- [ ] Final walkthrough call

-----

## Done Checklist

- [ ] Users can register and login
- [ ] Users can add/edit/delete assets
- [ ] Live pricing works for stocks/crypto/commodities
- [ ] Manual assets can be valued
- [ ] Dashboard shows portfolio overview
- [ ] Charts display allocations
- [ ] Alerts can be created and triggered
- [ ] Push notifications work
- [ ] Premium upgrade flow works
- [ ] Risk analysis displays for premium users
- [ ] App runs offline with cached data
- [ ] App is stable on real devices
- [ ] TestFlight build available
- [ ] Play Internal Testing build available
- [ ] Source code transferred
- [ ] Documentation complete
