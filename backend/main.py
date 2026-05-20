import os

import psycopg2
from dotenv import load_dotenv


load_dotenv()

database_url = os.getenv("DATABASE_URL")

if not database_url:
    raise RuntimeError("DATABASE_URL is not set. Copy .env.example to .env and add your Supabase password.")

connection = psycopg2.connect(database_url)

try:
    with connection.cursor() as cursor:
        cursor.execute("select current_database(), current_user;")
        database_name, database_user = cursor.fetchone()
        print(f"Connected to database '{database_name}' as '{database_user}'.")
finally:
    connection.close()
