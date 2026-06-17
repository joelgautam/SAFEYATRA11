import base64
import json
import logging
import urllib.parse
import urllib.request

from django.conf import settings


logger = logging.getLogger(__name__)


def _twilio_auth_header(sid, token):
    auth = base64.b64encode(f"{sid}:{token}".encode("utf-8")).decode("ascii")
    return f"Basic {auth}"


def _twilio_verify_service_sid():
    return getattr(settings, "TWILIO_VERIFY_SERVICE_SID", "") or getattr(
        settings,
        "TWILIO_VERIFY_SERVICE_ID",
        "",
    )


def send_sms(*, to_phone, body):
    """
    Send an SMS using the configured provider.

    In local development, missing SMS credentials should not break emergency
    alert persistence. The returned status is stored on AlertRecipient.
    """
    provider = getattr(settings, "SMS_PROVIDER", "console").lower()
    if provider != "twilio":
        logger.info("SMS skipped for %s: %s", to_phone, body)
        return "queued"

    sid = getattr(settings, "TWILIO_ACCOUNT_SID", "")
    token = getattr(settings, "TWILIO_AUTH_TOKEN", "")
    from_phone = getattr(settings, "TWILIO_FROM_PHONE", "")
    if not sid or not token or not from_phone:
        logger.warning("Twilio SMS skipped because credentials are incomplete.")
        return "queued"

    payload = urllib.parse.urlencode(
        {
            "To": to_phone,
            "From": from_phone,
            "Body": body,
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        f"https://api.twilio.com/2010-04-01/Accounts/{sid}/Messages.json",
        data=payload,
        method="POST",
    )
    request.add_header("Authorization", _twilio_auth_header(sid, token))
    request.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if 200 <= response.status < 300:
                return "sent"
            logger.warning("Twilio returned HTTP %s for %s.", response.status, to_phone)
    except Exception:
        logger.exception("Twilio SMS failed for %s.", to_phone)

    return "failed"


def send_otp_verification(*, to_phone):
    """
    Start a Twilio Verify SMS challenge.
    Returns True when Twilio accepted the verification request.
    """
    provider = getattr(settings, "SMS_PROVIDER", "console").lower()
    if provider != "twilio":
        logger.info("Twilio Verify start skipped in development for %s.", to_phone)
        return True

    sid = getattr(settings, "TWILIO_ACCOUNT_SID", "")
    token = getattr(settings, "TWILIO_AUTH_TOKEN", "")
    service_sid = _twilio_verify_service_sid()
    if not sid or not token or not service_sid:
        logger.warning("Twilio Verify start skipped because credentials are incomplete.")
        return False

    payload = urllib.parse.urlencode(
        {
            "To": to_phone,
            "Channel": "sms",
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        f"https://verify.twilio.com/v2/Services/{service_sid}/Verifications",
        data=payload,
        method="POST",
    )
    request.add_header("Authorization", _twilio_auth_header(sid, token))
    request.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if 200 <= response.status < 300:
                return True
            logger.warning(
                "Twilio Verify start returned HTTP %s for %s.",
                response.status,
                to_phone,
            )
    except Exception:
        logger.exception("Twilio Verify start failed for %s.", to_phone)

    return False


def verify_otp(*, to_phone, otp_code):
    """
    Verify a one-time password (OTP) using Twilio Verify API.
    Returns True if approved, False otherwise.
    """
    provider = getattr(settings, "SMS_PROVIDER", "console").lower()
    if provider != "twilio":
        logger.info("SMS Verification bypassed in development for %s.", to_phone)
        return otp_code == "123456"

    sid = getattr(settings, "TWILIO_ACCOUNT_SID", "")
    token = getattr(settings, "TWILIO_AUTH_TOKEN", "")
    service_sid = _twilio_verify_service_sid()

    if not sid or not token or not service_sid:
        logger.warning("Twilio Verify skipped because credentials or Service SID are incomplete.")
        return False

    payload = urllib.parse.urlencode(
        {
            "To": to_phone,
            "Code": otp_code,
        }
    ).encode("utf-8")

    url = f"https://verify.twilio.com/v2/Services/{service_sid}/VerificationCheck"

    request = urllib.request.Request(
        url,
        data=payload,
        method="POST",
    )

    request.add_header("Authorization", _twilio_auth_header(sid, token))
    request.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if 200 <= response.status < 300:
                result = json.loads(response.read().decode("utf-8"))
                return result.get("status") == "approved"

            logger.warning("Twilio Verify returned HTTP %s for %s.", response.status, to_phone)
    except Exception:
        logger.exception("Twilio Verification failed for %s.", to_phone)

    return False
