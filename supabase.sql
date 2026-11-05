-- Ejecutar una sola vez en SQL Editor de un proyecto nuevo de Supabase.
begin;
create table public.members (
 id uuid primary key references auth.users(id),
 name text not null unique check (name in ('Juan Pablo','Moises','Jesus','Alejandro','Daniel'))
);
create table public.movements (
 id uuid primary key,
 person text not null references public.members(name),
 type text not null check (type in ('cup','payment','coffee','milk','sugar')),
 cents integer not null check (cents between 1 and 1000000 and (type <> 'cup' or cents = 50)),
 note text not null default '' check (length(note) <= 160),
 date timestamptz not null default now(),
 void boolean not null default false
);
alter table public.members enable row level security;
alter table public.movements enable row level security;
revoke all on public.members, public.movements from anon, authenticated;
grant select on public.members, public.movements to authenticated;
create policy own_membership on public.members for select to authenticated using (id = (select auth.uid()));
create policy member_reads on public.movements for select to authenticated using (exists (select 1 from public.members where id=(select auth.uid())));
create function public.add_movement(p_id uuid,p_type text,p_cents integer,p_note text default '') returns void
language plpgsql security definer set search_path = '' as $$
declare v_name text;
begin
 select name into v_name from public.members where id=auth.uid();
 if v_name is null then raise exception 'Cuenta no autorizada'; end if;
 if p_type is null or p_type not in ('cup','payment','coffee','milk','sugar') or p_cents is null or p_cents < 1 or p_cents > 1000000 or (p_type='cup' and p_cents<>50) or p_note is null or length(p_note)>160 then raise exception 'Movimiento no válido'; end if;
 insert into public.movements(id,person,type,cents,note) values(p_id,v_name,p_type,p_cents,p_note);
end $$;
create function public.void_movement(p_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare v_name text;
begin
 select name into v_name from public.members where id=auth.uid();
 if v_name is null then raise exception 'Cuenta no autorizada'; end if;
 update public.movements set void=true where id=p_id and person=v_name;
 if not found then raise exception 'Movimiento no encontrado o de otro compañero'; end if;
end $$;
revoke all on function public.add_movement(uuid,text,integer,text) from public,anon;
revoke all on function public.void_movement(uuid) from public,anon;
grant execute on function public.add_movement(uuid,text,integer,text) to authenticated;
grant execute on function public.void_movement(uuid) to authenticated;
commit;
