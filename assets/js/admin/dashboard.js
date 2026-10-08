import { api } from "../api.js";
import { qs, setState, hide, escapeHtml } from "../ui.js";
import { friendlyError } from "../errors.js";
import { getSession } from "../auth.js";

(async () => {
  const state = qs("#admin-state");
  const grid = qs("#admin-grid");
  try {
    const session = await getSession();
    if (!session) {
      location.href = "../login.html?returnTo=" + encodeURIComponent(location.href);
      return;
    }
    const d = await api.adminGetDashboardSummary();
    const items = [
      ["Active Trees", d?.activeTrees],
      ["Founding Trees", d?.foundingTrees],
      ["Pending Photos", d?.pendingPhotos],
      ["Pending Stories", d?.pendingStories],
      ["Current Guardians", d?.currentGuardians],
      ["Tree Language", d?.treeLanguageResponses],
      ["Visits", d?.visits]
    ];
    grid.innerHTML = items.map(([k,v]) => `<div class="card"><div class="meta">${escapeHtml(k)}</div><div style="font-size:2rem;font-weight:800">${Number(v || 0)}</div></div>`).join("");
    hide(state); grid.hidden = false;
  } catch (err) {
    setState(state, friendlyError(err), "error");
  }
})();