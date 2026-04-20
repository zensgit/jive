#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    import psycopg
except ModuleNotFoundError as exc:
    print(
        "ERROR: psycopg is required for Postgres fallback. "
        "Install it with `python3 -m pip install --user 'psycopg[binary]'`.",
        file=sys.stderr,
    )
    raise SystemExit(2) from exc


@dataclass(frozen=True)
class MigrationSpec:
    version: str
    name: str
    path: Path


@dataclass
class RemoteState:
    tables: set[str]
    columns: set[tuple[str, str]]
    indexes: set[str]
    constraints: dict[str, str]
    history_versions: set[str]


KNOWN_MIGRATION_VERSIONS = {
    "001",
    "002",
    "003",
    "004",
    "006",
    "007",
    "008",
    "009",
    "010",
    "011",
    "012",
    "013",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Fallback planner/applier for remote Supabase migrations when "
            "`supabase db push` cannot connect to the remote database."
        )
    )
    parser.add_argument("mode", choices=("plan", "apply"))
    parser.add_argument("--db-url", required=True)
    parser.add_argument("--migrations-dir", default="supabase/migrations")
    parser.add_argument("--lock-timeout", default="4s")
    parser.add_argument("--statement-timeout", default="60s")
    return parser.parse_args()


def load_migrations(migrations_dir: Path) -> list[MigrationSpec]:
    specs: list[MigrationSpec] = []
    for path in sorted(migrations_dir.glob("*.sql")):
        match = re.match(r"(?P<version>\d+)_(?P<name>.+)\.sql$", path.name)
        if not match:
            continue
        specs.append(
            MigrationSpec(
                version=match.group("version"),
                name=match.group("name"),
                path=path,
            )
        )
    if not specs:
        raise RuntimeError(f"no migration files found in {migrations_dir}")
    return specs


def fetch_remote_state(conn: psycopg.Connection) -> RemoteState:
    with conn.cursor() as cur:
        cur.execute(
            """
            select tablename
            from pg_tables
            where schemaname = 'public'
            """
        )
        tables = {row[0] for row in cur.fetchall()}

        cur.execute(
            """
            select table_name, column_name
            from information_schema.columns
            where table_schema = 'public'
            """
        )
        columns = {(row[0], row[1]) for row in cur.fetchall()}

        cur.execute(
            """
            select indexname
            from pg_indexes
            where schemaname = 'public'
            """
        )
        indexes = {row[0] for row in cur.fetchall()}

        cur.execute(
            """
            select c.conname, pg_get_constraintdef(c.oid)
            from pg_constraint c
            join pg_class t on t.oid = c.conrelid
            join pg_namespace n on n.oid = t.relnamespace
            where n.nspname = 'public'
            """
        )
        constraints = {row[0]: row[1] for row in cur.fetchall()}

        cur.execute(
            """
            select exists (
              select 1
              from information_schema.schemata
              where schema_name = 'supabase_migrations'
            )
            """
        )
        has_history_schema = cur.fetchone()[0]

        history_versions: set[str] = set()
        if has_history_schema:
            cur.execute(
                """
                select exists (
                  select 1
                  from information_schema.tables
                  where table_schema = 'supabase_migrations'
                    and table_name = 'schema_migrations'
                )
                """
            )
            has_history_table = cur.fetchone()[0]
            if has_history_table:
                cur.execute(
                    "select version from supabase_migrations.schema_migrations"
                )
                history_versions = {row[0] for row in cur.fetchall()}

    return RemoteState(
        tables=tables,
        columns=columns,
        indexes=indexes,
        constraints=constraints,
        history_versions=history_versions,
    )


def has_table(state: RemoteState, table_name: str) -> bool:
    return table_name in state.tables


def has_column(state: RemoteState, table_name: str, column_name: str) -> bool:
    return (table_name, column_name) in state.columns


def has_index(state: RemoteState, index_name: str) -> bool:
    return index_name in state.indexes


def migration_is_applied(version: str, state: RemoteState) -> bool:
    if version == "001":
        return has_table(state, "transactions")
    if version == "002":
        return all(
            has_table(state, table_name)
            for table_name in ("accounts", "categories", "tags", "budgets")
        )
    if version == "003":
        shared_ledgers = has_table(state, "shared_ledgers")
        shared_members = has_table(state, "shared_ledger_members")
        if shared_ledgers != shared_members:
            raise RuntimeError(
                "partial shared ledger schema detected; "
                "manual review is required before applying migration 003"
            )
        return shared_ledgers and shared_members
    if version == "004":
        return all(
            has_column(state, table_name, column_name)
            for table_name, column_name in (
                ("transactions", "book_key"),
                ("accounts", "book_key"),
                ("budgets", "book_key"),
                ("shared_ledgers", "workspace_key"),
            )
        )
    if version == "006":
        return all(
            has_column(state, table_name, "deleted_at")
            for table_name in ("transactions", "budgets")
        )
    if version == "007":
        return has_table(state, "user_subscriptions")
    if version == "008":
        required_columns = (
            ("transactions", "sync_key"),
            ("transactions", "account_sync_key"),
            ("transactions", "to_account_sync_key"),
            ("accounts", "sync_key"),
            ("budgets", "sync_key"),
        )
        required_indexes = (
            "idx_transactions_user_sync_key",
            "idx_accounts_user_sync_key",
            "idx_budgets_user_sync_key",
            "idx_categories_user_key",
            "idx_tags_user_key",
            "idx_transactions_account_sync_key",
            "idx_transactions_to_account_sync_key",
            "idx_transactions_user_local_id",
            "idx_accounts_user_local_id",
            "idx_budgets_user_local_id",
        )
        return all(
            has_column(state, table_name, column_name)
            for table_name, column_name in required_columns
        ) and all(has_index(state, index_name) for index_name in required_indexes)
    if version == "009":
        return has_table(state, "subscription_webhook_notifications")
    if version == "010":
        return has_table(state, "analytics_events")
    if version == "011":
        return has_table(state, "notification_queue")
    if version == "012":
        constraint = state.constraints.get("user_subscriptions_platform_check", "")
        return has_index(
            state, "idx_user_subscriptions_admin_override_unique"
        ) and "admin_override" in constraint
    if version == "013":
        constraint = state.constraints.get("user_subscriptions_platform_check", "")
        required_columns = (
            ("user_subscriptions", "source_order_no"),
            ("user_subscriptions", "provider_trade_no"),
        )
        required_indexes = (
            "idx_payment_orders_user_updated",
            "idx_payment_orders_provider_trade_unique",
            "idx_payment_events_provider_event_unique",
            "idx_payment_events_order_created",
        )
        return (
            "wechat_pay" in constraint
            and "alipay" in constraint
            and all(
                has_column(state, table_name, column_name)
                for table_name, column_name in required_columns
            )
            and has_table(state, "payment_orders")
            and has_table(state, "payment_events")
            and all(has_index(state, index_name) for index_name in required_indexes)
        )
    raise RuntimeError(
        f"migration {version} is not reviewed by the direct Postgres fallback yet"
    )


def classify_migrations(
    migrations: list[MigrationSpec], state: RemoteState
) -> tuple[list[MigrationSpec], list[MigrationSpec]]:
    baselines: list[MigrationSpec] = []
    pending: list[MigrationSpec] = []

    for spec in migrations:
        applied = migration_is_applied(spec.version, state)
        recorded = spec.version in state.history_versions

        if recorded and not applied:
            raise RuntimeError(
                f"remote history marks migration {spec.version} as applied, "
                "but the expected schema marker is missing"
            )

        if applied:
            if not recorded:
                baselines.append(spec)
            continue

        pending.append(spec)

    return baselines, pending


def ensure_history_table(cur: psycopg.Cursor) -> None:
    cur.execute("create schema if not exists supabase_migrations")
    cur.execute(
        """
        create table if not exists supabase_migrations.schema_migrations (
          version text not null primary key
        )
        """
    )
    cur.execute(
        """
        alter table supabase_migrations.schema_migrations
          add column if not exists statements text[]
        """
    )
    cur.execute(
        """
        alter table supabase_migrations.schema_migrations
          add column if not exists name text
        """
    )


def upsert_history(cur: psycopg.Cursor, spec: MigrationSpec) -> None:
    sql_text = spec.path.read_text(encoding="utf-8")
    cur.execute(
        """
        insert into supabase_migrations.schema_migrations(version, name, statements)
        values (%s, %s, %s)
        on conflict (version)
        do update set
          name = excluded.name,
          statements = excluded.statements
        """,
        (spec.version, spec.name, [sql_text]),
    )


def print_plan(
    baselines: list[MigrationSpec], pending: list[MigrationSpec], state: RemoteState
) -> None:
    history = ", ".join(sorted(state.history_versions)) or "(none)"
    baseline_versions = ", ".join(spec.version for spec in baselines) or "(none)"
    pending_versions = ", ".join(spec.version for spec in pending) or "(none)"

    print(f"remote_history_versions: {history}")
    print(f"baseline_versions: {baseline_versions}")
    print(f"pending_versions: {pending_versions}")

    for spec in baselines:
        print(f"BASELINE {spec.version} {spec.path.name}")
    for spec in pending:
        print(f"PENDING  {spec.version} {spec.path.name}")


def apply_plan(
    conn: psycopg.Connection,
    baselines: list[MigrationSpec],
    pending: list[MigrationSpec],
    lock_timeout: str,
    statement_timeout: str,
) -> None:
    with conn.transaction():
        with conn.cursor() as cur:
            ensure_history_table(cur)
            for spec in baselines:
                upsert_history(cur, spec)

    for spec in pending:
        sql_text = spec.path.read_text(encoding="utf-8")
        with conn.transaction():
            with conn.cursor() as cur:
                cur.execute("set local lock_timeout = %s", (lock_timeout,))
                cur.execute(
                    "set local statement_timeout = %s", (statement_timeout,)
                )
                cur.execute(sql_text)
                ensure_history_table(cur)
                upsert_history(cur, spec)
        print(f"APPLIED  {spec.version} {spec.path.name}")

    if baselines:
        versions = ", ".join(spec.version for spec in baselines)
        print(f"BASELINED {versions}")


def main() -> int:
    args = parse_args()
    migrations = load_migrations(Path(args.migrations_dir))
    unsupported_versions = sorted(
        {spec.version for spec in migrations} - KNOWN_MIGRATION_VERSIONS
    )
    if unsupported_versions:
        versions = ", ".join(unsupported_versions)
        raise RuntimeError(
            "fallback planner only supports explicitly reviewed migrations. "
            f"Unsupported versions: {versions}"
        )

    with psycopg.connect(args.db_url, autocommit=False) as conn:
        state = fetch_remote_state(conn)
        baselines, pending = classify_migrations(migrations, state)
        print_plan(baselines, pending, state)

        if args.mode == "plan":
            return 0

        apply_plan(
            conn,
            baselines,
            pending,
            args.lock_timeout,
            args.statement_timeout,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
