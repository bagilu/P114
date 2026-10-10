-- P114 V0.016 Founding Trees curation
BEGIN;

CREATE OR REPLACE FUNCTION public."P114_AdminSetFoundingTree"(
    p_public_tree_id text,
    p_is_founding_tree boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid uuid;
BEGIN
    v_uid := public."P114_RequireLocalRole"(ARRAY['editor','admin']::text[]);

    UPDATE public."TblP114Trees"
       SET "IsFoundingTree" = coalesce(p_is_founding_tree,false),
           "UpdatedAt" = now()
     WHERE "PublicTreeId" = upper(trim(p_public_tree_id));

    IF NOT FOUND THEN
        RAISE EXCEPTION 'P114_TREE_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public."P114_AdminSetFoundingTree"(text,boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public."P114_AdminSetFoundingTree"(text,boolean) FROM anon;
GRANT EXECUTE ON FUNCTION public."P114_AdminSetFoundingTree"(text,boolean) TO authenticated;

COMMENT ON FUNCTION public."P114_AdminSetFoundingTree"(text,boolean) IS
'P114 editor/admin curation toggle for the Founding Trees collection.';

COMMIT;