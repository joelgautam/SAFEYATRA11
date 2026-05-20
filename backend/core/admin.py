from django.contrib import admin

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


admin.site.register(UserProfile)
admin.site.register(GuardianContact)
admin.site.register(Trip)
admin.site.register(LocationPing)
admin.site.register(TripEvent)
admin.site.register(Alert)
admin.site.register(AlertRecipient)
admin.site.register(Notification)
admin.site.register(OtpCode)
admin.site.register(SafetyTip)
admin.site.register(Faq)
admin.site.register(AudioSafetySession)
