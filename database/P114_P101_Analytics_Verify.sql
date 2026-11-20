-- P114 → P101 centralized analytics registration verification
-- Read-only. Run in the P101 central Supabase project after registration.

SELECT project_code, canonical_origin, enabled
FROM p101_analytics."TblP101AnalyticsProjects"
WHERE project_code = 'P114';
