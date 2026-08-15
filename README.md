<p align="center">
  <img src="assets/images/logo.png" alt="UniCart logo" width="96" />
</p>

<h1 align="center">UniCart</h1>

<p align="center">
  A campus group-buying platform for Pan-Atlantic University students.
</p>

<p align="center">
  <a href="https://unicartbytekena.onrender.com">Live PAU Beta</a> ·
  <a href="https://github.com/epic-ice-fire/unicart-backend">Backend API</a>
</p>

<p align="center">
  <img src="https://github.com/epic-ice-fire/unicart_app/actions/workflows/frontend-ci.yml/badge.svg" alt="Frontend CI" />
</p>

## Overview

UniCart helps verified PAU students combine purchases into shared batches, pay securely, submit item links, and follow each batch from funding to processing.

The project is designed as a responsive Flutter application with a production FastAPI backend, PostgreSQL persistence, Flutterwave payments, and PAU email verification.

## Highlights

- PAU-only access through `@pau.edu.ng` email verification
- Secure account and revocable session handling
- Flutterwave entry-fee and item payment flows
- Shared lobby progress with batch targets
- Item submission, payment locking, and batch history
- Admin workflow for reviewing items and progressing batches
- Responsive web and mobile-first UI
- Automated Flutter analysis, tests, and release web builds

## Tech stack

| Layer | Technology |
| --- | --- |
| Client | Flutter / Dart |
| API | FastAPI / Python |
| Database | PostgreSQL |
| Payments | Flutterwave |
| Email | Gmail API |
| Hosting | Render |
| CI | GitHub Actions |

## Project structure

```text
lib/
├── config/      API configuration
├── models/      Domain models
├── screens/     Auth, lobby and admin UI
├── services/    API, auth, session and lobby clients
├── theme/       UniCart design system
└── widgets/     Shared UI components
```

## Local development

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

The client uses the local API in development and the production API for release builds.

## Security

Secrets are not stored in the frontend repository. Authentication tokens are revocable server-side, passwords are never persisted by UniCart, and production payment verification is performed by the backend rather than trusted from the client.

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## Status

UniCart is in a controlled PAU beta while the first real student usage and batch activity are measured before wider rollout.
