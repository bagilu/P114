-- P114 V0.015 duplicate merge migration
BEGIN;

CREATE OR REPLACE FUNCTION public."P114_AdminMergeInstitution"(p_source_id uuid, p_target_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE v_count integer;
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['admin']::text[]);
  IF p_source_id IS NULL OR p_target_id IS NULL OR p_source_id = p_target_id THEN
    RAISE EXCEPTION 'P114_INVALID_MERGE_TARGET' USING ERRCODE='22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public."TblP114Institutions" WHERE "Id"=p_source_id)
     OR NOT EXISTS (SELECT 1 FROM public."TblP114Institutions" WHERE "Id"=p_target_id) THEN
    RAISE EXCEPTION 'P114_INSTITUTION_NOT_FOUND' USING ERRCODE='P0002';
  END IF;
  UPDATE public."TblP114Campuses" SET "InstitutionId"=p_target_id WHERE "InstitutionId"=p_source_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  DELETE FROM public."TblP114Institutions" WHERE "Id"=p_source_id;
  RETURN v_count;
END; $$;

CREATE OR REPLACE FUNCTION public."P114_AdminMergeCampus"(p_source_id uuid, p_target_id uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE v_count integer;
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['admin']::text[]);
  IF p_source_id IS NULL OR p_target_id IS NULL OR p_source_id = p_target_id THEN
    RAISE EXCEPTION 'P114_INVALID_MERGE_TARGET' USING ERRCODE='22023';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public."TblP114Campuses" WHERE "Id"=p_source_id)
     OR NOT EXISTS (SELECT 1 FROM public."TblP114Campuses" WHERE "Id"=p_target_id) THEN
    RAISE EXCEPTION 'P114_CAMPUS_NOT_FOUND' USING ERRCODE='P0002';
  END IF;
  UPDATE public."TblP114Trees" SET "CampusId"=p_target_id WHERE "CampusId"=p_source_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  DELETE FROM public."TblP114Campuses" WHERE "Id"=p_source_id;
  RETURN v_count;
END; $$;

REVOKE ALL ON FUNCTION public."P114_AdminMergeInstitution"(uuid,uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_AdminMergeInstitution"(uuid,uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminMergeInstitution"(uuid,uuid) TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminMergeCampus"(uuid,uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_AdminMergeCampus"(uuid,uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminMergeCampus"(uuid,uuid) TO authenticated;
COMMIT;