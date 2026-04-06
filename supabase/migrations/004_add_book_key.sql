-- B1.1: align sync schema with book/workspace boundaries for core ledger tables.

alter table public.transactions
  add column if not exists book_key text;

alter table public.transactions
  alter column book_key set default 'book_default';

update public.transactions
set book_key = 'book_default'
where book_key is null or nullif(btrim(book_key), '') is null;

alter table public.transactions
  alter column book_key set not null;

alter table public.accounts
  add column if not exists book_key text;

alter table public.accounts
  alter column book_key set default 'book_default';

update public.accounts
set book_key = 'book_default'
where book_key is null or nullif(btrim(book_key), '') is null;

alter table public.accounts
  alter column book_key set not null;

alter table public.budgets
  add column if not exists book_key text;

alter table public.budgets
  alter column book_key set default 'book_default';

update public.budgets
set book_key = 'book_default'
where book_key is null or nullif(btrim(book_key), '') is null;

alter table public.budgets
  alter column book_key set not null;

create index if not exists idx_transactions_book_key
  on public.transactions(book_key);

create index if not exists idx_accounts_book_key
  on public.accounts(book_key);

create index if not exists idx_budgets_book_key
  on public.budgets(book_key);

drop policy if exists "Users can read own transactions" on public.transactions;
drop policy if exists "Users can insert own transactions" on public.transactions;
drop policy if exists "Users can update own transactions" on public.transactions;
drop policy if exists "Users can delete own transactions" on public.transactions;

create policy "Users can read own transactions"
  on public.transactions for select
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "Users can insert own transactions"
  on public.transactions for insert
  with check (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "Users can update own transactions"
  on public.transactions for update
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  )
  with check (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "Users can delete own transactions"
  on public.transactions for delete
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

drop policy if exists "accounts_select" on public.accounts;
drop policy if exists "accounts_insert" on public.accounts;
drop policy if exists "accounts_update" on public.accounts;
drop policy if exists "accounts_delete" on public.accounts;

create policy "accounts_select"
  on public.accounts for select
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "accounts_insert"
  on public.accounts for insert
  with check (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "accounts_update"
  on public.accounts for update
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  )
  with check (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "accounts_delete"
  on public.accounts for delete
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

drop policy if exists "budgets_select" on public.budgets;
drop policy if exists "budgets_insert" on public.budgets;
drop policy if exists "budgets_update" on public.budgets;
drop policy if exists "budgets_delete" on public.budgets;

create policy "budgets_select"
  on public.budgets for select
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "budgets_insert"
  on public.budgets for insert
  with check (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "budgets_update"
  on public.budgets for update
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  )
  with check (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );

create policy "budgets_delete"
  on public.budgets for delete
  using (
    auth.uid() = user_id
    and nullif(btrim(book_key), '') is not null
  );
