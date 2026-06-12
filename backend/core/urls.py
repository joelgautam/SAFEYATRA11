from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AlertRecipientViewSet,
    AlertViewSet,
    AudioSafetySessionViewSet,
    FaqViewSet,
    GuardianContactViewSet,
    LocationPingViewSet,
    NotificationViewSet,
    OtpCodeViewSet,
    RequestOtpView,
    SafetyTipViewSet,
    TripEventViewSet,
    TripViewSet,
    UserProfileViewSet,
    VerifyOtpView,
)


router = DefaultRouter()
router.register("users", UserProfileViewSet)
router.register("guardian-contacts", GuardianContactViewSet)
router.register("trips", TripViewSet)
router.register("location-pings", LocationPingViewSet)
router.register("trip-events", TripEventViewSet)
router.register("alerts", AlertViewSet)
router.register("alert-recipients", AlertRecipientViewSet)
router.register("notifications", NotificationViewSet)
router.register("otp-codes", OtpCodeViewSet)
router.register("safety-tips", SafetyTipViewSet)
router.register("faqs", FaqViewSet)
router.register("audio-sessions", AudioSafetySessionViewSet)

urlpatterns = [
    path("auth/request-otp/", RequestOtpView.as_view(), name="request-otp"),
    path("auth/verify-otp/", VerifyOtpView.as_view(), name="verify-otp"),
    path("", include(router.urls)),
]
