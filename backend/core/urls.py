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
    PredefinedRouteViewSet,
    RequestOtpView,
    SafetyTipViewSet,
    RouteSearchView,
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
router.register("predefined-routes", PredefinedRouteViewSet)

urlpatterns = [
    path("auth/request-otp/", RequestOtpView.as_view(), name="request-otp"),
    path("auth/verify-otp/", VerifyOtpView.as_view(), name="verify-otp"),
    path("route-search/", RouteSearchView.as_view(), name="route-search"),
    path("", include(router.urls)),
]
