import math

from django.conf import settings
from django.http import FileResponse, Http404
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    Alert,
    AlertRecipient,
    AudioSafetySession,
    Faq,
    GuardianContact,
    LocationPing,
    Notification,
    OtpCode,
    PredefinedRoute,
    SafetyTip,
    Trip,
    TripEvent,
    UserProfile,
)
from .serializers import (
    AlertRecipientSerializer,
    AlertSerializer,
    AudioSafetySessionSerializer,
    FaqSerializer,
    GuardianContactSerializer,
    LocationPingSerializer,
    NotificationSerializer,
    OtpCodeSerializer,
    PredefinedRouteSerializer,
    SafetyTipSerializer,
    TripEventSerializer,
    TripSerializer,
    TripStatusSerializer,
    UserProfileSerializer,
)
from .sms import send_otp_verification, send_sms, verify_otp
from .supabase_routes import search_route_suggestions


def normalize_phone(phone):
    """Remove spaces, dashes, and other formatting from phone numbers."""
    if not phone:
        return ""
    # Keep digits and leading plus sign
    return "".join(c for c in phone if c.isdigit() or (c == "+" and phone.index(c) == 0))


def notify_guardians_for_user(*, user, notification_type, message):
    guardians = GuardianContact.objects.filter(user=user, is_active=True)
    Notification.objects.create(
        user=user,
        title="Guardian notification sent",
        body=message,
        notification_type=notification_type,
    )

    notified = 0
    for guardian in guardians:
        delivery_status = send_sms(to_phone=guardian.phone, body=message)
        if delivery_status in {"queued", "sent"}:
            notified += 1
    return notified


class UserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    filterset_fields = ["phone"]

    def get_queryset(self):
        queryset = super().get_queryset()
        phone = self.request.query_params.get("phone")
        if phone:
            queryset = queryset.filter(phone=normalize_phone(phone))
        return queryset


class OtpCodeViewSet(viewsets.ModelViewSet):
    queryset = OtpCode.objects.all()
    serializer_class = OtpCodeSerializer


class RequestOtpView(APIView):
    def post(self, request):
        phone = normalize_phone(str(request.data.get("phone", "")).strip())
        full_name = str(request.data.get("full_name", "")).strip()
        email = str(request.data.get("email", "")).strip()

        if not phone or len(phone) < 7:
            return Response(
                {"detail": "A valid phone number is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user, _ = UserProfile.objects.get_or_create(phone=phone)
        updates = []
        if full_name and user.full_name != full_name:
            user.full_name = full_name
            updates.append("full_name")
        if email and user.email != email:
            user.email = email
            updates.append("email")
        if updates:
            user.save(update_fields=updates + ["updated_at"])

        use_twilio_verify = (
            getattr(settings, "SMS_PROVIDER", "console").lower() == "twilio"
        )

        if use_twilio_verify and not send_otp_verification(to_phone=phone):
            return Response(
                {"detail": "Could not send OTP SMS. Check Twilio configuration."},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        code = "000000" if use_twilio_verify else "123456"
        otp = OtpCode.objects.create(
            user=user,
            phone=phone,
            code=code,
            purpose="signup",
            expires_at=timezone.now() + timezone.timedelta(minutes=10),
        )

        response_data = {
            "detail": "OTP sent to your phone." if use_twilio_verify else "OTP generated and stored in the database.",
            "otp_id": str(otp.id),
            "phone": phone,
            "expires_at": otp.expires_at,
        }
        if not use_twilio_verify:
            response_data["dev_otp"] = code

        return Response(
            response_data,
            status=status.HTTP_201_CREATED,
        )


class VerifyOtpView(APIView):
    def post(self, request):
        phone = normalize_phone(str(request.data.get("phone", "")).strip())
        code = str(request.data.get("code", "")).strip()

        if not phone or len(code) != 6:
            return Response(
                {"detail": "Phone and 6-digit OTP are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp = (
            OtpCode.objects.select_related("user")
            .filter(
                phone=phone,
                purpose="signup",
                verified_at__isnull=True,
                expires_at__gte=timezone.now(),
            )
            .order_by("-created_at")
            .first()
        )

        if otp is None:
            return Response(
                {"detail": "OTP expired or not found. Please request a new OTP."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp.attempts += 1
        use_twilio_verify = getattr(settings, "SMS_PROVIDER", "console").lower() == "twilio"
        is_valid = (
            verify_otp(to_phone=phone, otp_code=code)
            if use_twilio_verify
            else otp.code == code
        )
        if not is_valid:
            otp.save(update_fields=["attempts", "updated_at"])
            return Response(
                {"detail": "Invalid or expired OTP." if use_twilio_verify else "Invalid OTP."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        now = timezone.now()
        otp.verified_at = now
        otp.save(update_fields=["attempts", "verified_at", "updated_at"])

        user = otp.user
        user.is_phone_verified = True
        user.save(update_fields=["is_phone_verified", "updated_at"])
        guardians_notified = notify_guardians_for_user(
            user=user,
            notification_type="secure_login",
            message=(
                f"SafeYatra notice: {user.full_name or user.phone} securely logged in "
                "after phone verification."
            ),
        )

        return Response(
            {
                "detail": "Phone verified successfully.",
                "user": {
                    "id": str(user.id),
                    "phone": user.phone,
                    "full_name": user.full_name,
                    "email": user.email,
                    "is_phone_verified": user.is_phone_verified,
                },
                "guardians_notified": guardians_notified,
            }
        )


class GuardianContactViewSet(viewsets.ModelViewSet):
    queryset = GuardianContact.objects.all()
    serializer_class = GuardianContactSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset


class TripViewSet(viewsets.ModelViewSet):
    queryset = Trip.objects.all()
    serializer_class = TripSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset

    @action(detail=False, methods=["post"], url_path="start-passive")
    def start_passive(self, request):
        user_id = request.data.get("user")
        if not user_id:
            return Response(
                {"detail": "User is required before starting passive mode."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = UserProfile.objects.get(id=user_id)
        except UserProfile.DoesNotExist:
            return Response(
                {"detail": "User not found. Please sign in again."},
                status=status.HTTP_404_NOT_FOUND,
            )

        now = timezone.now()
        predefined_route_id = request.data.get("predefined_route")
        predefined_route = None
        if predefined_route_id:
            try:
                predefined_route = PredefinedRoute.objects.get(id=predefined_route_id)
            except (PredefinedRoute.DoesNotExist, ValueError):
                pass

        trip = Trip.objects.create(
            user=user,
            start_label=str(request.data.get("start_label", "")).strip()
            or "Current location",
            destination_label=str(
                request.data.get("destination_label", "")
            ).strip()
            or "Destination",
            start_lat=request.data.get("start_lat") or None,
            start_lng=request.data.get("start_lng") or None,
            destination_lat=request.data.get("destination_lat") or None,
            destination_lng=request.data.get("destination_lng") or None,
            planned_route=request.data.get("planned_route") or {},
            predefined_route=predefined_route,
            passive_mode_enabled=True,
            status=Trip.Status.ACTIVE,
            started_at=now,
        )

        guardians = GuardianContact.objects.filter(user=user, is_active=True)
        notifications = [
            Notification(
                user=user,
                title="Passive monitoring started",
                body=f"Trip from {trip.start_label} to {trip.destination_label} is active.",
                notification_type="passive_mode",
            )
        ]
        Notification.objects.bulk_create(notifications)
        guardians_notified = notify_guardians_for_user(
            user=user,
            notification_type="trip_started",
            message=(
                f"SafeYatra notice: {user.full_name or user.phone} started a trip "
                f"from {trip.start_label} to {trip.destination_label}."
            ),
        )

        return Response(
            {
                "detail": "Passive monitoring started.",
                "trip": TripStatusSerializer(trip).data,
                "guardians_notified": guardians_notified or guardians.count(),
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], url_path="ping")
    def ping(self, request, pk=None):
        trip = self.get_object()
        if trip.status not in [Trip.Status.ACTIVE, Trip.Status.DEVIATION]:
            return Response(
                {
                    "detail": "Location pings are only accepted for active trips.",
                    "trip": TripStatusSerializer(trip).data,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        latitude = request.data.get("latitude")
        longitude = request.data.get("longitude")
        if latitude is None or longitude is None:
            return Response(
                {"detail": "Latitude and longitude are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        recorded_at = request.data.get("recorded_at")
        if recorded_at:
            parsed_at = timezone.datetime.fromisoformat(
                str(recorded_at).replace("Z", "+00:00")
            )
            if timezone.is_naive(parsed_at):
                parsed_at = timezone.make_aware(parsed_at)
        else:
            parsed_at = timezone.now()

        ping = LocationPing.objects.create(
            trip=trip,
            user=trip.user,
            latitude=latitude,
            longitude=longitude,
            accuracy_meters=request.data.get("accuracy_meters") or None,
            speed_mps=request.data.get("speed_mps") or None,
            address_label=str(request.data.get("address_label", "")).strip(),
            recorded_at=parsed_at,
        )

        deviation_detected, distance_from_route = self._detect_route_deviation(
            trip, ping
        )
        alert = None
        recipients_count = 0
        if deviation_detected and trip.status == Trip.Status.ACTIVE:
            trip.status = Trip.Status.DEVIATION
            trip.save(update_fields=["status", "updated_at"])
            TripEvent.objects.create(
                trip=trip,
                event_type="deviation",
                title="Route deviation detected",
                description=(
                    "Latest location moved "
                    f"{int(distance_from_route or 0)}m from the planned route."
                ),
                latitude=ping.latitude,
                longitude=ping.longitude,
                occurred_at=parsed_at,
            )
            alert, recipients_count = self._create_deviation_alert_if_needed(
                trip=trip,
                latitude=ping.latitude,
                longitude=ping.longitude,
                distance_from_route=distance_from_route,
            )

        return Response(
            {
                "detail": "Location ping stored.",
                "ping": LocationPingSerializer(ping).data,
                "trip": TripStatusSerializer(trip).data,
                "deviation_detected": deviation_detected,
                "distance_from_route_meters": distance_from_route,
                "alert": AlertSerializer(alert).data if alert else None,
                "recipients_notified": recipients_count,
            }
        )

    @action(detail=True, methods=["post"], url_path="sos")
    def sos(self, request, pk=None):
        trip = self.get_object()
        alert, recipients_count = self._create_alert_for_guardians(
            trip=trip,
            alert_type=Alert.AlertType.SOS,
            message="SOS alert triggered. User requested emergency help.",
            latitude=request.data.get("latitude"),
            longitude=request.data.get("longitude"),
        )
        trip.status = Trip.Status.SOS
        trip.save(update_fields=["status", "updated_at"])

        return Response(
            {
                "detail": "SOS alert sent to emergency contacts.",
                "alert": AlertSerializer(alert).data,
                "trip": TripStatusSerializer(trip).data,
                "recipients_notified": recipients_count,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], url_path="mark-safe")
    def mark_safe(self, request, pk=None):
        trip = self.get_object()
        trip.status = Trip.Status.SAFE
        trip.completed_at = timezone.now()
        trip.passive_mode_enabled = False
        if trip.started_at:
            trip.duration_seconds = max(
                0, int((trip.completed_at - trip.started_at).total_seconds())
            )
        trip.save(
            update_fields=[
                "status",
                "completed_at",
                "passive_mode_enabled",
                "duration_seconds",
                "updated_at",
            ]
        )
        TripEvent.objects.create(
            trip=trip,
            event_type="safe",
            title="User marked safe",
            description="Passive monitoring was ended by the user.",
            occurred_at=trip.completed_at,
        )

        return Response(
            {
                "detail": "Trip marked safe.",
                "trip": TripStatusSerializer(trip).data,
            }
        )

    @action(detail=True, methods=["post"], url_path="deviation-alert")
    def deviation_alert(self, request, pk=None):
        trip = self.get_object()
        alert, recipients_count = self._create_alert_for_guardians(
            trip=trip,
            alert_type=Alert.AlertType.DEVIATION,
            message="Route deviation alert. User did not confirm safety in time.",
            latitude=request.data.get("latitude"),
            longitude=request.data.get("longitude"),
        )
        trip.status = Trip.Status.DEVIATION
        trip.save(update_fields=["status", "updated_at"])

        return Response(
            {
                "detail": "Deviation alert sent to emergency contacts.",
                "alert": AlertSerializer(alert).data,
                "trip": TripStatusSerializer(trip).data,
                "recipients_notified": recipients_count,
            },
            status=status.HTTP_201_CREATED,
        )

    def _create_deviation_alert_if_needed(
        self,
        *,
        trip,
        latitude,
        longitude,
        distance_from_route=None,
    ):
        existing = Alert.objects.filter(
            trip=trip,
            alert_type=Alert.AlertType.DEVIATION,
            status__in=[Alert.Status.PENDING, Alert.Status.SENT],
        ).first()
        if existing:
            return existing, existing.recipients.count()

        distance_text = ""
        if distance_from_route is not None:
            distance_text = f" Current location is about {int(distance_from_route)}m off route."
        return self._create_alert_for_guardians(
            trip=trip,
            alert_type=Alert.AlertType.DEVIATION,
            message=(
                "Route deviation detected by SafeYatra."
                f"{distance_text} Emergency contacts were notified."
            ),
            latitude=latitude,
            longitude=longitude,
        )

    def _create_alert_for_guardians(
        self,
        *,
        trip,
        alert_type,
        message,
        latitude=None,
        longitude=None,
    ):
        now = timezone.now()
        location_link = self._location_link(latitude, longitude)
        alert = Alert.objects.create(
            user=trip.user,
            trip=trip,
            alert_type=alert_type,
            status=Alert.Status.SENT,
            message=message,
            latitude=latitude or None,
            longitude=longitude or None,
            triggered_at=now,
        )
        guardians = GuardianContact.objects.filter(user=trip.user, is_active=True)
        recipients = []
        sms_body = self._sms_body(
            trip=trip,
            alert_type=alert_type,
            message=message,
            location_link=location_link,
        )
        for guardian in guardians:
            delivery_status = send_sms(to_phone=guardian.phone, body=sms_body)
            recipients.append(
                AlertRecipient(
                    alert=alert,
                    guardian=guardian,
                    recipient_name=guardian.name,
                    recipient_phone=guardian.phone,
                    delivery_status=delivery_status,
                    delivered_at=now if delivery_status == "sent" else None,
                )
            )
        AlertRecipient.objects.bulk_create(recipients)
        return alert, len(recipients)

    def _detect_route_deviation(self, trip, ping):
        if trip.safe_corridor_meters <= 0:
            return False, None

        try:
            ping_lat = float(ping.latitude)
            ping_lng = float(ping.longitude)
        except (TypeError, ValueError):
            return False, None

        route_points = self._route_points_for_trip(trip)
        if not route_points:
            return False, None

        distance_from_route = self._distance_from_route_meters(
            route_points,
            ping_lat,
            ping_lng,
        )
        tolerance = float(trip.safe_corridor_meters)
        if ping.accuracy_meters:
            try:
                tolerance += min(float(ping.accuracy_meters), 50)
            except (TypeError, ValueError):
                pass
        return distance_from_route > tolerance, distance_from_route

    def _route_points_for_trip(self, trip):
        route_points = []
        predefined_route = getattr(trip, "predefined_route", None)
        if predefined_route and predefined_route.waypoints:
            route_points = self._parse_route_points(predefined_route.waypoints)

        if not route_points:
            planned_route = trip.planned_route or {}
            route_points = self._parse_route_points(planned_route.get("points", []))

        if not route_points:
            route_points = self._start_destination_points(trip)

        return route_points

    def _parse_route_points(self, raw_points):
        points = []
        for point in raw_points or []:
            if not isinstance(point, dict):
                continue
            lat = point.get("lat", point.get("latitude"))
            lng = point.get("lng", point.get("longitude"))
            try:
                points.append((float(lat), float(lng)))
            except (TypeError, ValueError):
                continue
        return points

    def _start_destination_points(self, trip):
        raw_points = [
            {"latitude": trip.start_lat, "longitude": trip.start_lng},
            {"latitude": trip.destination_lat, "longitude": trip.destination_lng},
        ]
        return self._parse_route_points(raw_points)

    def _distance_from_route_meters(self, route_points, point_lat, point_lng):
        if len(route_points) == 1:
            return self._distance_between_meters(
                route_points[0][0],
                route_points[0][1],
                point_lat,
                point_lng,
            )

        min_dist = float("inf")
        for index in range(len(route_points) - 1):
            start_lat, start_lng = route_points[index]
            end_lat, end_lng = route_points[index + 1]
            dist = self._distance_from_line_meters(
                start_lat,
                start_lng,
                end_lat,
                end_lng,
                point_lat,
                point_lng,
            )
            min_dist = min(min_dist, dist)
        return min_dist

    def _distance_between_meters(self, start_lat, start_lng, end_lat, end_lng):
        radius_meters = 6_371_000
        d_lat = math.radians(end_lat - start_lat)
        d_lng = math.radians(end_lng - start_lng)
        lat1 = math.radians(start_lat)
        lat2 = math.radians(end_lat)
        a = (
            math.sin(d_lat / 2) ** 2
            + math.cos(lat1) * math.cos(lat2) * math.sin(d_lng / 2) ** 2
        )
        return radius_meters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    def _sms_body(self, *, trip, alert_type, message, location_link):
        alert_label = "SOS" if alert_type == Alert.AlertType.SOS else "Route deviation"
        user_name = trip.user.full_name or trip.user.phone
        location_text = f" Location: {location_link}" if location_link else ""
        return (
            f"SafeYatra {alert_label} alert for {user_name}. "
            f"Trip: {trip.start_label} to {trip.destination_label}. "
            f"{message}{location_text}"
        )

    def _location_link(self, latitude, longitude):
        if latitude is None or longitude is None:
            return ""
        template = getattr(settings, "EMERGENCY_ALERT_BASE_URL", "")
        if not template:
            return ""
        return template.format(lat=latitude, lng=longitude)

    def _distance_from_line_meters(
        self,
        start_lat,
        start_lng,
        end_lat,
        end_lng,
        point_lat,
        point_lng,
    ):
        mean_lat = math.radians((start_lat + end_lat + point_lat) / 3)

        def to_xy(lat, lng):
            return (
                math.radians(lng) * 6_371_000 * math.cos(mean_lat),
                math.radians(lat) * 6_371_000,
            )

        sx, sy = to_xy(start_lat, start_lng)
        ex, ey = to_xy(end_lat, end_lng)
        px, py = to_xy(point_lat, point_lng)
        dx = ex - sx
        dy = ey - sy
        if dx == 0 and dy == 0:
            return math.hypot(px - sx, py - sy)

        t = max(
            0,
            min(1, ((px - sx) * dx + (py - sy) * dy) / (dx * dx + dy * dy)),
        )
        closest_x = sx + t * dx
        closest_y = sy + t * dy
        return math.hypot(px - closest_x, py - closest_y)


class LocationPingViewSet(viewsets.ModelViewSet):
    queryset = LocationPing.objects.all()
    serializer_class = LocationPingSerializer


class TripEventViewSet(viewsets.ModelViewSet):
    queryset = TripEvent.objects.all()
    serializer_class = TripEventSerializer


class AlertViewSet(viewsets.ModelViewSet):
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset


class AlertRecipientViewSet(viewsets.ModelViewSet):
    queryset = AlertRecipient.objects.all()
    serializer_class = AlertRecipientSerializer


class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer


class SafetyTipViewSet(viewsets.ModelViewSet):
    queryset = SafetyTip.objects.all()
    serializer_class = SafetyTipSerializer


class RouteSearchView(APIView):
    def get(self, request):
        query = str(request.query_params.get("q", "")).strip()
        try:
            limit = min(max(int(request.query_params.get("limit", 10)), 1), 25)
        except (TypeError, ValueError):
            limit = 10

        if len(query) < 2:
            return Response({"results": []})

        return Response(
            {
                "query": query,
                "results": search_route_suggestions(query, limit=limit),
            }
        )


class PredefinedRouteViewSet(viewsets.ModelViewSet):
    queryset = PredefinedRoute.objects.all()
    serializer_class = PredefinedRouteSerializer

    @action(detail=False, methods=["get"], url_path="search")
    def search(self, request):
        return RouteSearchView().get(request)


class FaqViewSet(viewsets.ModelViewSet):
    queryset = Faq.objects.all()
    serializer_class = FaqSerializer


class AudioSafetySessionViewSet(viewsets.ModelViewSet):
    queryset = AudioSafetySession.objects.all()
    serializer_class = AudioSafetySessionSerializer
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_queryset(self):
        queryset = super().get_queryset()
        user_id = self.request.query_params.get("user")
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset

    @action(detail=False, methods=["post"], url_path="start-alert")
    def start_alert(self, request):
        user_id = request.data.get("user")
        if not user_id:
            return Response(
                {"detail": "User is required before recording."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = UserProfile.objects.get(id=user_id)
        except UserProfile.DoesNotExist:
            return Response(
                {"detail": "User not found. Please sign in again."},
                status=status.HTTP_404_NOT_FOUND,
            )

        now = timezone.now()
        keyword = str(request.data.get("keyword_detected", "Voice alert")).strip()
        session = AudioSafetySession.objects.create(
            user=user,
            status="recording",
            keyword_detected=keyword,
            started_at=now,
        )
        alert = Alert.objects.create(
            user=user,
            alert_type=Alert.AlertType.AUDIO_KEYWORD,
            status=Alert.Status.SENT,
            message="Voice safety alert started. Emergency contacts were notified.",
            triggered_at=now,
        )

        guardians = GuardianContact.objects.filter(user=user, is_active=True)
        recipients = [
            AlertRecipient(
                alert=alert,
                guardian=guardian,
                recipient_name=guardian.name,
                recipient_phone=guardian.phone,
                delivery_status="queued",
                delivered_at=now,
            )
            for guardian in guardians
        ]
        AlertRecipient.objects.bulk_create(recipients)

        return Response(
            {
                "detail": "Recording started and emergency contacts were queued.",
                "session": AudioSafetySessionSerializer(
                    session, context={"request": request}
                ).data,
                "alert": AlertSerializer(alert).data,
                "recipients_notified": len(recipients),
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"], url_path="upload-recording")
    def upload_recording(self, request, pk=None):
        session = self.get_object()
        recording = request.FILES.get("recording")
        if recording is None:
            return Response(
                {"detail": "A voice recording file is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        session.recording_file = recording
        session.recording_url = ""
        session.status = "completed"
        session.ended_at = timezone.now()
        session.save(
            update_fields=[
                "recording_file",
                "recording_url",
                "status",
                "ended_at",
                "updated_at",
            ]
        )

        return Response(
            {
                "detail": "Voice recording saved.",
                "session": AudioSafetySessionSerializer(
                    session, context={"request": request}
                ).data,
            }
        )

    @action(detail=True, methods=["get"], url_path="recording")
    def recording(self, request, pk=None):
        session = self.get_object()
        if not session.recording_file:
            raise Http404("Voice recording was not found.")

        try:
            return FileResponse(
                session.recording_file.open("rb"),
                as_attachment=False,
                filename=session.recording_file.name.rsplit("/", 1)[-1],
            )
        except FileNotFoundError as exc:
            raise Http404("Voice recording file is missing.") from exc
