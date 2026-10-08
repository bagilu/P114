import { api } from "../api.js";
import { publicMediaUrl } from "../storage.js";
import { qs, setState, hide, footerHtml, escapeHtml } from "../ui.js";
import { friendlyError } from "../errors.js";
import { getSession } from "../auth.js";

qs("#footer").innerHTML = footerHtml();
const params = new URLSearchParams(location.search);
const treeId = (params.get("id") || "").toUpperCase();
const valid = /^T\d{4}$/.test(treeId);
const treeState = qs("#tree-state");

function mediaByType(media, type) {
  return media?.find(m => m.mediaType === type || m.MediaType === type);
}

function value(obj, ...keys) {
  for (const k of keys) if (obj && obj[k] !== undefined && obj[k] !== null) return obj[k];
  return null;
}

function renderInfo(tree) {
  qs("#tree-id").textContent = value(tree, "PublicTreeId") || treeId;
  qs("#tree-name").textContent = value(tree, "CommonNameZh") || "未命名樹";
  qs("#tree-latin").textContent = value(tree, "ScientificName") || "";
  qs("#tree-location").textContent = [value(tree,"CampusNameZh"), value(tree,"Landmark")].filter(Boolean).join(" · ");
  qs("#tree-badges").innerHTML = value(tree,"IsFoundingTree") ? `<span class="badge">Founding Tree</span>` : "";

  const speciesRows = [
    ["中文名", value(tree,"CommonNameZh")],
    ["英文名", value(tree,"CommonNameEn")],
    ["學名", value(tree,"ScientificName")],
    ["科", value(tree,"FamilyZh") || value(tree,"FamilyScientific")],
    ["生活型", value(tree,"LifeForm")],
    ["來源", value(tree,"OriginStatus")]
  ].filter(([,v]) => v);
  qs("#species-info").innerHTML = speciesRows.map(([k,v]) => `<div><strong>${escapeHtml(k)}</strong>　${escapeHtml(v)}</div>`).join("");

  const individualRows = [
    ["Tree ID", value(tree,"PublicTreeId")],
    ["加入日期", value(tree,"DateAdded")],
    ["高度", value(tree,"EstimatedHeightM") ? `${value(tree,"EstimatedHeightM")} m` : null],
    ["DBH", value(tree,"DbhCm") ? `${value(tree,"DbhCm")} cm` : null],
    ["位置提示", value(tree,"RelativeLocation")],
    ["方向", value(tree,"DirectionNote")],
    ["個體特徵", value(tree,"IndividualNote")],
    ["校園故事", value(tree,"CampusStory")]
  ].filter(([,v]) => v);
  qs("#individual-info").innerHTML = individualRows.map(([k,v]) => `<div style="margin-bottom:8px"><strong>${escapeHtml(k)}</strong><br>${escapeHtml(v)}</div>`).join("");
}

function renderMedia(media) {
  const hero = mediaByType(media, "hero") || mediaByType(media, "whole_tree") || media?.[0];
  const heroPath = hero && (hero.filePath || hero.FilePath);
  qs("#tree-media").innerHTML = heroPath ? `<img src="${publicMediaUrl(heroPath)}" alt="樹木照片">` : "";

  const wanted = [
    ["location_signature","環境定位"],
    ["whole_tree","全樹"],
    ["trunk","樹幹／特徵"]
  ];
  qs("#confirm-photos").innerHTML = wanted.map(([type,label]) => {
    const m = mediaByType(media, type);
    const p = m && (m.filePath || m.FilePath);
    if (!p) return "";
    return `<figure><img src="${publicMediaUrl(p)}" alt="${label}"><figcaption>${label}</figcaption></figure>`;
  }).join("");
}

async function renderMonths() {
  const state = qs("#month-state");
  const grid = qs("#month-grid");
  try {
    const year = new Date().getFullYear();
    const rows = await api.getTreeMonthlyPhotos(treeId, year);
    const byMonth = new Map();
    for (const r of rows || []) {
      const m = Number(r.RecordMonth);
      if (!byMonth.has(m)) byMonth.set(m, []);
      byMonth.get(m).push(r);
    }
    grid.innerHTML = Array.from({length:12}, (_,i) => {
      const month = i + 1;
      const items = byMonth.get(month) || [];
      const img = items[0]?.FilePath ? `<img src="${publicMediaUrl(items[0].FilePath)}" alt="${month}月照片" style="width:100%;aspect-ratio:1/1;object-fit:cover;border-radius:10px">` : `<div class="meta">尚無代表照</div>`;
      return `<div class="month-cell"><strong>${month} 月</strong>${img}</div>`;
    }).join("");
    hide(state); grid.hidden = false;
  } catch (err) { setState(state, friendlyError(err), "error"); }
}

async function renderStories() {
  const state = qs("#story-state");
  const list = qs("#story-list");
  try {
    const rows = await api.getTreeStories(treeId, 3);
    if (!rows?.length) return setState(state, "這棵樹還沒有公開故事。");
    hide(state);
    list.innerHTML = rows.map(s => `<div style="padding:10px 0;border-bottom:1px solid var(--line)">
      <strong>${escapeHtml(s.Title || "樹的故事")}</strong>
      <div class="meta">${escapeHtml(s.PublicAuthor || "")} · ${escapeHtml(s.SubmittedAt || "")}</div>
      <p>${escapeHtml((s.Content || "").slice(0,180))}${(s.Content || "").length > 180 ? "…" : ""}</p>
    </div>`).join("");
  } catch (err) { setState(state, friendlyError(err), "error"); }
}

(async () => {
  if (!valid) {
    treeState.hidden = false;
    setState(treeState, "Tree ID 格式不正確。", "error");
    return;
  }
  try {
    const profile = await api.getTreeProfile(treeId);
    if (!profile?.tree) throw new Error("P114_TREE_NOT_FOUND");
    renderInfo(profile.tree);
    renderMedia(profile.media || []);
    qs("#guardian-count").textContent = profile.guardianCount ?? 0;

    const stats = profile.treeLanguageStats || [];
    qs("#tree-language").innerHTML = stats.length
      ? stats.slice(0,6).map(x => `<span class="badge" style="margin:3px">${escapeHtml(x.labelZh || "")} · ${Number(x.count || 0)}</span>`).join("")
      : "尚無公開樹語統計。";

    await Promise.all([renderMonths(), renderStories()]);
  } catch (err) {
    treeState.hidden = false;
    setState(treeState, friendlyError(err), "error");
  }
})();

qs("#guardian-btn").addEventListener("click", async () => {
  try {
    const session = await getSession();
    if (!session) return location.href = `login.html?returnTo=${encodeURIComponent(location.href)}`;
    await api.setGuardianTree(treeId);
    alert("已設為你的守護樹。");
  } catch (err) { alert(friendlyError(err)); }
});

qs("#visit-btn").addEventListener("click", async () => {
  try {
    const session = await getSession();
    if (!session) return location.href = `login.html?returnTo=${encodeURIComponent(location.href)}`;
    await api.recordVisit(treeId);
    alert("已記錄這次找到它。");
  } catch (err) { alert(friendlyError(err)); }
});