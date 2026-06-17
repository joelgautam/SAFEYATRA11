import json
import logging
import urllib.parse
import urllib.request

from django.conf import settings

from .models import PredefinedRoute


logger = logging.getLogger(__name__)


def search_route_suggestions(query, *, limit=10):
    normalized = query.strip()
    if len(normalized) < 2:
        return []

    results = []
    results.extend(
        _search_supabase_table(
            settings.SUPABASE_ROUTES_TABLE,
            normalized,
            limit,
            search_columns=settings.SUPABASE_ROUTE_SEARCH_COLUMNS,
        )
    )
    remaining = max(0, limit - len(results))
    if remaining:
        results.extend(
            _search_supabase_table(
                settings.SUPABASE_POIS_TABLE,
                normalized,
                remaining,
                search_columns=settings.SUPABASE_POI_SEARCH_COLUMNS,
            )
        )

    if results:
        return _dedupe_results(results)[:limit]

    return _search_local_predefined_routes(normalized, limit)


def _search_supabase_table(table_name, query, limit, *, search_columns):
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_KEY or not table_name:
        return []

    escaped_query = _escape_supabase_filter_value(query)
    filters = ",".join(
        f"{column}.ilike.*{escaped_query}*" for column in search_columns
    )
    if not filters:
        return []
    params = urllib.parse.urlencode(
        {
            "select": "*",
            "or": f"({filters})",
            "limit": limit,
        }
    )
    url = f"{settings.SUPABASE_URL.rstrip('/')}/rest/v1/{table_name}?{params}"
    request = urllib.request.Request(url, method="GET")
    request.add_header("apikey", settings.SUPABASE_SERVICE_KEY)
    request.add_header("Authorization", f"Bearer {settings.SUPABASE_SERVICE_KEY}")
    request.add_header("Accept", "application/json")

    try:
        with urllib.request.urlopen(request, timeout=settings.SUPABASE_REQUEST_TIMEOUT) as response:
            rows = json.loads(response.read().decode("utf-8"))
    except Exception:
        logger.exception("Supabase route lookup failed for table %s.", table_name)
        return []

    return [_normalize_supabase_row(row, source=table_name) for row in rows]


def _normalize_supabase_row(row, *, source):
    waypoints = row.get("waypoints") or row.get("route") or row.get("path") or []
    first_point = waypoints[0] if isinstance(waypoints, list) and waypoints else {}
    latitude = row.get("latitude", row.get("lat", first_point.get("lat")))
    longitude = row.get("longitude", row.get("lng", first_point.get("lng")))
    return {
        "id": str(row.get("id", "")),
        "name": str(row.get("name", row.get("title", ""))),
        "description": str(row.get("description", row.get("address", "")) or ""),
        "address": str(row.get("address", row.get("description", "")) or ""),
        "latitude": latitude,
        "longitude": longitude,
        "waypoints": waypoints if isinstance(waypoints, list) else [],
        "source": source,
    }


def _search_local_predefined_routes(query, limit):
    try:
        routes = list(PredefinedRoute.objects.filter(name__icontains=query)[:limit])
    except Exception:
        logger.warning("Local predefined route fallback lookup failed.")
        return []

    results = []
    for route in routes:
        first_point = route.waypoints[0] if route.waypoints else {}
        results.append(
            {
                "id": str(route.id),
                "name": route.name,
                "description": route.description,
                "address": route.description,
                "latitude": first_point.get("lat"),
                "longitude": first_point.get("lng"),
                "waypoints": route.waypoints,
                "source": "predefined_routes",
            }
        )
    return results


def _dedupe_results(results):
    seen = set()
    deduped = []
    for result in results:
        key = (result.get("source"), result.get("id")) if result.get("id") else (
            result.get("name"),
            result.get("address"),
        )
        if key in seen:
            continue
        seen.add(key)
        deduped.append(result)
    return deduped


def _escape_supabase_filter_value(value):
    return value.replace("*", "").replace(",", " ").replace("(", "").replace(")", "")
