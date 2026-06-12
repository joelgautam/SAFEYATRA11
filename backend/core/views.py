import random

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
    SafetyTipSerializer,
    TripEventSerializer,
    TripSerializer,
    TripStatusSerializer,
    UserProfileSerializer,
)


def normalize_phone(phone):
    """Remove spaces, dashes, and other formatting from phone numbers."""
    if not phone:
        return ""
    # Keep digits and leading plus sign
    return "".join(c for c in phone if c.isdigit() or (c == "+" and phone.index(c) == 0))


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

        code = f"{random.SystemRandom().randint(0, 999999):06d}"
        otp = OtpCode.objects.create(
            user=user,
            phone=phone,
            code=code,
            purpose="signup",
            expires_at=timezone.now() + timezone.timedelta(minutes=10),
        )

        return Response(
            {
                "detail": "OTP generated and stored in the database.",
                "otp_id": str(otp.id),
                "phone": phone,
                "expires_at": otp.expires_at,
                "dev_otp": code,
            },
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
        if otp.code != code:
            otp.save(update_fields=["attempts", "updated_at"])
            return Response(
                {"detail": "Invalid OTP."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        now = timezone.now()
        otp.verified_at = now
        otp.save(update_fields=["attempts", "verified_at", "updated_at"])

        user = otp.user
        user.is_phone_verified = True
        user.save(update_fields=["is_phone_verified", "updated_at"])

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

        return Response(
            {
                "detail": "Passive monitoring started.",
                "trip": TripStatusSerializer(trip).data,
                "guardians_notified": guardians.count(),
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

        deviation_detected = self._detect_simple_deviation(trip, ping)
        if deviation_detected and trip.status == Trip.Status.ACTIVE:
            trip.status = Trip.Status.DEVIATION
            trip.save(update_fields=["status", "updated_at"])
            TripEvent.objects.create(
                trip=trip,
                event_type="deviation",
                title="Route deviation detected",
                description="Latest location moved outside the simple safe corridor.",
                latitude=ping.latitude,
                longitude=ping.longitude,
                occurred_at=parsed_at,
            )

        return Response(
            {
                "detail": "Location ping stored.",
                "ping": LocationPingSerializer(ping).data,
                "trip": TripStatusSerializer(trip).data,
                "deviation_detected": deviation_detected,
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
        trip.save(
            update_fields=[
                "status",
                "completed_at",
                "passive_mode_enabled",
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
        return alert, len(recipients)

    def _detect_simple_deviation(self, trip, ping):
        if (
            trip.destination_lat is None
            or trip.destination_lng is None
            or trip.safe_corridor_meters <= 0
        ):
            return False

        try:
            lat_delta = abs(float(ping.latitude) - float(trip.destination_lat))
            lng_delta = abs(float(ping.longitude) - float(trip.destination_lng))
        except (TypeError, ValueError):
            return False

        approx_meters = max(lat_delta, lng_delta) * 111_000
        return approx_meters > trip.safe_corridor_meters * 8


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
