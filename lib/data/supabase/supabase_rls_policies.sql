-- ARCHITECTURE.md §10 and PROMPT.md §4.8:
-- player-specific Supabase tables must have RLS enabled and scoped to
-- auth.uid() = player_id. This SQL is applied in Supabase, not from the client.

alter table player_progress enable row level security;
alter table purchases enable row level security;
alter table leaderboards enable row level security;

create policy "player_progress_select_own"
on player_progress for select
using (auth.uid() = player_id);

create policy "player_progress_insert_own"
on player_progress for insert
with check (auth.uid() = player_id);

create policy "player_progress_update_own"
on player_progress for update
using (auth.uid() = player_id)
with check (auth.uid() = player_id);

create policy "purchases_select_own"
on purchases for select
using (auth.uid() = player_id);

create policy "purchases_insert_own"
on purchases for insert
with check (auth.uid() = player_id);

create policy "purchases_update_own"
on purchases for update
using (auth.uid() = player_id)
with check (auth.uid() = player_id);

create policy "leaderboards_select_all"
on leaderboards for select
using (true);

create policy "leaderboards_insert_own"
on leaderboards for insert
with check (auth.uid() = player_id);

create policy "leaderboards_update_own"
on leaderboards for update
using (auth.uid() = player_id)
with check (auth.uid() = player_id);
