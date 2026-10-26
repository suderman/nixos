"""Publish only subscription quota fields, never management responses or tokens."""

import json
import math
import os
import sys
import time
from datetime import datetime
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class QuotaError(Exception):
    def __init__(self, message, retry_at: float = 0):
        super().__init__(message)
        self.retry_at = retry_at


def number(value):
    if isinstance(value, bool):
        return None
    try:
        value = float(value)
        return value if math.isfinite(value) else None
    except (ValueError, TypeError):
        return None


def epoch(value):
    if not value:
        return None
    if isinstance(value, (int, float)):
        return number(value)
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except (ValueError, TypeError, AttributeError):
        return None


def retry_time(headers, now):
    value = next((v for k, v in headers.items() if k.lower() == "retry-after"), None)
    if isinstance(value, list):
        value = value[0] if value else None
    seconds = number(value)
    if seconds is not None:
        return now + max(120, seconds)
    if value:
        try:
            return max(now + 120, parsedate_to_datetime(value).timestamp())
        except (ValueError, TypeError, OverflowError):
            pass
    return now + 300


def management(base_url, key, path, payload=None):
    body = json.dumps(payload).encode() if payload is not None else None
    request = Request(
        base_url + "/v8/management/" + path,
        data=body,
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"},
    )
    try:
        with urlopen(request, timeout=20) as response:
            return json.load(response)
    except HTTPError as error:
        # Do not publish server error bodies: they can contain credential details.
        raise QuotaError(f"Management HTTP {error.code}") from None
    except (URLError, TimeoutError, OSError):
        raise QuotaError("CLIProxyAPI unreachable") from None
    except (ValueError, TypeError):
        raise QuotaError("Invalid management response") from None


def window(name, used, reset_at, seconds):
    used = number(used)
    if used is None:
        return None
    return {
        "name": name,
        "remaining": round(max(0, min(100, 100 - used)), 1),
        "resetAt": epoch(reset_at),
        "seconds": seconds,
    }


def normalize(provider, payload):
    windows = []
    if provider == "codex":
        limits = payload.get("rate_limit") or {}
        for key in ("primary_window", "secondary_window"):
            raw = limits.get(key) or {}
            seconds = number(raw.get("limit_window_seconds"))
            name = (
                "5 hour"
                if seconds == 18000
                else "Weekly"
                if seconds == 604800
                else "Quota"
            )
            item = window(name, raw.get("used_percent"), raw.get("reset_at"), seconds)
            if item:
                windows.append(item)
        plan = payload.get("plan_type") or ""
    else:
        for key, name, seconds in (
            ("five_hour", "5 hour", 18000),
            ("seven_day", "Weekly", 604800),
            ("seven_day_opus", "Opus weekly", 604800),
            ("seven_day_sonnet", "Sonnet weekly", 604800),
            ("seven_day_oauth_apps", "OAuth apps weekly", 604800),
        ):
            raw = payload.get(key) or {}
            item = window(name, raw.get("utilization"), raw.get("resets_at"), seconds)
            if item:
                windows.append(item)
        plan = ""
    if not windows:
        raise QuotaError("Usage response has no quota windows")
    return windows, str(plan)


def usage(base_url, key, credential, now):
    provider = credential.get("provider") or credential.get("type")
    headers = {"Authorization": "Bearer $TOKEN$", "Content-Type": "application/json"}
    if provider == "codex":
        url = "https://chatgpt.com/backend-api/wham/usage"
        headers["User-Agent"] = "codex-tui/0.149.1"
        claims = credential.get("id_token") or {}
        account_id = (
            claims.get("chatgpt_account_id") if isinstance(claims, dict) else None
        )
        if account_id:
            headers["ChatGPT-Account-Id"] = account_id
    else:
        url = "https://api.anthropic.com/api/oauth/usage"
        headers.update(
            {
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "claude-cli/2.1.280 (external, cli)",
            }
        )
    result = management(
        base_url,
        key,
        "requests/api-call",
        {
            "authIndex": credential["auth_index"],
            "method": "GET",
            "url": url,
            "header": headers,
        },
    )
    code = result.get("status_code")
    if code == 429:
        raise QuotaError(
            "Usage rate limited", retry_time(result.get("header") or {}, now)
        )
    if not isinstance(code, int) or not 200 <= code < 300:
        raise QuotaError(f"Usage HTTP {code}")
    try:
        payload = json.loads(result["body"])
        return normalize(provider, payload)
    except (ValueError, TypeError, KeyError, AttributeError):
        raise QuotaError("Invalid usage response") from None


def collect(base_url, key, previous, now):
    try:
        listing = management(base_url, key, "credentials")
        files = listing["files"]
        if not isinstance(files, list):
            raise TypeError
    except (QuotaError, KeyError, TypeError) as error:
        return {
            "fetched": previous.get("fetched"),
            "error": str(error)
            if isinstance(error, QuotaError)
            else "Invalid account list",
            "accounts": previous.get("accounts", {}),
        }

    accounts = {}
    for credential in files:
        provider = credential.get("provider") or credential.get("type")
        if provider not in ("codex", "claude"):
            continue
        index = credential.get("auth_index")
        if not index:
            continue
        old = previous.get("accounts", {}).get(index, {})
        account = {
            "provider": provider,
            "label": str(
                credential.get("label")
                or credential.get("email")
                or credential.get("name")
                or provider
            ),
            "disabled": bool(credential.get("disabled")),
            "unavailable": bool(credential.get("unavailable")),
            "plan": old.get("plan", ""),
            "windows": old.get("windows", []),
            "fetched": old.get("fetched"),
            "error": old.get("error", ""),
            "retryAt": old.get("retryAt", 0),
        }
        # Paused accounts remain visible, but do not generate usage traffic.
        if not account["disabled"] and now >= account["retryAt"]:
            try:
                account["windows"], account["plan"] = usage(
                    base_url, key, credential, now
                )
                account.update(fetched=time.time(), error="", retryAt=0)
            except QuotaError as error:
                account.update(error=str(error), retryAt=error.retry_at)
        accounts[index] = account
    return {"fetched": now, "error": "", "accounts": accounts}


def write_json(path, value, mode):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, allow_nan=False))
    temporary.chmod(mode)
    temporary.replace(path)


def main():
    directory = Path(os.environ["RUNTIME_DIRECTORY"])
    cache = directory / "cache.json"
    try:
        previous = json.loads(cache.read_text())
    except (OSError, ValueError):
        previous = {}
    key = (
        (Path(os.environ["CREDENTIALS_DIRECTORY"]) / "management-key")
        .read_text()
        .strip()
    )
    snapshot = collect(sys.argv[1].rstrip("/"), key, previous, time.time())
    write_json(cache, snapshot, 0o600)
    # Explicit fields only. Never serialize raw credentials, upstream bodies or headers.
    write_json(
        directory / "quota.json",
        {
            "fetched": snapshot["fetched"],
            "error": snapshot["error"],
            "accounts": list(snapshot["accounts"].values()),
        },
        0o644,
    )


if __name__ == "__main__":
    main()
