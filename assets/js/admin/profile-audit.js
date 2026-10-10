import{api}from"../api.js";import{getSession}from"../auth.js";import{qs,setState,hide,escapeHtml}from"../ui.js";import{friendlyError}from"../errors.js";
let rows=[];
const sp=t=>t.TblP114TreeSpecies||{},cp=t=>t.TblP114Campuses||{};
async function gate(){const st=qs("#audit-gate");try{if(!await getSession()){location.href="../login.html?returnTo="+encodeURIComponent(location.href);return false}const a=await api.getProjectAccess();if(!a.roles.some(x=>["editor","admin"].includes(x))){setState(st,"此功能需要 editor 或 admin 權限。","error");return false}hide(st);qs("#audit-app").hidden=false;return true}catch(e){setState(st,friendlyError(e),"error");return false}}
function auditTree(t,media,obs){
  const types=new Set((media||[]).map(x=>x.MediaType||x.mediaType));
  const hasObs=(obs||[]).length>0,hasObsRef=(obs||[]).some(x=>x.ReferencePhotoPath);
  const checks=[
    ["物種",!!t.SpeciesId],
    ["GPS 座標",t.Latitude!=null&&t.Longitude!=null],
    ["最近地標",!!t.Landmark],
    ["相對位置",!!t.RelativeLocation],
    ["方向提示",!!t.DirectionNote],
    ["辨識提示",!!t.IdentificationNote],
    ["個體特徵",!!t.IndividualNote],
    ["校園故事",!!t.CampusStory],
    ["Hero 照",types.has("hero")],
    ["環境定位照",types.has("location_signature")],
    ["全樹照",types.has("whole_tree")],
    ["樹幹／特徵照",types.has("trunk")],
    ["Observation Point",hasObs],
    ["拍攝點參考照",hasObsRef]
  ];
  const done=checks.filter(x=>x[1]).length,score=Math.round(done/checks.length*100);
  return{tree:t,checks,score,missing:checks.filter(x=>!x[1]).map(x=>x[0])};
}
function render(){
  const q=(qs("#audit-filter").value||"").trim().toLowerCase(),mode=qs("#audit-mode").value,sort=qs("#audit-sort").value;
  let data=rows.filter(r=>{
    const t=r.tree,hay=[t.PublicTreeId,sp(t).CommonNameZh,sp(t).ScientificName,cp(t).NameZh].filter(Boolean).join(" ").toLowerCase();
    if(q&&!hay.includes(q))return false;
    if(mode==="incomplete"&&r.score>=80)return false;
    if(mode==="ready"&&r.score<80)return false;
    if(mode==="founding"&&!t.IsFoundingTree)return false;
    return true;
  });
  data.sort((a,b)=>sort==="score-desc"?b.score-a.score:sort==="id"?String(a.tree.PublicTreeId).localeCompare(String(b.tree.PublicTreeId)):a.score-b.score);
  qs("#audit-total").textContent=rows.length;
  qs("#audit-ready").textContent=rows.filter(x=>x.score>=80).length;
  qs("#audit-founding").textContent=rows.filter(x=>x.tree.IsFoundingTree&&x.score>=80).length;
  const st=qs("#audit-state"),box=qs("#audit-list");
  if(!data.length){box.hidden=true;return setState(st,"沒有符合條件的 Tree。")}
  hide(st);box.hidden=false;
  box.innerHTML=data.map(r=>{
    const t=r.tree,name=sp(t).CommonNameZh||"未鑑定",campus=cp(t).NameZh||"",tone=r.score>=80?"success":r.score>=60?"warning":"error";
    return `<article class="card audit-card"><div class="audit-head"><div><div class="meta">${escapeHtml(t.PublicTreeId)} · ${escapeHtml(campus)}</div><h3>${escapeHtml(name)}</h3><div class="meta"><em>${escapeHtml(sp(t).ScientificName||"")}</em></div></div><div class="audit-score ${tone}"><strong>${r.score}%</strong><span>${r.score>=80?"Ready":"Incomplete"}</span></div></div><div class="audit-checks">${r.checks.map(([label,ok])=>`<span class="audit-chip ${ok?"ok":"missing"}">${ok?"✓":"○"} ${escapeHtml(label)}</span>`).join("")}</div><div class="meta" style="margin-top:10px">${r.missing.length?"尚缺："+escapeHtml(r.missing.join("、")):"必要項目已齊全。"}</div><div class="hero-actions" style="margin-top:14px"><a class="btn btn-primary" href="trees.html#tree-form">回 Tree Management 補資料</a><a class="btn" href="../tree.html?id=${encodeURIComponent(t.PublicTreeId)}" target="_blank" rel="noopener">查看公開 Tree Profile</a></div></article>`;
  }).join("");
}
async function load(){
  const st=qs("#audit-state");setState(st,"正在檢查 Tree Profiles…");
  const trees=await api.adminListTrees();
  rows=await Promise.all(trees.map(async t=>{const [media,obs]=await Promise.all([api.adminListTreeMedia(t.Id),api.adminListObservationPoints(t.Id)]);return auditTree(t,media,obs)}));
  render();
}
["#audit-filter","#audit-mode","#audit-sort"].forEach(s=>qs(s).addEventListener(s==="#audit-filter"?"input":"change",render));
(async()=>{if(await gate())try{await load()}catch(e){setState(qs("#audit-state"),friendlyError(e),"error")}})();