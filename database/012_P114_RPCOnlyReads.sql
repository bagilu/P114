-- P114｜我們的樹 MyTreeMyRoot
-- 012_P114_RPCOnlyReads.sql
-- SDS v3.7 migration: frontend read paths move from direct Table/View access to P114 RPCs.
-- Existing table/view grants are intentionally not broadly changed in this migration;
-- endpoint exposure must be validated in HealthCheck before revoking production grants.

BEGIN;

CREATE OR REPLACE FUNCTION public."P114_ListFoundingTrees"(p_limit integer DEFAULT 6)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY v."PublicTreeId"), '[]'::jsonb)
  FROM (
    SELECT *
    FROM public."VwP114FoundingTrees"
    ORDER BY "PublicTreeId"
    LIMIT greatest(1, least(coalesce(p_limit,6),100))
  ) v;
$$;

CREATE OR REPLACE FUNCTION public."P114_ListPublicTrees"(p_campus_id uuid DEFAULT NULL)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY v."PublicTreeId"), '[]'::jsonb)
  FROM public."VwP114PublicTrees" v
  WHERE p_campus_id IS NULL OR v."CampusId" = p_campus_id;
$$;

CREATE OR REPLACE FUNCTION public."P114_ListPublicCampuses"()
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT coalesce(
    jsonb_agg(jsonb_build_object('CampusId',x."CampusId",'NameZh',x."CampusNameZh") ORDER BY x."CampusNameZh"),
    '[]'::jsonb
  )
  FROM (
    SELECT DISTINCT "CampusId","CampusNameZh"
    FROM public."VwP114PublicTrees"
    WHERE "CampusId" IS NOT NULL
  ) x;
$$;

CREATE OR REPLACE FUNCTION public."P114_GetOwnProfileSummary"()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_uid uuid; v_result jsonb;
BEGIN
  v_uid := public."P114_RequireAuth"();
  SELECT jsonb_build_object(
    'Id',"Id",'DisplayName',"DisplayName",'Nickname',"Nickname",'Status',"Status"
  )
  INTO v_result
  FROM public."TblP114UserProfiles"
  WHERE "AuthUserId" = v_uid;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_GetOwnRoles"()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_uid uuid;
BEGIN
  v_uid := public."P114_RequireAuth"();
  RETURN (
    SELECT coalesce(jsonb_agg(jsonb_build_object('RoleCode',"RoleCode",'IsActive',"IsActive") ORDER BY "RoleCode"),'[]'::jsonb)
    FROM public."TblP114ProjectRoles"
    WHERE "AuthUserId"=v_uid AND "IsActive"=true
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_GetProjectAccess"()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_uid uuid; v_roles text[];
BEGIN
  v_uid := public."P114_RequireAuth"();
  PERFORM public."P114_EnsureMemberAccess"();
  SELECT coalesce(array_agg("RoleCode" ORDER BY "RoleCode"),ARRAY[]::text[])
    INTO v_roles
  FROM public."TblP114ProjectRoles"
  WHERE "AuthUserId"=v_uid AND "IsActive"=true;
  RETURN jsonb_build_object(
    'authenticated',true,
    'authorized',v_roles && ARRAY['member','editor','admin']::text[],
    'roles',to_jsonb(v_roles),
    'canAdmin',v_roles && ARRAY['editor','admin']::text[]
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_GetMyPhotos"()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_uid uuid;
BEGIN
  v_uid := public."P114_RequireAuth"();
  RETURN (
    SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY p."SubmittedAt" DESC),'[]'::jsonb)
    FROM public."TblP114TreePhotos" p
    WHERE p."AuthUserId"=v_uid AND p."DeletedAt" IS NULL
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_GetMyStories"()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_uid uuid;
BEGIN
  v_uid := public."P114_RequireAuth"();
  RETURN (
    SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY s."SubmittedAt" DESC),'[]'::jsonb)
    FROM public."TblP114TreeStories" s
    WHERE s."AuthUserId"=v_uid AND s."DeletedAt" IS NULL
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_GetMyVisits"(p_limit integer DEFAULT 50)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_uid uuid;
BEGIN
  v_uid := public."P114_RequireAuth"();
  RETURN (
    SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY v."VisitedAt" DESC),'[]'::jsonb)
    FROM (
      SELECT *
      FROM public."TblP114TreeVisits"
      WHERE "AuthUserId"=v_uid
      ORDER BY "VisitedAt" DESC
      LIMIT greatest(1,least(coalesce(p_limit,50),200))
    ) v
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListInstitutions"()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x."NameZh"),'[]'::jsonb) FROM public."TblP114Institutions" x);
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListCampuses"()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x."NameZh"),'[]'::jsonb) FROM public."TblP114Campuses" x);
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListSpecies"()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x."CommonNameZh",x."ScientificName"),'[]'::jsonb) FROM public."TblP114TreeSpecies" x);
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListTrees"()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (
    SELECT coalesce(jsonb_agg(
      to_jsonb(t)
      || jsonb_build_object('TblP114TreeSpecies',
        CASE WHEN s."Id" IS NULL THEN NULL ELSE jsonb_build_object(
          'Id',s."Id",'ScientificName',s."ScientificName",'CommonNameZh',s."CommonNameZh",'CommonNameEn',s."CommonNameEn"
        ) END)
      || jsonb_build_object('TblP114Campuses',
        CASE WHEN c."Id" IS NULL THEN NULL ELSE jsonb_build_object(
          'Id',c."Id",'NameZh',c."NameZh",'NameEn',c."NameEn"
        ) END)
      ORDER BY t."PublicTreeId"
    ),'[]'::jsonb)
    FROM public."TblP114Trees" t
    LEFT JOIN public."TblP114TreeSpecies" s ON s."Id"=t."SpeciesId"
    LEFT JOIN public."TblP114Campuses" c ON c."Id"=t."CampusId"
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListTreeMedia"(p_tree_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x."SortOrder"),'[]'::jsonb) FROM public."TblP114TreeMedia" x WHERE x."TreeId"=p_tree_id);
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListObservationPoints"(p_tree_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (
    SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x."IsPrimary" DESC,x."Name"),'[]'::jsonb)
    FROM public."TblP114ObservationPoints" x WHERE x."TreeId"=p_tree_id
  );
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_AdminListTreeLanguageOptions"()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);
  RETURN (SELECT coalesce(jsonb_agg(to_jsonb(x) ORDER BY x."SortOrder"),'[]'::jsonb) FROM public."TblP114TreeLanguageOptions" x);
END;
$$;

REVOKE ALL ON FUNCTION public."P114_ListFoundingTrees"(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public."P114_ListFoundingTrees"(integer) TO anon, authenticated;
REVOKE ALL ON FUNCTION public."P114_ListPublicTrees"(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public."P114_ListPublicTrees"(uuid) TO anon, authenticated;
REVOKE ALL ON FUNCTION public."P114_ListPublicCampuses"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public."P114_ListPublicCampuses"() TO anon, authenticated;

REVOKE ALL ON FUNCTION public."P114_GetOwnProfileSummary"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_GetOwnProfileSummary"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_GetOwnRoles"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_GetOwnRoles"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_GetProjectAccess"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_GetProjectAccess"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_GetMyPhotos"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_GetMyPhotos"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_GetMyStories"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_GetMyStories"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_GetMyVisits"(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_GetMyVisits"(integer) TO authenticated;

REVOKE ALL ON FUNCTION public."P114_AdminListInstitutions"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListInstitutions"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminListCampuses"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListCampuses"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminListSpecies"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListSpecies"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminListTrees"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListTrees"() TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminListTreeMedia"(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListTreeMedia"(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminListObservationPoints"(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListObservationPoints"(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public."P114_AdminListTreeLanguageOptions"() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminListTreeLanguageOptions"() TO authenticated;

COMMIT;
