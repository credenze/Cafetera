begin;

alter table public.movements
  add column if not exists recipient text references public.members(name);
alter table public.movements drop constraint if exists movements_type_check;
alter table public.movements add constraint movements_type_check
  check (type in ('cup','payment','coffee','milk','sugar','product','peer'));
alter table public.movements drop constraint if exists movements_recipient_check;
alter table public.movements add constraint movements_recipient_check check (
  (type = 'peer' and recipient is not null and recipient <> person)
  or (type <> 'peer' and recipient is null)
);

create or replace function public.pay_colleague(
  p_id uuid, p_recipient text, p_cents integer, p_note text default ''
) returns void language plpgsql security definer set search_path = '' as $$
declare
  payer text;
  payer_debt bigint;
  recipient_debt bigint;
begin
  select name into payer from public.members where id = auth.uid();
  if payer is null or p_recipient is null or payer = p_recipient then
    raise exception 'Selecciona otro compañero';
  end if;
  if p_cents is null or p_cents not between 1 and 1000000 then
    raise exception 'Importe no válido';
  end if;
  -- Serializa el cálculo con otros pagos, consumos y anulaciones.
  lock table public.movements in share row exclusive mode;
  with entries as (
    select person, case when type = 'cup' then cents else -cents end as delta
      from public.movements where not void
    union all
    select recipient, cents from public.movements where type = 'peer' and not void
  )
  select coalesce(sum(delta) filter (where person = payer),0),
         coalesce(sum(delta) filter (where person = p_recipient),0)
    into payer_debt, recipient_debt from entries;
  if p_cents > least(payer_debt, -recipient_debt) then
    raise exception 'El importe supera tu deuda o el saldo a favor del compañero. Actualiza las cuentas.';
  end if;
  insert into public.movements(id,person,recipient,type,cents,note)
    values(p_id,payer,p_recipient,'peer',p_cents,p_note);
end $$;
revoke all on function public.pay_colleague(uuid,text,integer,text) from public, anon;
grant execute on function public.pay_colleague(uuid,text,integer,text) to authenticated;
create or replace function public.add_movement(p_id uuid,p_type text,p_cents integer,p_note text default '') returns void
language plpgsql security definer set search_path = '' as $
declare v_name text;
begin
 select name into v_name from public.members where id=auth.uid();
 if v_name is null then raise exception 'Cuenta no autorizada'; end if;
 if p_type is null or p_type not in ('cup','payment','coffee','milk','sugar','product') or p_cents is null or p_cents < 1 or p_cents > 1000000 or (p_type='cup' and p_cents<>50) or p_note is null or length(p_note)>160 then raise exception 'Movimiento no válido'; end if;
 if p_type = 'product' and btrim(p_note) = '' then raise exception 'Escribe el concepto de la compra'; end if;
 insert into public.movements(id,person,type,cents,note) values(p_id,v_name,p_type,p_cents,p_note);
end $;
commit;
