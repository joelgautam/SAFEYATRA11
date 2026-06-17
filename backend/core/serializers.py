from rest_framework import serializers

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


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = "__all__"


class OtpCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = OtpCode
        fields = "__all__"


class GuardianContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = GuardianContact
        fields = "__all__"


class PredefinedRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PredefinedRoute
        fields = "__all__"


class TripSerializer(serializers.ModelSerializer):
    predefined_route_detail = PredefinedRouteSerializer(source="predefined_route", read_only=True)

    class Meta:
        model = Trip
        fields = "__all__"


class TripStatusSerializer(serializers.ModelSerializer):
    latest_ping = serializers.SerializerMethodField()

    class Meta:
        model = Trip
        fields = [
            "id",
            "status",
            "passive_mode_enabled",
            "safe_corridor_meters",
            "started_at",
            "completed_at",
            "latest_ping",
        ]

    def get_latest_ping(self, obj):
        ping = obj.location_pings.order_by("-recorded_at").first()
        if ping is None:
            return None
        return LocationPingSerializer(ping).data


class LocationPingSerializer(serializers.ModelSerializer):
    class Meta:
        model = LocationPing
        fields = "__all__"


class TripEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = TripEvent
        fields = "__all__"


class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = "__all__"


class AlertRecipientSerializer(serializers.ModelSerializer):
    class Meta:
        model = AlertRecipient
        fields = "__all__"


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = "__all__"


class SafetyTipSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetyTip
        fields = "__all__"


class FaqSerializer(serializers.ModelSerializer):
    class Meta:
        model = Faq
        fields = "__all__"


class AudioSafetySessionSerializer(serializers.ModelSerializer):
    recording_file_url = serializers.SerializerMethodField()

    class Meta:
        model = AudioSafetySession
        fields = "__all__"

    def get_recording_file_url(self, obj):
        if not obj.recording_file:
            return ""
        request = self.context.get("request")
        url = f"/api/audio-sessions/{obj.id}/recording/"
        return request.build_absolute_uri(url) if request else url
