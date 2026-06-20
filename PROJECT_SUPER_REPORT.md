# Project Super Report: Personal Finance App (Flutter)

This report provides a comprehensive overview of the Personal Finance App project to bring a new AI assistant up to speed.

## 1. Project Overview
- **Name**: Personal Finance App
- **Platform**: Flutter (Android/iOS/Web/Desktop)
- **Primary Focus**: Automating expense tracking through Bank SMS parsing and providing manual entry for financial management.
- **Target Region**: Sri Lanka (supports local banks and languages).

## 2. Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: `flutter_riverpod` (with code generation via `riverpod_generator`).
- **Database**: `drift` (ORM for SQLite) for local persistence.
- **Charts**: `fl_chart` for financial analytics.
- **Background Tasks**: `workmanager` for monthly summaries.
- **Notifications**: `flutter_local_notifications`.
- **Authentication**: `local_auth` for biometric/PIN lock.
- **SMS Integration**: `flutter_sms_inbox` and `permission_handler`.

## 3. Architecture
The project follows a **Clean Architecture** inspired structure:
- `lib/core/`: Common constants and theme (currently light).
- `lib/domain/`: Entities (e.g., `BankTransaction`) and business logic interfaces.
- `lib/data/`: 
    - `models/`: Database table definitions (Categories, Accounts, Transactions, CategoryRules).
    - `datasources/`: Drift database implementation (`AppDatabase`) and DAOs.
- `lib/presentation/`:
    - `screens/`: UI pages (Dashboard, Analytics, Settings, etc.).
    - `providers/`: Riverpod providers for state.
- `lib/services/`: Specific services like `SmsParserService` and `LocalAuthService`.
- `lib/utils/`: Helpers like `AppTranslations` and `NotificationService`.

## 4. Core Features
### A. SMS Transaction Parsing (Automated Tracking)
- **Banks Supported**: Bank of Ceylon (BOC), National Savings Bank (NSB), People's Bank.
- **Logic**: Uses a `SmsParserRegistry` to identify the sender and use a specific parser (e.g., `BocParser`) to extract amount, type (income/expense), and account details.
- **Developer Tool**: Includes an `SmsAnalyzerScreen` to inspect and export SMS patterns for debugging new bank formats.

### B. Financial Management
- **Accounts**: Manage multiple wallets or bank accounts with initial balances.
- **Categories**: Organize transactions into categories (e.g., Food, Transport) with optional monthly budgets.
- **Transactions**: Supports Manual entry, SMS parsing, and Transfers between accounts.

### C. Analytics & Reporting
- Visualizes spending habits using charts (`AnalyticsScreen`).
- Displays "Net Balance", "Income", and "Expense" overviews.

### D. Security & UX
- **App Lock**: Biometric or PIN protection.
- **Multilingual**: Supports **English, Sinhala (සිංහල), and Tamil (தமிழ்)**.
- **Onboarding**: A dedicated flow for language selection, permissions, and initial setup.

## 5. Data Model (Drift Database)
The database is currently at **Version 3**.
- **Categories**: `id`, `name`, `icon`, `isIncome`, `monthlyBudget`.
- **Accounts**: `id`, `name`, `type` (cash/bank), `initialBalance`.
- **Transactions**: `id`, `amount`, `date`, `note`, `categoryId`, `accountId`, `isTransfer`, `transferToAccountId`, etc.
- **CategoryRules**: Used for automatic categorization logic.

## 6. Key Files for Quick Start
- `lib/main.dart`: Initialization of Workmanager, Notifications, and Riverpod.
- `lib/data/datasources/app_database.dart`: Database schema and migration logic.
- `lib/services/parsers/`: Contains the logic for reading bank SMS.
- `lib/utils/app_translations.dart`: Centralized dictionary for all UI text.

## 7. Current Status & Developer Notes
- The app uses **Sinhala comments** in some parts of the code (e.g., `[නව වෙනස]` meaning "new change") to track updates.
- **Background Task**: A periodic task runs via `Workmanager` to send a monthly summary notification at the end of every month.
- **Missing/Empty Folders**: Some folders like `lib/core` or `lib/data/repositories` are currently empty or minimally used as logic is consolidated in DAOs and Providers.

---
**Report generated for:** Deshan Mahesh
**Purpose**: To maintain project continuity across AI chat sessions.
