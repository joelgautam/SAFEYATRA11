import uuid

from django.db import models


class TimeStampedModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class UserProfile(TimeStampedModel):
    phone = models.CharField(max_length=32, unique=True)
    full_name = models.CharField(max_length=120, blank=True)
    email = models.EmailField(blank=True)
    age = models.PositiveSmallIntegerField(null=True, blank=True)
    blood_group = models.CharField(max_length=8, blank=True)
    avatar_url = models.URLField(blank=True)
    is_phone_verified = models.BooleanField(default=False)
    safety_score = models.PositiveSmallIntegerField(default=100)

    class Meta:
        db_table = "user_profiles"

    def __str__(self):
        return self.full_name or self.phone


class OtpCode(TimeStampedModel):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="otp_codes")
    phone = models.CharField(max_length=32)
    code = models.CharField(max_length=6)
    purpose = models.CharField(max_length=30, default="signup")
    expires_at = models.DateTimeField()
    verified_at = models.DateTimeField(null=True, blank=True)
    attempts = models.PositiveSmallIntegerField(default=0)

    class Meta:
        db_table = "otp_codes"
        ordering = ["-created_at"]


class GuardianContact(TimeStampedModel):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="guardians")
    name = models.CharField(max_length=120)
    phone = models.CharField(max_length=32)
    relation = models.CharField(max_length=60)
    priority = models.PositiveSmallIntegerField(default=1)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "guardian_contacts"
        ordering = ["priority", "created_at"]


class PredefinedRoute(TimeStampedModel):
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    # List of {"lat": 27.7, "lng": 85.3} points
    waypoints = models.JSONField(default=list)
    is_safe = models.BooleanField(default=True)

    class Meta:
        db_table = "predefined_routes"

    def __str__(self):
        return self.name


class Trip(TimeStampedModel):
    class Status(models.TextChoices):
        PLANNED = "planned", "Planned"
        ACTIVE = "active", "Active"
        SAFE = "safe", "Safe"
        DEVIATION = "deviation", "Deviation"
        SOS = "sos", "SOS"
        CANCELLED = "cancelled", "Cancelled"

    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="trips")
    start_label = models.CharField(max_length=180)
    destination_label = models.CharField(max_length=180)
    start_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    start_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    destination_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    destination_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PLANNED)
    passive_mode_enabled = models.BooleanField(default=False)
    safe_corridor_meters = models.PositiveIntegerField(default=150)
    planned_route = models.JSONField(default=dict, blank=True)
    predefined_route = models.ForeignKey(
        PredefinedRoute,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_constraint=False,
    )
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    distance_meters = models.PositiveIntegerField(null=True, blank=True)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)

    class Meta:
        db_table = "trips"
        ordering = ["-created_at"]


class LocationPing(TimeStampedModel):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="location_pings")
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="location_pings")
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    accuracy_meters = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    speed_mps = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    address_label = models.CharField(max_length=180, blank=True)
    recorded_at = models.DateTimeField()

    class Meta:
        db_table = "location_pings"
        ordering = ["-recorded_at"]


class TripEvent(TimeStampedModel):
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="events")
    event_type = models.CharField(max_length=40)
    title = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    occurred_at = models.DateTimeField()

    class Meta:
        db_table = "trip_events"
        ordering = ["occurred_at"]


class Alert(TimeStampedModel):
    class AlertType(models.TextChoices):
        DEVIATION = "deviation", "Deviation"
        SOS = "sos", "SOS"
        AUDIO_KEYWORD = "audio_keyword", "Audio Keyword"
        POLICE = "police", "Police"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        SENT = "sent", "Sent"
        CANCELLED = "cancelled", "Cancelled"
        RESOLVED = "resolved", "Resolved"

    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="alerts")
    trip = models.ForeignKey(Trip, on_delete=models.SET_NULL, null=True, blank=True, related_name="alerts")
    alert_type = models.CharField(max_length=30, choices=AlertType.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    message = models.TextField(blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    triggered_at = models.DateTimeField()
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "alerts"
        ordering = ["-triggered_at"]


class AlertRecipient(TimeStampedModel):
    alert = models.ForeignKey(Alert, on_delete=models.CASCADE, related_name="recipients")
    guardian = models.ForeignKey(GuardianContact, on_delete=models.SET_NULL, null=True, blank=True)
    recipient_name = models.CharField(max_length=120)
    recipient_phone = models.CharField(max_length=32)
    delivery_status = models.CharField(max_length=30, default="pending")
    delivered_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "alert_recipients"


class Notification(TimeStampedModel):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=120)
    body = models.TextField()
    notification_type = models.CharField(max_length=40, default="general")
    is_read = models.BooleanField(default=False)

    class Meta:
        db_table = "notifications"
        ordering = ["-created_at"]


class SafetyTip(TimeStampedModel):
    title = models.CharField(max_length=120)
    body = models.TextField()
    category = models.CharField(max_length=60, default="general")
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "safety_tips"


class Faq(TimeStampedModel):
    question = models.CharField(max_length=240)
    answer = models.TextField()
    category = models.CharField(max_length=60, default="general")
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = "faqs"
        ordering = ["display_order", "created_at"]


class AudioSafetySession(TimeStampedModel):
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name="audio_sessions")
    trip = models.ForeignKey(Trip, on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=30, default="recording")
    keyword_detected = models.CharField(max_length=80, blank=True)
    recording_file = models.FileField(upload_to="voice_recordings/", blank=True)
    recording_url = models.URLField(blank=True)
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "audio_safety_sessions"
        ordering = ["-started_at"]
