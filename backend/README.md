# SafeYatra Django Backend

Backend API scaffold for the SafeYatra Flutter app. It stores users, guardian contacts, trips, live location pings, route events, alerts, notifications, safety tips, FAQs, and audio safety sessions in Supabase Postgres.

## Setup

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python manage.py runserver
```

Set `DATABASE_URL` in `.env` to your Supabase Postgres connection string.

## Supabase Tables

Run [db/supabase_schema.sql](db/supabase_schema.sql) in the Supabase SQL editor.

## API

- `GET/POST /api/users/`
- `GET/POST /api/guardian-contacts/`
- `GET/POST /api/trips/`
- `GET/POST /api/location-pings/`
- `GET/POST /api/trip-events/`
- `GET/POST /api/alerts/`
- `GET/POST /api/alert-recipients/`
- `GET/POST /api/notifications/`
- `GET/POST /api/safety-tips/`
- `GET/POST /api/faqs/`
- `GET/POST /api/audio-sessions/`
