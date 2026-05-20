import random

from django.utils import timezone
from rest_framework import status, viewsets
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
    UserProfileSerializer,
)


class UserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all()
    serializer_class = UserProfileSerializer
    filterset_fields = ["phone"]


class OtpCodeViewSet(viewsets.ModelViewSet):
    queryset = OtpCode.objects.all()
    serializer_class = OtpCodeSerializer


class RequestOtpView(APIView):
    def post(self, request):
        phone = str(request.data.get("phone", "")).strip()
        full_name = str(request.data.get("full_name", "")).strip()
        email = str(request.data.get("email", "")).strip()

        if not phone or len(phone) < 8:
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
        phone = str(request.data.get("phone", "")).strip()
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


class LocationPingViewSet(viewsets.ModelViewSet):
    queryset = LocationPing.objects.all()
    serializer_class = LocationPingSerializer


class TripEventViewSet(viewsets.ModelViewSet):
    queryset = TripEvent.objects.all()
    serializer_class = TripEventSerializer


class AlertViewSet(viewsets.ModelViewSet):
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer


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
