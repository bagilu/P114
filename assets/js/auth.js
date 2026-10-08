import { requireSupabaseConfig } from "./supabase-client.js";

export async function getSession() {
  const supabase = requireSupabaseConfig();
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  return data.session;
}

export async function signIn(email, password) {
  const supabase = requireSupabaseConfig();
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const supabase = requireSupabaseConfig();
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function requireLogin(returnTo = location.href) {
  const session = await getSession();
  if (!session) {
    location.href = `login.html?returnTo=${encodeURIComponent(returnTo)}`;
    return null;
  }
  return session;
}