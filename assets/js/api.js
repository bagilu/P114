import { requireSupabaseConfig } from "./supabase-client.js";

async function rpc(name, args = {}) {
  const supabase = requireSupabaseConfig();
  const { data, error } = await supabase.rpc(name, args);
  if (error) throw error;
  return data;
}

export const api = {
  getFoundingTrees: async (limit = 6) => {
    const supabase = requireSupabaseConfig();
    const { data, error } = await supabase
      .from("VwP114FoundingTrees")
      .select("*")
      .limit(limit);
    if (error) throw error;
    return data || [];
  },

  getPublicTrees: async (campusId = null) => {
    const supabase = requireSupabaseConfig();
    let q = supabase.from("VwP114PublicTrees").select("*");
    if (campusId) q = q.eq("CampusId", campusId);
    const { data, error } = await q.order("PublicTreeId");
    if (error) throw error;
    return data || [];
  },

  getCampuses: async () => {
    const supabase = requireSupabaseConfig();
    const { data, error } = await supabase
      .from("VwP114PublicCampuses")
      .select("*")
      .order("NameZh");
    if (error) throw error;
    return data || [];
  },

  searchTrees: (query, campusId = null, limit = 20) =>
    rpc("P114_SearchTrees", {
      p_query: query,
      p_campus_id: campusId,
      p_limit: limit
    }),

  getTreeProfile: (treeId) =>
    rpc("P114_GetTreeProfile", { p_public_tree_id: treeId }),

  getNearbyTrees: (lat, lon, radiusM = 500, limit = 30) =>
    rpc("P114_GetNearbyTrees", {
      p_latitude: lat,
      p_longitude: lon,
      p_radius_m: radiusM,
      p_limit: limit
    }),

  getTreeMonthlyPhotos: (treeId, year) =>
    rpc("P114_GetTreeMonthlyPhotos", {
      p_public_tree_id: treeId,
      p_year: year
    }),

  getTreeStories: (treeId, limit = 10) =>
    rpc("P114_GetTreeStories", {
      p_public_tree_id: treeId,
      p_limit: limit,
      p_featured_first: true
    }),

  getMyGuardianTree: () => rpc("P114_GetMyGuardianTree"),
  getMyTreeLanguage: (treeId) =>
    rpc("P114_GetMyTreeLanguage", { p_public_tree_id: treeId }),

  setGuardianTree: (treeId, year = new Date().getFullYear()) =>
    rpc("P114_SetGuardianTree", {
      p_public_tree_id: treeId,
      p_year: year
    }),

  setTreeLanguage: (treeId, optionIds, freeText) =>
    rpc("P114_SetTreeLanguage", {
      p_public_tree_id: treeId,
      p_option_ids: optionIds,
      p_free_text: freeText || null
    }),

  submitStory: (treeId, title, content, identityMode = "nickname") =>
    rpc("P114_SubmitTreeStory", {
      p_public_tree_id: treeId,
      p_title: title,
      p_content: content,
      p_public_identity_mode: identityMode
    }),

  recordVisit: (treeId, lat = null, lon = null) =>
    rpc("P114_RecordTreeVisit", {
      p_public_tree_id: treeId,
      p_latitude: lat,
      p_longitude: lon
    }),

  adminGetDashboardSummary: () => rpc("P114_AdminGetDashboardSummary"),
  adminGetPendingPhotos: (limit = 100) =>
    rpc("P114_AdminGetPendingPhotos", { p_limit: limit }),
  adminGetPendingStories: (limit = 100) =>
    rpc("P114_AdminGetPendingStories", { p_limit: limit })
};