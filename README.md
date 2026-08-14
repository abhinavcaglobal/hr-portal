# CA Global Leave Portal

Production-ready Flutter Web HR leave portal for CA Global employees.

## Features

- Outlook Sign-In via Microsoft redirect (`@caglobal.com` only)
- Employee dashboard with leave balance and attendance calendar
- Admin dashboard for Excel uploads (parsing placeholder)
- Firebase Auth, Firestore, and Storage
- Riverpod state management with clean architecture

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Update `lib/firebase_options.dart` with your project credentials.

### 3. Enable Outlook Sign-In (Microsoft)

Employees sign in with their **Outlook / Microsoft work account**. The app redirects to Microsoft's login page and returns after authentication.

1. Firebase Console → Authentication → Sign-in method → **Microsoft**
2. Register an app in [Azure Portal](https://portal.azure.com) → Microsoft Entra ID → App registrations
3. Add the Firebase redirect URI from the Firebase Microsoft provider setup
4. Copy the **Application (client) ID** and **Client secret** into Firebase
5. Set `microsoftTenantId` in `lib/core/constants/app_constants.dart` to your Azure tenant ID (recommended for CA Global only), or keep `organizations` for any work account
6. Add your web app domain under Firebase → Authentication → Settings → Authorized domains

### 4. Firestore collections

**employees**

```json
{
  "email": "employee@caglobal.com",
  "name": "Employee Name",
  "openingBalance": 5
}
```

**attendance**

```json
{
  "employeeEmail": "employee@caglobal.com",
  "date": "2025-07-01",
  "status": "P"
}
```

### 5. Run on web

```bash
flutter run -d chrome
```

## Admin Access

- Admin email: `hr-india@caglobal.com`
- All other `@caglobal.com` users are employees

## Leave Balance Formula

Opening balance is uploaded as the balance through end of May (e.g. May 2026).
Each completed month from June onward earns 1 leave; leave taken in a month is
applied against that month's entitlement first, and only the unused portion is
carried forward. Leave taken in the current month is deducted immediately.

```
Pending Balance =
  Opening Balance
  + Σ unused monthly entitlement (completed months since June)
  − excess leave beyond monthly entitlement (completed months)
  − leave taken in the current month
```

| Status | Deduction |
|--------|-----------|
| P      | 0         |
| L      | 1.0       |
| HL     | 0.5       |
| SL     | 0.25      |

## Project Structure

```
lib/
├── core/           # Theme, router, constants, shared widgets
├── features/       # Auth, dashboard, attendance, admin, leave
├── models/
├── repositories/
├── services/
├── providers/
└── main.dart
```
