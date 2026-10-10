-- P114｜我們的樹 MyTreeMyRoot
-- 010_P114_AutoMemberProvisioning.sql
-- Any authenticated Shared Auth user who enters P114 receives member access automatically.
-- Existing active editor/admin roles are preserved. Intentionally inactive local-role records are not reactivated.

BEGIN;

CREATE OR REPLACE FUNCTION public."P114_EnsureMemberAccess"()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_uid uuid;
    v_has_any_role boolean;
    v_has_active_role boolean;
    v_profile_id uuid;
BEGIN
    v_uid := public."P114_RequireAuth"();

    SELECT EXISTS(
        SELECT 1 FROM public."TblP114ProjectRoles" WHERE "AuthUserId" = v_uid
    ) INTO v_has_any_role;

    SELECT EXISTS(
        SELECT 1 FROM public."TblP114ProjectRoles"
        WHERE "AuthUserId" = v_uid AND "IsActive" = true
    ) INTO v_has_active_role;

    IF v_has_active_role THEN
        SELECT "Id" INTO v_profile_id
        FROM public."TblP114UserProfiles"
        WHERE "AuthUserId" = v_uid;

        IF v_profile_id IS NULL THEN
            INSERT INTO public."TblP114UserProfiles" ("AuthUserId","DisplayName","Status")
            VALUES (v_uid,NULL,'active')
            RETURNING "Id" INTO v_profile_id;
        END IF;

        RETURN 'already_authorized';
    END IF;

    IF v_has_any_role THEN
        RAISE EXCEPTION 'P114_ACCESS_SUSPENDED' USING ERRCODE = '42501';
    END IF;

    INSERT INTO public."TblP114ProjectRoles" ("AuthUserId","RoleCode","IsActive","GrantedAt","GrantedBy")
    VALUES (v_uid,'member',true,now(),NULL);

    SELECT "Id" INTO v_profile_id
    FROM public."TblP114UserProfiles"
    WHERE "AuthUserId" = v_uid;

    IF v_profile_id IS NULL THEN
        INSERT INTO public."TblP114UserProfiles" ("AuthUserId","DisplayName","Status")
        VALUES (v_uid,NULL,'active')
        RETURNING "Id" INTO v_profile_id;
    END IF;

    RETURN 'member_created';
END;
$$;

REVOKE ALL ON FUNCTION public."P114_EnsureMemberAccess"() FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_EnsureMemberAccess"() FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_EnsureMemberAccess"() TO authenticated;

COMMENT ON FUNCTION public."P114_EnsureMemberAccess"() IS
'Auto-provisions the P114 member role for a newly authenticated Shared Auth user. Preserves existing active roles and does not reactivate deliberately inactive P114 roles.';

COMMIT;