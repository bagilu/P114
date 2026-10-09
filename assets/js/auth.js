import { requireSupabaseConfig } from "./supabase-client.js";

export async function getSession() {
  const s = requireSupabaseConfig();
  const { data, error } = await s.auth.getSession();
  if (error) throw error;
  return data.session;
}

export async function getCurrentUser() {
  const session = await getSession();
  return session?.user || null;
}

export async function signIn(email, password) {
  const s = requireSupabaseConfig();
  const { data, error } = await s.auth.signInWithPassword({ email, password });
  if (error) throw error;

  // Re-read the session so UI state is based on persisted P114-auth state.
  const { data: sessionData, error: sessionError } = await s.auth.getSession();
  if (sessionError) throw sessionError;
  if (!sessionData?.session) throw new Error("P114_LOGIN_SESSION_NOT_PERSISTED");

  return sessionData.session;
}

export async function signOut() {
  const s = requireSupabaseConfig();
  const { error } = await s.auth.signOut();
  if (error) throw error;
}

export function onAuthStateChange(callback) {
  const s = requireSupabaseConfig();
  const { data } = s.auth.onAuthStateChange((_event, session) => callback(session));
  return () => data?.subscription?.unsubscribe?.();
}
