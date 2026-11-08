-- Peekapoo Zone Puppies private shared invoice database
-- Run this entire script in Supabase Dashboard > SQL Editor > New query.
-- This script is safe to re-run. It closes anonymous/public table access and
-- permits access only to authenticated Supabase users.

create table if not exists public.shared_invoice_data (
  id integer primary key check (id = 1),
  payload jsonb not null default '{"invoices":[],"folders":[],"invoiceCounter":0}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.shared_invoice_data enable row level security;

-- Remove any broad/default grants. The publishable key alone must never grant
-- access to customer or invoice records.
revoke all on table public.shared_invoice_data from public, anon;
grant select, insert, update on table public.shared_invoice_data to authenticated;

-- Require a real authenticated user for every permitted operation.
drop policy if exists "Authenticated users can read shared invoices" on public.shared_invoice_data;
create policy "Authenticated users can read shared invoices"
  on public.shared_invoice_data for select
  to authenticated using (auth.uid() is not null);

drop policy if exists "Authenticated users can insert shared invoices" on public.shared_invoice_data;
create policy "Authenticated users can insert shared invoices"
  on public.shared_invoice_data for insert
  to authenticated with check (auth.uid() is not null);

drop policy if exists "Authenticated users can update shared invoices" on public.shared_invoice_data;
create policy "Authenticated users can update shared invoices"
  on public.shared_invoice_data for update
  to authenticated using (auth.uid() is not null)
  with check (auth.uid() is not null);

-- No DELETE grant or DELETE policy is provided. Folder deletion in the app
-- only unassigns invoices from the folder; it does not delete invoice records.


-- Private storage for puppy photos. Photos are uploaded individually instead
-- of embedding large base64 images in the shared JSON database row.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('invoice-puppy-photos', 'invoice-puppy-photos', false, 15728640,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
set public = false,
    file_size_limit = 15728640,
    allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Authenticated users can read invoice puppy photos" on storage.objects;
create policy "Authenticated users can read invoice puppy photos"
on storage.objects for select to authenticated
using (bucket_id = 'invoice-puppy-photos' and auth.uid() is not null);

drop policy if exists "Authenticated users can upload invoice puppy photos" on storage.objects;
create policy "Authenticated users can upload invoice puppy photos"
on storage.objects for insert to authenticated
with check (bucket_id = 'invoice-puppy-photos' and auth.uid() is not null);

drop policy if exists "Authenticated users can update invoice puppy photos" on storage.objects;
create policy "Authenticated users can update invoice puppy photos"
on storage.objects for update to authenticated
using (bucket_id = 'invoice-puppy-photos' and auth.uid() is not null)
with check (bucket_id = 'invoice-puppy-photos' and auth.uid() is not null);
