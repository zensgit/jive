#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="${STAGING_ENV_FILE:-/tmp/jive-saas-staging.env}"
OUT_DIR="${JIVE_SAAS_SYNC_SMOKE_OUT_DIR:-}"
KEEP_USER=0
SKIP_CLEANUP=0
PYTHON_BIN="${PYTHON_BIN:-python3}"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_saas_staging_sync_smoke.sh [options]

Options:
  --env-file <path>   Staging env file. Defaults to STAGING_ENV_FILE or /tmp/jive-saas-staging.env.
  --out-dir <path>    Artifact directory. Defaults to /tmp/jive-saas-sync-smoke-<stamp>.
  --keep-user         Keep the temporary auth user for manual follow-up.
  --skip-cleanup      Keep inserted sync rows and the temporary auth user.
  --python <path>     Python interpreter. Defaults to PYTHON_BIN or python3.
  --help              Show this help.

Required env keys:
  SUPABASE_URL
  SUPABASE_ANON_KEY
  SUPABASE_SERVICE_ROLE_KEY

What this smoke validates:
  1. Admin API can create an email-confirmed staging test user.
  2. The staging user can sign in with anon credentials.
  3. Account, transaction, and budget sync payloads can be inserted through RLS.
  4. A second user session can pull inserted core rows by sync_key.
  5. Transaction account_sync_key references survive the round trip.
  6. Transaction and budget rows can be updated with deleted_at tombstones through RLS.
  7. Test rows and temporary user are cleaned up unless skipped.

Notes:
  The script writes only redacted metadata and smoke artifacts. It does not print secrets.
EOF
}

log() {
  printf '[saas-sync-smoke] %s\n' "$*"
}

die() {
  printf '[saas-sync-smoke] ERROR: %s\n' "$*" >&2
  exit 1
}

require_value() {
  local flag="${1:-}"
  local value="${2:-}"
  [[ -n "$value" ]] || die "$flag requires a value"
}

parse_args() {
  while (($#)); do
    case "$1" in
      --env-file)
        require_value "$1" "${2:-}"
        ENV_FILE="${2:-}"
        shift 2
        ;;
      --out-dir)
        require_value "$1" "${2:-}"
        OUT_DIR="${2:-}"
        shift 2
        ;;
      --keep-user)
        KEEP_USER=1
        shift
        ;;
      --skip-cleanup)
        SKIP_CLEANUP=1
        KEEP_USER=1
        shift
        ;;
      --python)
        require_value "$1" "${2:-}"
        PYTHON_BIN="${2:-}"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

load_env_file() {
  [[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

main() {
  parse_args "$@"
  load_env_file

  [[ -n "${SUPABASE_URL:-}" ]] || die "SUPABASE_URL is required"
  [[ -n "${SUPABASE_ANON_KEY:-}" ]] || die "SUPABASE_ANON_KEY is required"
  [[ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]] || die "SUPABASE_SERVICE_ROLE_KEY is required"
  command -v "$PYTHON_BIN" >/dev/null 2>&1 || die "python not found: $PYTHON_BIN"

  if [[ -z "$OUT_DIR" ]]; then
    OUT_DIR="/tmp/jive-saas-sync-smoke-$(date +%Y%m%d-%H%M%S)"
  fi
  mkdir -p "$OUT_DIR"

  log "artifacts: $OUT_DIR"
  log "env file: $ENV_FILE"
  log "starting staging sync push/pull smoke"

  SUPABASE_URL="$SUPABASE_URL" \
  SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY" \
  JIVE_SAAS_SYNC_SMOKE_OUT_DIR="$OUT_DIR" \
  JIVE_SAAS_SYNC_SMOKE_KEEP_USER="$KEEP_USER" \
  JIVE_SAAS_SYNC_SMOKE_SKIP_CLEANUP="$SKIP_CLEANUP" \
    "$PYTHON_BIN" - <<'PY'
from __future__ import annotations

import datetime as dt
import json
import os
import secrets
import string
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


class SmokeFailure(RuntimeError):
    pass


supabase_url = os.environ["SUPABASE_URL"].rstrip("/")
anon_key = os.environ["SUPABASE_ANON_KEY"]
service_role_key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
out_dir = Path(os.environ["JIVE_SAAS_SYNC_SMOKE_OUT_DIR"])
keep_user = os.environ.get("JIVE_SAAS_SYNC_SMOKE_KEEP_USER") == "1"
skip_cleanup = os.environ.get("JIVE_SAAS_SYNC_SMOKE_SKIP_CLEANUP") == "1"

stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d%H%M%S")
suffix = "".join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(8))
email = f"jive-sync-smoke-{stamp}-{suffix}@example.invalid"
password = "JiveSyncSmoke!" + "".join(
    secrets.choice(string.ascii_letters + string.digits) for _ in range(18)
)
sync_key = f"jive_sync_smoke_tx_{stamp}_{suffix}"
account_sync_key = f"jive_sync_smoke_acct_{stamp}_{suffix}"
budget_sync_key = f"jive_sync_smoke_budget_{stamp}_{suffix}"
book_key = "book_default"
local_id = int(time.time() * 1000) % 900000000000
account_local_id = local_id + 1
budget_local_id = local_id + 2
now = dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")

created_user_id: str | None = None
access_token_1: str | None = None
access_token_2: str | None = None
cleanup_errors: list[str] = []


def write_json(name: str, payload: object) -> None:
    (out_dir / name).write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )


def request_json(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    payload: object | None = None,
    expected: tuple[int, ...] = (200,),
) -> tuple[int, object | None, str]:
    data: bytes | None = None
    req_headers = dict(headers or {})
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        req_headers.setdefault("Content-Type", "application/json")
    req = urllib.request.Request(url, data=data, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read().decode("utf-8", errors="replace")
            status = response.status
    except urllib.error.HTTPError as error:
        raw = error.read().decode("utf-8", errors="replace")
        status = error.code
    except urllib.error.URLError as error:
        raise SmokeFailure(f"{method} {url} failed: {error}") from error

    parsed: object | None = None
    if raw.strip():
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = {"raw": raw}

    if status not in expected:
        raise SmokeFailure(
            f"{method} {url} returned {status}, expected {expected}: {raw[:500]}"
        )
    return status, parsed, raw


def service_headers() -> dict[str, str]:
    return {
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
    }


def anon_headers(token: str | None = None) -> dict[str, str]:
    headers = {"apikey": anon_key}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def rest_url(table: str, query: str = "") -> str:
    base = f"{supabase_url}/rest/v1/{table}"
    return f"{base}?{query}" if query else base


def sign_in() -> tuple[str, str]:
    status, parsed, _ = request_json(
        "POST",
        f"{supabase_url}/auth/v1/token?grant_type=password",
        headers=anon_headers(),
        payload={"email": email, "password": password},
        expected=(200,),
    )
    if not isinstance(parsed, dict):
        raise SmokeFailure(f"sign-in returned non-object payload: {parsed!r}")
    token = parsed.get("access_token")
    user = parsed.get("user")
    if not isinstance(token, str) or not token:
        raise SmokeFailure("sign-in did not return access_token")
    if not isinstance(user, dict) or not isinstance(user.get("id"), str):
        raise SmokeFailure("sign-in did not return user.id")
    return token, user["id"]


def cleanup() -> None:
    if skip_cleanup:
        return

    tx_query = urllib.parse.urlencode({"sync_key": f"eq.{sync_key}"})
    try:
        request_json(
            "DELETE",
            rest_url("transactions", tx_query),
            headers=service_headers(),
            expected=(200, 204),
        )
    except Exception as error:  # noqa: BLE001 - cleanup must not hide original result.
        cleanup_errors.append(f"transaction cleanup failed: {error}")

    budget_query = urllib.parse.urlencode({"sync_key": f"eq.{budget_sync_key}"})
    try:
        request_json(
            "DELETE",
            rest_url("budgets", budget_query),
            headers=service_headers(),
            expected=(200, 204),
        )
    except Exception as error:  # noqa: BLE001 - cleanup must not hide original result.
        cleanup_errors.append(f"budget cleanup failed: {error}")

    account_query = urllib.parse.urlencode({"sync_key": f"eq.{account_sync_key}"})
    try:
        request_json(
            "DELETE",
            rest_url("accounts", account_query),
            headers=service_headers(),
            expected=(200, 204),
        )
    except Exception as error:  # noqa: BLE001 - cleanup must not hide original result.
        cleanup_errors.append(f"account cleanup failed: {error}")

    if created_user_id and not keep_user:
        try:
            request_json(
                "DELETE",
                f"{supabase_url}/auth/v1/admin/users/{created_user_id}",
                headers=service_headers(),
                expected=(200, 204),
            )
        except Exception as error:  # noqa: BLE001
            cleanup_errors.append(f"user cleanup failed: {error}")


try:
    write_json(
        "metadata.json",
        {
            "generatedAt": now,
            "supabaseUrlHost": urllib.parse.urlparse(supabase_url).netloc,
            "email": email,
            "syncKey": sync_key,
            "accountSyncKey": account_sync_key,
            "budgetSyncKey": budget_sync_key,
            "bookKey": book_key,
            "localId": local_id,
            "accountLocalId": account_local_id,
            "budgetLocalId": budget_local_id,
            "keepUser": keep_user,
            "skipCleanup": skip_cleanup,
        },
    )

    _, create_payload, _ = request_json(
        "POST",
        f"{supabase_url}/auth/v1/admin/users",
        headers=service_headers(),
        payload={
            "email": email,
            "password": password,
            "email_confirm": True,
            "user_metadata": {"source": "jive_saas_staging_sync_smoke"},
        },
        expected=(200,),
    )
    if not isinstance(create_payload, dict) or not isinstance(create_payload.get("id"), str):
        raise SmokeFailure("admin create user did not return user id")
    created_user_id = create_payload["id"]
    write_json("create-user.redacted.json", {"id": created_user_id, "email": email})

    access_token_1, user_id_1 = sign_in()
    access_token_2, user_id_2 = sign_in()
    if user_id_1 != created_user_id or user_id_2 != created_user_id:
        raise SmokeFailure("signed-in user id does not match created user id")
    write_json("sessions.redacted.json", {"userId": created_user_id, "sessionCount": 2})

    account_payload = {
        "user_id": created_user_id,
        "local_id": account_local_id,
        "sync_key": account_sync_key,
        "book_key": book_key,
        "name": f"Staging Smoke Account {stamp}",
        "type": "asset",
        "sub_type": "cash",
        "opening_balance": 100.0,
        "credit_limit": None,
        "currency": "CNY",
        "is_archived": False,
        "sort_order": 880,
        "updated_at": now,
    }
    _, account_insert_payload, _ = request_json(
        "POST",
        rest_url("accounts"),
        headers={
            **anon_headers(access_token_1),
            "Prefer": "return=representation",
        },
        payload=account_payload,
        expected=(201,),
    )
    if not isinstance(account_insert_payload, list) or len(account_insert_payload) != 1:
        raise SmokeFailure(f"account insert returned unexpected payload: {account_insert_payload!r}")
    inserted_account = account_insert_payload[0]
    if (
        not isinstance(inserted_account, dict)
        or inserted_account.get("sync_key") != account_sync_key
    ):
        raise SmokeFailure("inserted account did not echo expected sync_key")
    write_json(
        "inserted-account.redacted.json",
        {
            "id": inserted_account.get("id"),
            "user_id": inserted_account.get("user_id"),
            "local_id": inserted_account.get("local_id"),
            "sync_key": inserted_account.get("sync_key"),
            "book_key": inserted_account.get("book_key"),
            "name": inserted_account.get("name"),
            "type": inserted_account.get("type"),
            "currency": inserted_account.get("currency"),
            "updated_at": inserted_account.get("updated_at"),
        },
    )

    account_select_query = urllib.parse.urlencode(
        {
            "select": "id,user_id,local_id,sync_key,book_key,name,type,currency,updated_at",
            "sync_key": f"eq.{account_sync_key}",
            "order": "updated_at.desc",
        }
    )
    _, account_pull_payload, _ = request_json(
        "GET",
        rest_url("accounts", account_select_query),
        headers=anon_headers(access_token_2),
        expected=(200,),
    )
    if not isinstance(account_pull_payload, list) or len(account_pull_payload) != 1:
        raise SmokeFailure(f"second-session account pull returned {account_pull_payload!r}")
    pulled_account = account_pull_payload[0]
    if not isinstance(pulled_account, dict):
        raise SmokeFailure("second-session account pull returned non-object row")
    if pulled_account.get("sync_key") != account_sync_key:
        raise SmokeFailure("second-session account pull sync_key mismatch")
    if pulled_account.get("book_key") != book_key:
        raise SmokeFailure("second-session account pull book_key mismatch")
    write_json("pulled-account.redacted.json", pulled_account)

    tx_payload = {
        "user_id": created_user_id,
        "local_id": local_id,
        "sync_key": sync_key,
        "book_key": book_key,
        "amount": 12.34,
        "source": "saas_staging_sync_smoke",
        "type": "expense",
        "timestamp": now,
        "category_key": "cat_food",
        "category": "餐饮",
        "note": f"staging sync smoke {stamp}",
        "account_id": account_local_id,
        "account_sync_key": account_sync_key,
        "raw_text": "staging sync smoke",
        "deleted_at": None,
        "updated_at": now,
    }
    _, insert_payload, _ = request_json(
        "POST",
        rest_url("transactions"),
        headers={
            **anon_headers(access_token_1),
            "Prefer": "return=representation",
        },
        payload=tx_payload,
        expected=(201,),
    )
    if not isinstance(insert_payload, list) or len(insert_payload) != 1:
        raise SmokeFailure(f"insert returned unexpected payload: {insert_payload!r}")
    inserted = insert_payload[0]
    if not isinstance(inserted, dict) or inserted.get("sync_key") != sync_key:
        raise SmokeFailure("inserted transaction did not echo expected sync_key")
    write_json(
        "inserted-transaction.redacted.json",
        {
            "id": inserted.get("id"),
            "user_id": inserted.get("user_id"),
            "local_id": inserted.get("local_id"),
            "sync_key": inserted.get("sync_key"),
            "book_key": inserted.get("book_key"),
            "amount": inserted.get("amount"),
            "account_id": inserted.get("account_id"),
            "account_sync_key": inserted.get("account_sync_key"),
            "deleted_at": inserted.get("deleted_at"),
            "updated_at": inserted.get("updated_at"),
        },
    )

    select_query = urllib.parse.urlencode(
        {
            "select": "id,user_id,local_id,sync_key,book_key,amount,account_id,account_sync_key,deleted_at,updated_at",
            "sync_key": f"eq.{sync_key}",
            "order": "updated_at.desc",
        }
    )
    _, pull_payload, _ = request_json(
        "GET",
        rest_url("transactions", select_query),
        headers=anon_headers(access_token_2),
        expected=(200,),
    )
    if not isinstance(pull_payload, list) or len(pull_payload) != 1:
        raise SmokeFailure(f"second-session pull returned {pull_payload!r}")
    pulled = pull_payload[0]
    if not isinstance(pulled, dict):
        raise SmokeFailure("second-session pull returned non-object row")
    if pulled.get("sync_key") != sync_key:
        raise SmokeFailure("second-session pull sync_key mismatch")
    if pulled.get("book_key") != book_key:
        raise SmokeFailure("second-session pull book_key mismatch")
    if pulled.get("account_sync_key") != account_sync_key:
        raise SmokeFailure("second-session pull account_sync_key mismatch")
    if abs(float(pulled.get("amount", 0)) - 12.34) > 0.0001:
        raise SmokeFailure("second-session pull amount mismatch")
    write_json("pulled-transaction.redacted.json", pulled)

    end_date = (
        dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=30)
    ).isoformat(timespec="milliseconds").replace("+00:00", "Z")
    # Match the current SyncEngine payload contract: it writes one category key
    # as a scalar jsonb string and reads both scalar and list forms.
    budget_payload = {
        "user_id": created_user_id,
        "local_id": budget_local_id,
        "sync_key": budget_sync_key,
        "book_key": book_key,
        "name": f"Staging Smoke Budget {stamp}",
        "amount": 880.0,
        "period": "monthly",
        "start_date": now,
        "end_date": end_date,
        "category_keys": "cat_food",
        "is_active": True,
        "carry_over": False,
        "deleted_at": None,
        "updated_at": now,
    }
    _, budget_insert_payload, _ = request_json(
        "POST",
        rest_url("budgets"),
        headers={
            **anon_headers(access_token_1),
            "Prefer": "return=representation",
        },
        payload=budget_payload,
        expected=(201,),
    )
    if not isinstance(budget_insert_payload, list) or len(budget_insert_payload) != 1:
        raise SmokeFailure(f"budget insert returned unexpected payload: {budget_insert_payload!r}")
    inserted_budget = budget_insert_payload[0]
    if (
        not isinstance(inserted_budget, dict)
        or inserted_budget.get("sync_key") != budget_sync_key
    ):
        raise SmokeFailure("inserted budget did not echo expected sync_key")
    write_json(
        "inserted-budget.redacted.json",
        {
            "id": inserted_budget.get("id"),
            "user_id": inserted_budget.get("user_id"),
            "local_id": inserted_budget.get("local_id"),
            "sync_key": inserted_budget.get("sync_key"),
            "book_key": inserted_budget.get("book_key"),
            "name": inserted_budget.get("name"),
            "amount": inserted_budget.get("amount"),
            "period": inserted_budget.get("period"),
            "category_keys": inserted_budget.get("category_keys"),
            "deleted_at": inserted_budget.get("deleted_at"),
            "updated_at": inserted_budget.get("updated_at"),
        },
    )

    budget_select_query = urllib.parse.urlencode(
        {
            "select": "id,user_id,local_id,sync_key,book_key,name,amount,period,category_keys,deleted_at,updated_at",
            "sync_key": f"eq.{budget_sync_key}",
            "order": "updated_at.desc",
        }
    )
    _, budget_pull_payload, _ = request_json(
        "GET",
        rest_url("budgets", budget_select_query),
        headers=anon_headers(access_token_2),
        expected=(200,),
    )
    if not isinstance(budget_pull_payload, list) or len(budget_pull_payload) != 1:
        raise SmokeFailure(f"second-session budget pull returned {budget_pull_payload!r}")
    pulled_budget = budget_pull_payload[0]
    if not isinstance(pulled_budget, dict):
        raise SmokeFailure("second-session budget pull returned non-object row")
    if pulled_budget.get("sync_key") != budget_sync_key:
        raise SmokeFailure("second-session budget pull sync_key mismatch")
    if pulled_budget.get("book_key") != book_key:
        raise SmokeFailure("second-session budget pull book_key mismatch")
    if abs(float(pulled_budget.get("amount", 0)) - 880.0) > 0.0001:
        raise SmokeFailure("second-session budget pull amount mismatch")
    if pulled_budget.get("category_keys") != "cat_food":
        raise SmokeFailure("second-session budget pull category_keys mismatch")
    write_json("pulled-budget.redacted.json", pulled_budget)

    deleted_at = dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
    update_query = urllib.parse.urlencode({"sync_key": f"eq.{sync_key}"})
    _, tombstone_payload, _ = request_json(
        "PATCH",
        rest_url("transactions", update_query),
        headers={
            **anon_headers(access_token_1),
            "Prefer": "return=representation",
        },
        payload={"deleted_at": deleted_at, "updated_at": deleted_at},
        expected=(200,),
    )
    if not isinstance(tombstone_payload, list) or len(tombstone_payload) != 1:
        raise SmokeFailure(f"tombstone update returned {tombstone_payload!r}")
    tombstoned = tombstone_payload[0]
    if not isinstance(tombstoned, dict) or not tombstoned.get("deleted_at"):
        raise SmokeFailure("tombstone update did not persist deleted_at")
    write_json(
        "tombstoned-transaction.redacted.json",
        {
            "id": tombstoned.get("id"),
            "sync_key": tombstoned.get("sync_key"),
            "book_key": tombstoned.get("book_key"),
            "deleted_at": tombstoned.get("deleted_at"),
            "updated_at": tombstoned.get("updated_at"),
        },
    )

    budget_deleted_at = dt.datetime.now(dt.timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
    budget_update_query = urllib.parse.urlencode({"sync_key": f"eq.{budget_sync_key}"})
    _, budget_tombstone_payload, _ = request_json(
        "PATCH",
        rest_url("budgets", budget_update_query),
        headers={
            **anon_headers(access_token_1),
            "Prefer": "return=representation",
        },
        payload={"deleted_at": budget_deleted_at, "updated_at": budget_deleted_at},
        expected=(200,),
    )
    if not isinstance(budget_tombstone_payload, list) or len(budget_tombstone_payload) != 1:
        raise SmokeFailure(f"budget tombstone update returned {budget_tombstone_payload!r}")
    tombstoned_budget = budget_tombstone_payload[0]
    if not isinstance(tombstoned_budget, dict) or not tombstoned_budget.get("deleted_at"):
        raise SmokeFailure("budget tombstone update did not persist deleted_at")
    write_json(
        "tombstoned-budget.redacted.json",
        {
            "id": tombstoned_budget.get("id"),
            "sync_key": tombstoned_budget.get("sync_key"),
            "book_key": tombstoned_budget.get("book_key"),
            "deleted_at": tombstoned_budget.get("deleted_at"),
            "updated_at": tombstoned_budget.get("updated_at"),
        },
    )

    cleanup()
    if cleanup_errors:
        raise SmokeFailure("; ".join(cleanup_errors))

    summary = {
        "status": "PASS",
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "userId": created_user_id,
        "email": email,
        "syncKey": sync_key,
        "accountSyncKey": account_sync_key,
        "budgetSyncKey": budget_sync_key,
        "bookKey": book_key,
        "validated": [
            "admin_user_create",
            "anon_password_sign_in_session_1",
            "anon_password_sign_in_session_2",
            "rls_insert_account",
            "second_session_pull_account_by_sync_key",
            "rls_insert_transaction",
            "second_session_pull_transaction_by_sync_key",
            "transaction_account_sync_key_round_trip",
            "rls_insert_budget",
            "second_session_pull_budget_by_sync_key",
            "rls_transaction_tombstone_update",
            "rls_budget_tombstone_update",
            "cleanup" if not skip_cleanup else "cleanup_skipped",
        ],
        "cleanup": "skipped" if skip_cleanup else ("user_kept" if keep_user else "complete"),
    }
    write_json("summary.json", summary)
    (out_dir / "summary.md").write_text(
        "# SaaS Staging Sync Smoke\n\n"
        f"- status: {summary['status']}\n"
        f"- userId: {created_user_id}\n"
        f"- email: {email}\n"
        f"- transactionSyncKey: {sync_key}\n"
        f"- accountSyncKey: {account_sync_key}\n"
        f"- budgetSyncKey: {budget_sync_key}\n"
        f"- bookKey: {book_key}\n"
        f"- cleanup: {summary['cleanup']}\n"
        f"- artifacts: {out_dir}\n",
        encoding="utf-8",
    )
except Exception as error:  # noqa: BLE001 - report exact smoke failure.
    try:
        cleanup()
    finally:
        write_json(
            "summary.json",
            {
                "status": "FAIL",
                "error": str(error),
                "userId": created_user_id,
                "email": email,
                "syncKey": sync_key,
                "accountSyncKey": account_sync_key,
                "budgetSyncKey": budget_sync_key,
                "cleanupErrors": cleanup_errors,
            },
        )
        (out_dir / "summary.md").write_text(
            "# SaaS Staging Sync Smoke\n\n"
            "- status: FAIL\n"
            f"- error: {error}\n"
            f"- userId: {created_user_id}\n"
            f"- email: {email}\n"
            f"- transactionSyncKey: {sync_key}\n"
            f"- accountSyncKey: {account_sync_key}\n"
            f"- budgetSyncKey: {budget_sync_key}\n"
            f"- artifacts: {out_dir}\n",
            encoding="utf-8",
        )
    raise
PY

  log "PASS"
  log "summary: $OUT_DIR/summary.md"
}

main "$@"
