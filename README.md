
# SafeYatra

A women's safety app for commuters in Kathmandu, built with Flutter and a Django REST backend. SafeYatra monitors a user's trip in real time and automatically escalates to emergency guardians — and to a rule-based police/audio-keyword pathway — if the user deviates from a safe route without confirming they're okay.

## Problem

Most safety apps rely on the user manually pressing an SOS button — but in an actual dangerous situation, that's often not possible. SafeYatra flips this: instead of waiting for the user to ask for help, it watches for a danger signal (leaving a defined **safe corridor** around a planned route) and acts automatically, without requiring the user to do anything.

## How it works

1. The user starts a **trip**, either along a predefined safe route or a custom one, with a configurable **safe corridor radius** (defaults to 150m).
2. The app streams live **location pings** while the trip is active.
3. If the user's location drifts outside the safe corridor, the trip status changes to `deviation` and the app attempts to verify the user is okay.
4. If unconfirmed, an **Alert** is created (deviation, SOS, audio keyword, or police type) and sent to the user's **guardian contacts**, in priority order, with per-recipient delivery-status tracking (pending → sent → resolved).
5. A **voice recording** can also be captured and attached to an alert as supporting evidence.

## Tech Stack

**Frontend**
- Flutter (Android, iOS, Web, Windows, macOS, Linux)
- `http` for API calls, `shared_preferences` for local session state

**Backend**
- Django 5 + Django REST Framework
- PostgreSQL via Supabase (`DATABASE_URL`), plus a separate predefined-routes database
- Twilio (OTP verification + SMS/call alerts to guardians)
- `django-cors-headers`, `django-environ` for config management

## Core Data Model

- `UserProfile` — phone-verified user with a `safety_score`
- `Trip` — status flow: `planned → active → safe / deviation / sos / cancelled`, with a `safe_corridor_meters` field
- `LocationPing` — timestamped lat/lng/speed/accuracy stream per trip
- `GuardianContact` — priority-ordered emergency contacts per user
- `Alert` — typed (`deviation`, `sos`, `audio_keyword`, `police`) with its own delivery lifecycle
- `AlertRecipient` — per-guardian delivery status for each alert
- `PredefinedRoute`, `TripEvent`, `Notification`, `SafetyTip` — supporting models

## Project Structure

```
SAFEYATRA11/
├── lib/
│   ├── screens/      # OTP login, home, trip setup/detail, guardian contacts,
│   │                 # deviation alert, alert sent, passive mode, FAQ, profile
│   ├── services/      # live_location, trip_monitoring_api, voice_recording,
│   │                 # app_session, external_url (web/native/stub variants)
│   └── widgets/       # maptiler_live_map
├── backend/
│   ├── safeyatra_backend/   # Django project settings, urls, wsgi/asgi
│   └── core/                # models, views, serializers, sms (Twilio), routers
├── assets/            # kathmandu_map.png, icons
└── android/ ios/ web/ windows/ macos/ linux/   # platform build targets
```

## Getting Started

**Frontend**
```bash
flutter pub get
flutter run
```

**Backend**
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in your own Supabase + Twilio credentials
python manage.py migrate
python manage.py runserver
```

## Current Status

Core flow is implemented end-to-end: OTP login, trip creation with safe-corridor monitoring, live location pings, deviation detection, guardian alerting with per-recipient delivery tracking, and voice-recording capture during alerts.

## Known Limitations

- Bystander/nearby-people notification is part of the design but needs verification against the current backend implementation — confirm whether it's fully wired up or still in progress.
- The deviation-verification step (giving the user a chance to confirm they're safe before escalating) should be double-checked for how much time it actually gives the user.
- Built as a personal/course project — not yet load-tested or hardened for production traffic.

## Why This Project

Most safety apps put the burden on the person in danger to ask for help. SafeYatra explores automatic, corridor-based detection instead, with the goal of removing that burden entirely — the app notices the deviation and acts, rather than waiting to be told.





This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

