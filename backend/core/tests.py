from unittest.mock import patch

from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    Alert,
    AlertRecipient,
    GuardianContact,
    LocationPing,
    PredefinedRoute,
    Trip,
    UserProfile,
)
from .views import TripViewSet


@override_settings(DATABASE_ROUTERS=[])
class RouteDeviationAlertTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = UserProfile.objects.create(
            phone="+9779800000000",
            full_name="Test Rider",
            is_phone_verified=True,
        )
        self.guardian = GuardianContact.objects.create(
            user=self.user,
            name="Guardian",
            phone="+9779800000001",
            relation="Friend",
            priority=1,
        )

    def _trip(self, **overrides):
        defaults = {
            "user": self.user,
            "start_label": "Start",
            "destination_label": "Destination",
            "start_lat": 27.700000,
            "start_lng": 85.300000,
            "destination_lat": 27.700000,
            "destination_lng": 85.310000,
            "status": Trip.Status.ACTIVE,
            "passive_mode_enabled": True,
            "safe_corridor_meters": 120,
            "started_at": timezone.now(),
        }
        defaults.update(overrides)
        return Trip.objects.create(**defaults)

    def _ping(self, trip, latitude, longitude):
        return self.client.post(
            reverse("trip-ping", args=[trip.id]),
            {
                "latitude": latitude,
                "longitude": longitude,
                "accuracy_meters": 5,
                "recorded_at": timezone.now().isoformat(),
            },
            format="json",
        )

    @patch("core.views.send_sms", return_value="sent")
    def test_on_route_ping_does_not_trigger_emergency_alert(self, send_sms_mock):
        trip = self._trip()

        response = self._ping(trip, 27.700010, 85.305000)

        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["deviation_detected"])
        trip.refresh_from_db()
        self.assertEqual(trip.status, Trip.Status.ACTIVE)
        self.assertEqual(Alert.objects.count(), 0)
        send_sms_mock.assert_not_called()

    @patch("core.views.send_sms", return_value="sent")
    def test_off_route_ping_triggers_single_deviation_alert_sms(self, send_sms_mock):
        trip = self._trip()

        response = self._ping(trip, 27.710000, 85.305000)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["deviation_detected"])
        self.assertEqual(response.data["recipients_notified"], 1)
        trip.refresh_from_db()
        self.assertEqual(trip.status, Trip.Status.DEVIATION)

        alert = Alert.objects.get()
        self.assertEqual(alert.alert_type, Alert.AlertType.DEVIATION)
        self.assertEqual(str(alert.trip_id), str(trip.id))
        recipient = AlertRecipient.objects.get(alert=alert)
        self.assertEqual(recipient.recipient_phone, self.guardian.phone)
        self.assertEqual(recipient.delivery_status, "sent")
        send_sms_mock.assert_called_once()

        second_response = self._ping(trip, 27.711000, 85.306000)
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(Alert.objects.count(), 1)
        send_sms_mock.assert_called_once()

    def test_predefined_route_waypoints_are_used_for_deviation_check(self):
        route = PredefinedRoute(
            name="Safe corridor",
            waypoints=[
                {"lat": 27.700000, "lng": 85.300000},
                {"lat": 27.705000, "lng": 85.305000},
                {"lat": 27.710000, "lng": 85.310000},
            ],
        )
        trip = self._trip(
            start_lat=None,
            start_lng=None,
            destination_lat=None,
            destination_lng=None,
        )
        trip.predefined_route = route
        viewset = TripViewSet()

        on_route_ping = LocationPing(
            trip=trip,
            user=self.user,
            latitude=27.705030,
            longitude=85.305030,
            accuracy_meters=5,
            recorded_at=timezone.now(),
        )
        off_route_ping = LocationPing(
            trip=trip,
            user=self.user,
            latitude=27.715000,
            longitude=85.305000,
            accuracy_meters=5,
            recorded_at=timezone.now(),
        )

        on_route, _ = viewset._detect_route_deviation(trip, on_route_ping)
        off_route, _ = viewset._detect_route_deviation(trip, off_route_ping)

        self.assertFalse(on_route)
        self.assertTrue(off_route)
