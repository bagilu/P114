import { api } from "../api.js";
import { publicMediaUrl } from "../storage.js";
import { treeCardHtml, qs, setState, hide, footerHtml, escapeHtml } from "../ui.js";
import { friendlyError } from "../errors.js";

qs("#footer").innerHTML = footerHtml();
const form = qs("#search-form");
const state = qs("#search-state");
const grid = qs("#search-grid");
const campus = qs("#campus");

(async () => {
  try {
    const campuses = await api.getCampuses();
    campus.insertAdjacentHTML("beforeend", campuses.map(c =>
      `<option value="${escapeHtml(c.CampusId || c.Id || "")}">${escapeHtml(c.NameZh || "")}</option>`
    ).join(""));
  } catch {}
})();

form.addEventListener("submit", async e => {
  e.preventDefault();
  const q = qs("#q").value.trim();
  if (!q) return setState(state, "請輸入搜尋關鍵字。");
  grid.hidden = true;
  setState(state, "搜尋中…");
  try {
    const rows = await api.searchTrees(q, campus.value || null, 20);
    if (!rows?.length) return setState(state, "沒有找到符合的樹。");
    grid.innerHTML = rows.map(t => treeCardHtml(t, t.HeroPhotoPath ? publicMediaUrl(t.HeroPhotoPath) : null)).join("");
    hide(state);
    grid.hidden = false;
  } catch (err) {
    setState(state, friendlyError(err), "error");
  }
});