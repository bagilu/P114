import { api } from "../api.js";
import { publicMediaUrl } from "../storage.js";
import { treeCardHtml, qs, setState, hide, footerHtml, escapeHtml } from "../ui.js";
import { friendlyError } from "../errors.js";

qs("#footer").innerHTML = footerHtml();
const state = qs("#explore-state");
const grid = qs("#explore-grid");
const campus = qs("#campus");

async function renderTrees(campusId = null) {
  grid.hidden = true;
  setState(state, "正在載入樹木…");
  try {
    const trees = await api.getPublicTrees(campusId);
    if (!trees.length) return setState(state, "目前沒有可顯示的樹。");
    grid.innerHTML = trees.map(t => treeCardHtml(t, t.HeroPhotoPath ? publicMediaUrl(t.HeroPhotoPath) : null)).join("");
    hide(state); grid.hidden = false;
  } catch (err) {
    setState(state, friendlyError(err), "error");
  }
}

(async () => {
  try {
    const campuses = await api.getCampuses();
    campus.insertAdjacentHTML("beforeend", campuses.map(c =>
      `<option value="${escapeHtml(c.CampusId || c.Id || "")}">${escapeHtml(c.NameZh || "")}</option>`
    ).join(""));
  } catch {}
  renderTrees();
})();

campus.addEventListener("change", () => renderTrees(campus.value || null));

qs("#near-me").addEventListener("click", () => {
  if (!navigator.geolocation) return setState(state, "此瀏覽器不支援定位。", "error");
  setState(state, "正在取得位置…");
  navigator.geolocation.getCurrentPosition(async pos => {
    try {
      const rows = await api.getNearbyTrees(pos.coords.latitude, pos.coords.longitude, 500, 30);
      if (!rows?.length) return setState(state, "500 公尺內沒有找到候選樹。");
      grid.innerHTML = rows.map(t => {
        const html = treeCardHtml(t, t.HeroPhotoPath ? publicMediaUrl(t.HeroPhotoPath) : null);
        return html.replace('</div></a>', `<div class="meta" style="margin-top:8px">約 ${Math.round(Number(t.DistanceM || 0))} 公尺</div></div></a>`);
      }).join("");
      hide(state); grid.hidden = false;
    } catch (err) {
      setState(state, friendlyError(err), "error");
    }
  }, () => setState(state, "無法取得位置；你仍可用校區與地標找樹。", "error"), {
    enableHighAccuracy: false,
    timeout: 8000
  });
});