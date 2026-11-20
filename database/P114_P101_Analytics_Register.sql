-- P114 → P101 centralized analytics registration
-- SBI-P-SDS v3.7 controlled cross-project governance operation.
-- Run ONLY by an authorized P101 platform administrator in the P101 central Supabase SQL Editor.
-- Do NOT run as a P114 migration.

INSERT INTO p101_analytics."TblP101AnalyticsProjects"
    (project_code, canonical_origin, enabled)
VALUES
    ('P114', 'https://bagilu.github.io', true)
ON CONFLICT (project_code)
DO UPDATE SET
    canonical_origin = EXCLUDED.canonical_origin,
    enabled = EXCLUDED.enabled;
