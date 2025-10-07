revoke delete on table "public"."video_list_members" from "anon";

revoke insert on table "public"."video_list_members" from "anon";

revoke references on table "public"."video_list_members" from "anon";

revoke select on table "public"."video_list_members" from "anon";

revoke trigger on table "public"."video_list_members" from "anon";

revoke truncate on table "public"."video_list_members" from "anon";

revoke update on table "public"."video_list_members" from "anon";

revoke delete on table "public"."video_list_members" from "authenticated";

revoke insert on table "public"."video_list_members" from "authenticated";

revoke references on table "public"."video_list_members" from "authenticated";

revoke select on table "public"."video_list_members" from "authenticated";

revoke trigger on table "public"."video_list_members" from "authenticated";

revoke truncate on table "public"."video_list_members" from "authenticated";

revoke update on table "public"."video_list_members" from "authenticated";

revoke delete on table "public"."video_list_members" from "service_role";

revoke insert on table "public"."video_list_members" from "service_role";

revoke references on table "public"."video_list_members" from "service_role";

revoke select on table "public"."video_list_members" from "service_role";

revoke trigger on table "public"."video_list_members" from "service_role";

revoke truncate on table "public"."video_list_members" from "service_role";

revoke update on table "public"."video_list_members" from "service_role";

revoke delete on table "public"."video_lists" from "anon";

revoke insert on table "public"."video_lists" from "anon";

revoke references on table "public"."video_lists" from "anon";

revoke select on table "public"."video_lists" from "anon";

revoke trigger on table "public"."video_lists" from "anon";

revoke truncate on table "public"."video_lists" from "anon";

revoke update on table "public"."video_lists" from "anon";

revoke delete on table "public"."video_lists" from "authenticated";

revoke insert on table "public"."video_lists" from "authenticated";

revoke references on table "public"."video_lists" from "authenticated";

revoke select on table "public"."video_lists" from "authenticated";

revoke trigger on table "public"."video_lists" from "authenticated";

revoke truncate on table "public"."video_lists" from "authenticated";

revoke update on table "public"."video_lists" from "authenticated";

revoke delete on table "public"."video_lists" from "service_role";

revoke insert on table "public"."video_lists" from "service_role";

revoke references on table "public"."video_lists" from "service_role";

revoke select on table "public"."video_lists" from "service_role";

revoke trigger on table "public"."video_lists" from "service_role";

revoke truncate on table "public"."video_lists" from "service_role";

revoke update on table "public"."video_lists" from "service_role";

revoke delete on table "public"."videos" from "anon";

revoke insert on table "public"."videos" from "anon";

revoke references on table "public"."videos" from "anon";

revoke select on table "public"."videos" from "anon";

revoke trigger on table "public"."videos" from "anon";

revoke truncate on table "public"."videos" from "anon";

revoke update on table "public"."videos" from "anon";

revoke delete on table "public"."videos" from "authenticated";

revoke insert on table "public"."videos" from "authenticated";

revoke references on table "public"."videos" from "authenticated";

revoke select on table "public"."videos" from "authenticated";

revoke trigger on table "public"."videos" from "authenticated";

revoke truncate on table "public"."videos" from "authenticated";

revoke update on table "public"."videos" from "authenticated";

revoke delete on table "public"."videos" from "service_role";

revoke insert on table "public"."videos" from "service_role";

revoke references on table "public"."videos" from "service_role";

revoke select on table "public"."videos" from "service_role";

revoke trigger on table "public"."videos" from "service_role";

revoke truncate on table "public"."videos" from "service_role";

revoke update on table "public"."videos" from "service_role";

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



