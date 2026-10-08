import { requireSupabaseConfig } from "./supabase-client.js";

function extFromFile(file) {
  const parts = (file.name || "").split(".");
  return parts.length > 1 ? parts.pop().toLowerCase() : "jpg";
}

export async function uploadCommunityPhoto({ treeId, userId, file, takenAt }) {
  const supabase = requireSupabaseConfig();
  const d = new Date(takenAt);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const safeName = `${crypto.randomUUID()}.${extFromFile(file)}`;
  const path = `trees/${treeId}/community/${year}/${month}/${userId}/${safeName}`;

  const { error } = await supabase.storage
    .from("P114TreeMedia")
    .upload(path, file, { upsert: false });

  if (error) throw error;
  return path;
}

export function publicMediaUrl(filePath) {
  if (!filePath) return null;
  const supabase = requireSupabaseConfig();
  return supabase.storage.from("P114TreeMedia").getPublicUrl(filePath).data.publicUrl;
}