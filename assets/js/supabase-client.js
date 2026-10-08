import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cfg = window.P114_CONFIG || {};
const ready = Boolean(cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY);

export const isConfigured = ready;

export const supabase = ready
  ? createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY, {
      auth: {
        storageKey: "P114-auth",
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true
      }
    })
  : null;

export function requireSupabaseConfig() {
  if (!supabase) {
    throw new Error("P114_CONFIG_MISSING");
  }
  return supabase;
}