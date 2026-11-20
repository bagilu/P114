# P114 SDS v3.7 Alignment Report — V0.021

Date: 2026-11-20  
Project: P114｜我們的樹 — MyTreeMyRoot  
Target standard: SBI-P-SDS v3.7

## Current status

- PASS — Web Version updated to V0.021 and HTML cache-busting aligned.
- PASS — 「好玩實驗室」 shared footer identity links to https://tcubmdsbilab.github.io/P101/.
- PASS — P101 centralized analytics loader added once to index.html with data-project="P114".
- PASS — Analytics/privacy explanation page added and linked from the shared footer.
- PASS — Tree Management adds writing hints for relative location, direction, identification, individual features, and campus story.
- PASS — DBH guidance states measurement at 1.3 m above ground.
- REVIEW — `database/012_P114_RPCOnlyReads.sql` is committed but must be executed before the live frontend can safely switch from direct Table/View reads to RPC-only.
- REVIEW — Table/View Data API exposure and grants have not been revoked in 012; endpoint-level hardening must be validated separately before QA-02/04 are considered fully passing.
- REVIEW — P101 central registration SQL and read-only verification SQL are committed, but execution in the P101 central Supabase project and end-to-end analytics verification are still required.
- REVIEW — Existing production `config.js` remains intentionally untouched. Repository/ZIP handling must be checked against SDS QA-12 before final compliance claim.
- REVIEW — SECURITY DEFINER functions in the existing project require role, search_path, least-data, and allow/deny review under SDS v3.7 DB-09.

## Files added / prepared

- `database/012_P114_RPCOnlyReads.sql`
- `database/P114_P101_Analytics_Register.sql`
- `database/P114_P101_Analytics_Verify.sql`
- `privacy.html`

## Compliance claim

P114 must NOT yet claim full SBI-P-SDS v3.7 compliance. The shared footer intentionally does not display the SDS v3.7 badge until the migration and runtime/permission checks above are completed.
