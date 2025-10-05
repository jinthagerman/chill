set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_user_video_list()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
    insert into public.video_lists (owner_id)
    values (new.id)
    on conflict (owner_id) do nothing;

    insert into public.video_list_members (user_id, list_owner_id, role, added_by)
    values (new.id, new.id, 'owner', new.id)
    on conflict (user_id) do update
        set list_owner_id = excluded.list_owner_id,
            role = 'owner',
            added_by = excluded.added_by,
            added_at = timezone('utc', now());

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
    new.updated_at = timezone('utc', now());
    return new;
end;
$function$
;



