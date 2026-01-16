# PanOptik Project Status

**Last Updated:** January 16, 2026

## Overview

PanOptik is a unified investment portfolio tracking mobile application with a NestJS backend. The project structure and core files have been created and pushed to GitHub.

---

## Repository

**GitHub:** https://github.com/ZeroBlind2025/PanOptik

---

## What Has Been Built

### Backend (NestJS) - `portfolio-api/`

| Component | Status | Files |
|-----------|--------|-------|
| **Project Setup** | ✅ Complete | `package.json`, `tsconfig.json`, `nest-cli.json` |
| **Prisma Schema** | ✅ Complete | `prisma/schema.prisma` |
| **App Module** | ✅ Complete | `src/app.module.ts` |
| **Main Entry** | ✅ Complete | `src/main.ts` |
| **Configuration** | ✅ Complete | `src/config/configuration.ts` |
| **Prisma Service** | ✅ Complete | `src/prisma.service.ts` |
| **Railway Deployment** | ✅ Complete | `railway.json`, `Procfile`, `nixpacks.toml` |

#### Modules

| Module | Controller | Service | DTOs | Guards/Decorators |
|--------|------------|---------|------|-------------------|
| **Auth** | ✅ | ✅ | ✅ Register/Login | ✅ JWT Strategy |
| **Users** | - | ✅ | - | - |
| **Assets** | ✅ | ✅ | ✅ Create/Update | - |
| **Prices** | ✅ | ✅ | - | ✅ 3 Providers |
| **Alerts** | ✅ | ✅ | ✅ Create/Update | ✅ Processor + Notifications |
| **Dashboard** | ✅ | ✅ | - | - |
| **Analytics** | ✅ | ✅ | - | - |
| **Subscriptions** | ✅ | ✅ | - | - |
| **Webhooks** | ✅ | - | - | - |
| **Health** | ✅ | - | - | - |

#### Authentication

- **Local JWT auth** with bcrypt password hashing
- `POST /auth/register` - Create new account
- `POST /auth/login` - Login and receive JWT
- `GET /auth/me` - Get current user (protected)

#### Price Providers

| Provider | File | API |
|----------|------|-----|
| Polygon.io | `providers/polygon.provider.ts` | Stocks/ETFs |
| CoinGecko | `providers/coingecko.provider.ts` | Crypto |
| Metals-API | `providers/metalsapi.provider.ts` | Commodities |

#### Common Utilities

| Utility | File | Purpose |
|---------|------|---------|
| Premium Guard | `common/guards/premium.guard.ts` | Restrict premium endpoints |
| Current User Decorator | `common/decorators/current-user.decorator.ts` | Extract user from request |

---

### Mobile App (Flutter) - `portfolio_app/`

| Component | Status | File |
|-----------|--------|------|
| **pubspec.yaml** | ✅ Complete | Dependencies configured |
| **Main Entry** | ✅ Complete | `lib/main.dart` |
| **App Widget** | ✅ Complete | `lib/app.dart` |

#### Configuration

| Config | File | Purpose |
|--------|------|---------|
| Environment | `lib/config/environment.dart` | API URLs, keys |
| Router | `lib/config/router.dart` | GoRouter navigation |
| Theme | `lib/config/theme.dart` | App theming |

#### Models

| Model | File |
|-------|------|
| User | `lib/models/user.dart` |
| Asset | `lib/models/asset.dart` |
| Price | `lib/models/price.dart` |
| Alert | `lib/models/alert.dart` |
| Dashboard | `lib/models/dashboard.dart` |

#### Services

| Service | File | Purpose |
|---------|------|---------|
| API Service | `lib/services/api_service.dart` | HTTP client |
| Auth Service | `lib/services/auth_service.dart` | JWT auth |
| Assets Service | `lib/services/assets_service.dart` | Asset CRUD |
| Prices Service | `lib/services/prices_service.dart` | Price fetching |
| Alerts Service | `lib/services/alerts_service.dart` | Alert management |
| Dashboard Service | `lib/services/dashboard_service.dart` | Dashboard data |
| Analytics Service | `lib/services/analytics_service.dart` | Premium analytics |
| Subscription Service | `lib/services/subscription_service.dart` | RevenueCat |
| Notification Service | `lib/services/notification_service.dart` | FCM |

#### Providers (Riverpod)

| Provider | File |
|----------|------|
| Auth Provider | `lib/providers/auth_provider.dart` |
| Assets Provider | `lib/providers/assets_provider.dart` |
| Alerts Provider | `lib/providers/alerts_provider.dart` |
| Dashboard Provider | `lib/providers/dashboard_provider.dart` |
| Subscription Provider | `lib/providers/subscription_provider.dart` |

#### Screens

| Feature | Screens |
|---------|---------|
| **Auth** | Login, Register, Forgot Password |
| **Dashboard** | Dashboard |
| **Assets** | List, Add, Edit, Detail |
| **Alerts** | List, Add |
| **Premium** | Subscription, Analytics, Risk Analysis |

#### Widgets

| Widget | File | Purpose |
|--------|------|---------|
| Loading Button | `lib/widgets/loading_button.dart` | Async button |
| Portfolio Value Card | `lib/features/dashboard/widgets/portfolio_value_card.dart` | Value display |
| Allocation Chart | `lib/features/dashboard/widgets/allocation_chart.dart` | Pie chart |
| Premium Banner | `lib/features/dashboard/widgets/premium_banner.dart` | Upgrade CTA |
| Asset Type Selector | `lib/features/assets/widgets/asset_type_selector.dart` | Type picker |
| Ticker Search Field | `lib/features/assets/widgets/ticker_search_field.dart` | Search input |
| Premium Guard | `lib/features/premium/widgets/premium_guard.dart` | Feature gate |
| Risk Gauge | `lib/features/premium/widgets/risk_gauge.dart` | Risk visualization |

---

### Database Schema (Prisma)

```
┌─────────────────┐     ┌─────────────────┐
│      User       │     │      Asset      │
├─────────────────┤     ├─────────────────┤
│ id              │────<│ userId          │
│ email           │     │ type            │
│ passwordHash    │     │ name            │
│ subscriptionStat│     │ ticker          │
│ fcmToken        │     │ quantity        │
│ createdAt       │     │ manualValue     │
│ updatedAt       │     │ country         │
└─────────────────┘     │ sector          │
        │               │ riskCategory    │
        │               │ notes           │
        │               └─────────────────┘
        │
        │               ┌─────────────────┐
        └──────────────<│      Alert      │
        │               ├─────────────────┤
        │               │ userId          │
        │               │ assetId         │
        │               │ type            │
        │               │ threshold       │
        │               │ triggered       │
        │               │ scheduledDate   │
        │               │ recurrence      │
        │               └─────────────────┘
        │
        │               ┌─────────────────┐
        └──────────────<│  Subscription   │
                        ├─────────────────┤
                        │ userId (unique) │
                        │ revenuecatId    │
                        │ status          │
                        │ plan            │
                        │ expiresAt       │
                        └─────────────────┘

┌─────────────────┐
│      Price      │
├─────────────────┤
│ ticker          │
│ assetType       │
│ price           │
│ currency        │
│ updatedAt       │
└─────────────────┘
(unique: ticker + assetType + currency)
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `.gitignore` | Git ignore rules |
| `README.md` | Project documentation |
| `docs/BUILD.md` | Detailed build specification |
| `portfolio-api/.env.example` | Environment variable template |
| `portfolio-api/railway.json` | Railway deployment config |
| `portfolio-api/Procfile` | Railway process file |
| `portfolio-api/nixpacks.toml` | Nixpacks build config |

---

## Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/portfolio

# JWT Authentication
JWT_SECRET=your-secret-key-at-least-32-characters-long

# Pricing APIs
POLYGON_API_KEY=your-polygon-api-key
COINGECKO_API_KEY=your-coingecko-api-key
METALS_API_KEY=your-metals-api-key

# Firebase (for push notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com

# RevenueCat
REVENUECAT_WEBHOOK_SECRET=your-webhook-secret
```

---

## What Needs To Be Done

### Immediate (Before First Deploy)

- [ ] Set up Railway project with PostgreSQL database
- [ ] Add environment variables in Railway
- [ ] Set Railway root directory to `portfolio-api`
- [ ] Run `npx prisma migrate deploy` to create database tables
- [ ] Install Flutter SDK on development machine
- [ ] Run `flutter pub get` in `portfolio_app/`

### Backend Tasks

- [ ] Add rate limiting
- [ ] Add request logging middleware
- [ ] Write unit tests for services
- [ ] Write e2e tests for controllers

### Mobile App Tasks

- [ ] Generate Flutter project files (`flutter create .` in portfolio_app)
- [ ] Update auth service to use local JWT instead of Supabase
- [ ] Configure iOS/Android build settings
- [ ] Set up Firebase project for FCM
- [ ] Configure RevenueCat products
- [ ] Add app icons and splash screen
- [ ] Test on iOS simulator and Android emulator

### Integration Tasks

- [ ] Test auth flow end-to-end (register/login)
- [ ] Test price fetching from all 3 APIs
- [ ] Test alert triggering and push notifications
- [ ] Test RevenueCat webhook handling
- [ ] Test premium feature gating

---

## Tech Stack Summary

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.x, Riverpod, Hive, fl_chart |
| Backend | NestJS, Prisma, PostgreSQL |
| Auth | Local JWT with bcrypt |
| Database | PostgreSQL (Railway) |
| Pricing | Polygon.io, CoinGecko, Metals-API |
| Subscriptions | RevenueCat |
| Push Notifications | Firebase Cloud Messaging |
| Observability | PostHog, Sentry |
| Hosting | Railway (backend) |

---

## File Count

- **Backend files:** 45
- **Flutter files:** 46
- **Config/docs:** 11
- **Total:** 112 files
