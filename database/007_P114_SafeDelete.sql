-- P114｜我們的樹 MyTreeMyRoot
-- 007_P114_SafeDelete.sql
-- Safe cleanup for duplicated Institution / Campus records.
-- Destructive delete is allowed only when the record is not referenced.

BEGIN;

CREATE OR REPLACE FUNCTION public."P114_AdminDeleteInstitution"(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_refs int;
BEGIN
    PERFORM public."P114_RequireLocalRole"(ARRAY['admin']::text[]);

    SELECT count(*)::int
      INTO v_refs
      FROM public."TblP114Campuses"
     WHERE "InstitutionId" = p_id;

    IF v_refs > 0 THEN
        RAISE EXCEPTION 'P114_INSTITUTION_IN_USE:%', v_refs
            USING ERRCODE = '23503';
    END IF;

    DELETE FROM public."TblP114Institutions"
     WHERE "Id" = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'P114_INSTITUTION_NOT_FOUND'
            USING ERRCODE = 'P0002';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminDeleteCampus"(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_refs int;
BEGIN
    PERFORM public."P114_RequireLocalRole"(ARRAY['admin']::text[]);

    SELECT count(*)::int
      INTO v_refs
      FROM public."TblP114Trees"
     WHERE "CampusId" = p_id;

    IF v_refs > 0 THEN
        RAISE EXCEPTION 'P114_CAMPUS_IN_USE:%', v_refs
            USING ERRCODE = '23503';
    END IF;

    DELETE FROM public."TblP114Campuses"
     WHERE "Id" = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'P114_CAMPUS_NOT_FOUND'
            USING ERRCODE = 'P0002';
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public."P114_AdminDeleteInstitution"(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_AdminDeleteInstitution"(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminDeleteInstitution"(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public."P114_AdminDeleteCampus"(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_AdminDeleteCampus"(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminDeleteCampus"(uuid) TO authenticated;

COMMENT ON FUNCTION public."P114_AdminDeleteInstitution"(uuid) IS
'Admin-only safe delete. Refuses deletion while any P114 Campus references the Institution.';

COMMENT ON FUNCTION public."P114_AdminDeleteCampus"(uuid) IS
'Admin-only safe delete. Refuses deletion while any P114 Tree references the Campus.';

COMMIT;
