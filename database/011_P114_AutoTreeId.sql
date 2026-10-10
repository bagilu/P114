-- P114｜我們的樹 MyTreeMyRoot
-- 011_P114_AutoTreeId.sql
-- Backend-generated permanent Public Tree ID (T0001..T9999).

BEGIN;

CREATE OR REPLACE FUNCTION public."P114_AdminCreateTreeAuto"(
    p_species_id uuid,
    p_campus_id uuid,
    p_latitude numeric,
    p_longitude numeric,
    p_is_founding_tree boolean DEFAULT false,
    p_date_added date DEFAULT NULL,
    p_landmark text DEFAULT NULL,
    p_relative_location text DEFAULT NULL,
    p_direction_note text DEFAULT NULL,
    p_identification_note text DEFAULT NULL,
    p_individual_note text DEFAULT NULL,
    p_campus_story text DEFAULT NULL,
    p_estimated_height_m numeric DEFAULT NULL,
    p_dbh_cm numeric DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_next integer;
    v_public_tree_id text;
BEGIN
    PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
    PERFORM pg_advisory_xact_lock(hashtext('P114_TREE_PUBLIC_ID')::bigint);

    SELECT coalesce(max(substring("PublicTreeId" from 2)::integer),0) + 1
      INTO v_next
      FROM public."TblP114Trees"
     WHERE "PublicTreeId" ~ '^T[0-9]{4}$';

    IF v_next > 9999 THEN
        RAISE EXCEPTION 'P114_TREE_ID_EXHAUSTED' USING ERRCODE='22003';
    END IF;

    v_public_tree_id := 'T' || lpad(v_next::text,4,'0');

    PERFORM public."P114_AdminCreateTree"(
        p_public_tree_id => v_public_tree_id,
        p_species_id => p_species_id,
        p_campus_id => p_campus_id,
        p_latitude => p_latitude,
        p_longitude => p_longitude,
        p_is_founding_tree => p_is_founding_tree,
        p_date_added => p_date_added,
        p_landmark => p_landmark,
        p_relative_location => p_relative_location,
        p_direction_note => p_direction_note,
        p_identification_note => p_identification_note,
        p_individual_note => p_individual_note,
        p_campus_story => p_campus_story,
        p_estimated_height_m => p_estimated_height_m,
        p_dbh_cm => p_dbh_cm
    );

    RETURN v_public_tree_id;
END;
$$;

REVOKE ALL ON FUNCTION public."P114_AdminCreateTreeAuto"(uuid,uuid,numeric,numeric,boolean,date,text,text,text,text,text,text,numeric,numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_AdminCreateTreeAuto"(uuid,uuid,numeric,numeric,boolean,date,text,text,text,text,text,text,numeric,numeric) FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminCreateTreeAuto"(uuid,uuid,numeric,numeric,boolean,date,text,text,text,text,text,text,numeric,numeric) TO authenticated;

COMMIT;