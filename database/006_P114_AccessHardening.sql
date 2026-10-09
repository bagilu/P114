-- P114｜我們的樹 MyTreeMyRoot
-- 006_P114_AccessHardening.sql
-- Purpose: separate shared Auth identity from P114 project authorization.
-- Safe migration: P114 objects only; no cross-project schema assumptions.
--
-- Policy after this migration:
--   1) auth.users answers WHO the person is.
--   2) active TblP114ProjectRoles answers whether they may use P114 member writes.
--   3) P114_EnsureProfile creates only the P114-local profile; it never grants a role.
--   4) member writes require one active local role: member/editor/admin.

BEGIN;

CREATE OR REPLACE FUNCTION public."P114_EnsureProfile"()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_profile_id uuid;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['member','editor','admin']::text[]);

    SELECT "Id"
      INTO v_profile_id
      FROM public."TblP114UserProfiles"
     WHERE "AuthUserId" = v_uid;

    IF v_profile_id IS NOT NULL THEN
        RETURN v_profile_id;
    END IF;

    INSERT INTO public."TblP114UserProfiles"
        ("AuthUserId", "DisplayName", "Status")
    VALUES
        (v_uid, NULL, 'active')
    RETURNING "Id" INTO v_profile_id;

    RETURN v_profile_id;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_SubmitTreePhoto"(
    p_public_tree_id text,
    p_photo_type text,
    p_file_path text,
    p_taken_at timestamptz,
    p_caption text DEFAULT NULL,
    p_observation_point_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_tree_id uuid;
    v_photo_id uuid;
    v_year int;
    v_month int;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['member','editor','admin']::text[]);
    PERFORM public."P114_EnsureProfile"();

    IF p_photo_type NOT IN ('community','scientific') THEN
        RAISE EXCEPTION 'P114_INVALID_PHOTO_TYPE' USING ERRCODE = '22023';
    END IF;

    IF p_file_path IS NULL OR trim(p_file_path) = '' THEN
        RAISE EXCEPTION 'P114_FILE_PATH_REQUIRED' USING ERRCODE = '22023';
    END IF;

    IF p_taken_at IS NULL THEN
        RAISE EXCEPTION 'P114_TAKEN_AT_REQUIRED' USING ERRCODE = '22023';
    END IF;

    SELECT "Id" INTO v_tree_id
    FROM public."TblP114Trees"
    WHERE "PublicTreeId" = upper(trim(p_public_tree_id))
      AND "Status" = 'active';

    IF v_tree_id IS NULL THEN
        RAISE EXCEPTION 'P114_TREE_NOT_FOUND_OR_INACTIVE' USING ERRCODE = 'P0002';
    END IF;

    IF p_photo_type = 'scientific'
       AND NOT public."P114_HasLocalRole"(ARRAY['editor','admin']::text[]) THEN
        RAISE EXCEPTION 'P114_SCIENTIFIC_PHOTO_STAFF_ONLY' USING ERRCODE = '42501';
    END IF;

    IF p_observation_point_id IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM public."TblP114ObservationPoints" op
        WHERE op."Id" = p_observation_point_id
          AND op."TreeId" = v_tree_id
    ) THEN
        RAISE EXCEPTION 'P114_INVALID_OBSERVATION_POINT' USING ERRCODE = '22023';
    END IF;

    v_year := extract(year from p_taken_at)::int;
    v_month := extract(month from p_taken_at)::int;

    BEGIN
        INSERT INTO public."TblP114TreePhotos" (
            "TreeId","AuthUserId","ObservationPointId","PhotoType","FilePath",
            "TakenAt","RecordYear","RecordMonth","Caption",
            "ReviewStatus","IsMonthlyRepresentative","IsScientificallyValuable"
        )
        VALUES (
            v_tree_id,v_uid,p_observation_point_id,p_photo_type,trim(p_file_path),
            p_taken_at,v_year,v_month,nullif(trim(coalesce(p_caption,'')),''),
            'pending',false,false
        )
        RETURNING "Id" INTO v_photo_id;
    EXCEPTION
        WHEN unique_violation THEN
            IF p_photo_type = 'community' THEN
                RAISE EXCEPTION 'P114_COMMUNITY_PHOTO_ALREADY_SUBMITTED_FOR_MONTH' USING ERRCODE = '23505';
            ELSE
                RAISE;
            END IF;
    END;

    RETURN v_photo_id;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_SubmitTreeStory"(
    p_public_tree_id text,
    p_title text,
    p_content text,
    p_public_identity_mode text DEFAULT 'nickname'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_tree_id uuid;
    v_story_id uuid;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['member','editor','admin']::text[]);
    PERFORM public."P114_EnsureProfile"();

    IF p_public_identity_mode NOT IN ('nickname','anonymous') THEN
        RAISE EXCEPTION 'P114_INVALID_IDENTITY_MODE' USING ERRCODE = '22023';
    END IF;

    IF length(trim(coalesce(p_title,''))) < 1 OR length(trim(coalesce(p_title,''))) > 150 THEN
        RAISE EXCEPTION 'P114_INVALID_STORY_TITLE' USING ERRCODE = '22023';
    END IF;

    IF length(trim(coalesce(p_content,''))) < 1 THEN
        RAISE EXCEPTION 'P114_STORY_CONTENT_REQUIRED' USING ERRCODE = '22023';
    END IF;

    SELECT "Id" INTO v_tree_id
    FROM public."TblP114Trees"
    WHERE "PublicTreeId" = upper(trim(p_public_tree_id))
      AND "Status" IN ('active','dead','removed');

    IF v_tree_id IS NULL THEN
        RAISE EXCEPTION 'P114_TREE_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    INSERT INTO public."TblP114TreeStories" (
        "TreeId","AuthUserId","Title","Content","PublicIdentityMode","ReviewStatus"
    )
    VALUES (
        v_tree_id,v_uid,trim(p_title),trim(p_content),p_public_identity_mode,'pending'
    )
    RETURNING "Id" INTO v_story_id;

    RETURN v_story_id;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_SetTreeLanguage"(
    p_public_tree_id text,
    p_option_ids uuid[] DEFAULT ARRAY[]::uuid[],
    p_free_text text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_tree_id uuid;
    v_response_id uuid;
    v_valid_count int;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['member','editor','admin']::text[]);
    PERFORM public."P114_EnsureProfile"();

    SELECT "Id" INTO v_tree_id
    FROM public."TblP114Trees"
    WHERE "PublicTreeId" = upper(trim(p_public_tree_id))
      AND "Status" IN ('active','dead','removed');

    IF v_tree_id IS NULL THEN
        RAISE EXCEPTION 'P114_TREE_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    IF cardinality(p_option_ids) > 3 THEN
        RAISE EXCEPTION 'P114_TREE_LANGUAGE_MAX_3_OPTIONS' USING ERRCODE = '22023';
    END IF;

    IF length(coalesce(p_free_text,'')) > 300 THEN
        RAISE EXCEPTION 'P114_TREE_LANGUAGE_TEXT_TOO_LONG' USING ERRCODE = '22023';
    END IF;

    SELECT count(*)::int INTO v_valid_count
    FROM public."TblP114TreeLanguageOptions"
    WHERE "TreeId" = v_tree_id
      AND "Active" = true
      AND "Id" = ANY(coalesce(p_option_ids, ARRAY[]::uuid[]));

    IF v_valid_count <> cardinality(coalesce(p_option_ids, ARRAY[]::uuid[])) THEN
        RAISE EXCEPTION 'P114_INVALID_TREE_LANGUAGE_OPTION' USING ERRCODE = '22023';
    END IF;

    INSERT INTO public."TblP114TreeLanguageResponses" ("TreeId","AuthUserId","FreeText")
    VALUES (v_tree_id,v_uid,nullif(trim(coalesce(p_free_text,'')),''))
    ON CONFLICT ("TreeId","AuthUserId")
    DO UPDATE SET "FreeText" = EXCLUDED."FreeText", "UpdatedAt" = now()
    RETURNING "Id" INTO v_response_id;

    DELETE FROM public."TblP114TreeLanguageResponseItems"
    WHERE "ResponseId" = v_response_id;

    INSERT INTO public."TblP114TreeLanguageResponseItems" ("ResponseId","OptionId")
    SELECT v_response_id, x
    FROM unnest(coalesce(p_option_ids, ARRAY[]::uuid[])) AS x;

    RETURN v_response_id;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_SetGuardianTree"(
    p_public_tree_id text,
    p_year integer DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_tree_id uuid;
    v_year int;
    v_history_id uuid;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['member','editor','admin']::text[]);
    PERFORM public."P114_EnsureProfile"();

    v_year := coalesce(p_year, extract(year from current_date)::int);

    IF v_year < 2000 OR v_year > 2200 THEN
        RAISE EXCEPTION 'P114_INVALID_GUARDIAN_YEAR' USING ERRCODE = '22023';
    END IF;

    SELECT "Id" INTO v_tree_id
    FROM public."TblP114Trees"
    WHERE "PublicTreeId" = upper(trim(p_public_tree_id))
      AND "Status" = 'active';

    IF v_tree_id IS NULL THEN
        RAISE EXCEPTION 'P114_TREE_NOT_FOUND_OR_INACTIVE' USING ERRCODE = 'P0002';
    END IF;

    UPDATE public."TblP114GuardianTreeHistory"
    SET "IsCurrent" = false, "EndedAt" = COALESCE("EndedAt", current_date)
    WHERE "AuthUserId" = v_uid AND "IsCurrent" = true AND "Year" <> v_year;

    INSERT INTO public."TblP114GuardianTreeHistory" (
        "AuthUserId","TreeId","Year","StartedAt","EndedAt","IsCurrent"
    )
    VALUES (v_uid,v_tree_id,v_year,current_date,NULL,true)
    ON CONFLICT ("AuthUserId","Year")
    DO UPDATE SET
        "TreeId" = EXCLUDED."TreeId",
        "StartedAt" = CASE
            WHEN public."TblP114GuardianTreeHistory"."TreeId" = EXCLUDED."TreeId"
            THEN public."TblP114GuardianTreeHistory"."StartedAt"
            ELSE current_date
        END,
        "EndedAt" = NULL,
        "IsCurrent" = true
    RETURNING "Id" INTO v_history_id;

    UPDATE public."TblP114GuardianTreeHistory"
    SET "IsCurrent" = false, "EndedAt" = COALESCE("EndedAt", current_date)
    WHERE "AuthUserId" = v_uid AND "Id" <> v_history_id AND "IsCurrent" = true;

    RETURN v_history_id;
END;
$$;

CREATE OR REPLACE FUNCTION public."P114_RecordTreeVisit"(
    p_public_tree_id text,
    p_latitude numeric DEFAULT NULL,
    p_longitude numeric DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_tree_id uuid;
    v_tree_lat numeric;
    v_tree_lon numeric;
    v_distance numeric;
    v_visit_id uuid;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['member','editor','admin']::text[]);
    PERFORM public."P114_EnsureProfile"();

    SELECT "Id","Latitude","Longitude"
      INTO v_tree_id,v_tree_lat,v_tree_lon
      FROM public."TblP114Trees"
     WHERE "PublicTreeId" = upper(trim(p_public_tree_id))
       AND "Status" IN ('active','dead','removed');

    IF v_tree_id IS NULL THEN
        RAISE EXCEPTION 'P114_TREE_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    IF (p_latitude IS NULL) <> (p_longitude IS NULL) THEN
        RAISE EXCEPTION 'P114_VISIT_LOCATION_REQUIRES_BOTH_LAT_LON' USING ERRCODE = '22023';
    END IF;

    IF p_latitude IS NOT NULL THEN
        IF p_latitude < -90 OR p_latitude > 90 OR p_longitude < -180 OR p_longitude > 180 THEN
            RAISE EXCEPTION 'P114_INVALID_VISIT_COORDINATE' USING ERRCODE = '22023';
        END IF;

        v_distance := 6371000.0 * 2 * asin(
            sqrt(
                power(sin(radians((v_tree_lat - p_latitude) / 2.0)), 2)
                + cos(radians(p_latitude)) * cos(radians(v_tree_lat))
                * power(sin(radians((v_tree_lon - p_longitude) / 2.0)), 2)
            )
        );
    END IF;

    INSERT INTO public."TblP114TreeVisits" (
        "AuthUserId","TreeId","Latitude","Longitude","DistanceToTreeM"
    )
    VALUES (v_uid,v_tree_id,p_latitude,p_longitude,v_distance)
    RETURNING "Id" INTO v_visit_id;

    RETURN v_visit_id;
END;
$$;

COMMENT ON FUNCTION public."P114_EnsureProfile"() IS
'Creates the P114-local profile only for an already-authorized P114 member/editor/admin. Never grants a P114 role.';

DO $$
DECLARE
    v_def text;
BEGIN
    SELECT pg_get_functiondef('public."P114_EnsureProfile"()'::regprocedure) INTO v_def;
    IF v_def ILIKE '%INSERT INTO public."TblP114ProjectRoles"%' THEN
        RAISE EXCEPTION 'P114_ACCESS_HARDENING_FAILED: EnsureProfile still grants role';
    END IF;
    IF v_def NOT ILIKE '%P114_RequireLocalRole%' THEN
        RAISE EXCEPTION 'P114_ACCESS_HARDENING_FAILED: EnsureProfile lacks role gate';
    END IF;
END;
$$;

COMMIT;
