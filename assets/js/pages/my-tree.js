import{api}from"../api.js";import{getSession}from"../auth.js";import{qs,setState,hide,footerHtml,escapeHtml}from"../ui.js";import{friendlyError}from"../errors.js";qs("#footer").innerHTML=footerHtml();(async()=>{const s=qs("#my-tree-state");try{const session=await getSession();if(!session){location.href=`login.html?returnTo=${encodeURIComponent(location.href)}`;return}const access=await api.getProjectAccess();if(!access.authorized){return setState(s,"你已登入，但此帳號目前尚未取得 P114 使用權限。","error")}const g=await api.getMyGuardianTree();if(!g)return setState(s,"你今年還沒有設定守護樹。到 Explore 找一棵吧！");hide(s);const c=qs("#guardian-card");c.hidden=false;c.innerHTML=`<span class="badge">${escapeHtml(g.year||"")} 守護樹</span><div class="eyebrow" style="margin-top:14px">${escapeHtml(g.publicTreeId||"")}</div><h2 style="margin:.2rem 0">${escapeHtml(g.commonNameZh||"未命名樹")}</h2><div class="meta"><em>${escapeHtml(g.scientificName||"")}</em></div><div class="meta">${escapeHtml(g.campusNameZh||"")}</div><div style="margin-top:16px"><a class="btn btn-primary" href="tree.html?id=${encodeURIComponent(g.publicTreeId||"")}">查看這棵樹</a></div>`;const l=await api.getMyTreeLanguage(g.publicTreeId),lc=qs("#language-card");lc.hidden=false;lc.innerHTML=`<h3>我對這棵樹的一句話</h3><p>${escapeHtml(l?.freeText||"你還沒有留下自由樹語。")}</p><a class="btn" href="tree.html?id=${encodeURIComponent(g.publicTreeId||"")}">編輯樹語</a>`}catch(e){setState(s,friendlyError(e),"error")}})();

/* V0008_MEMBER_ACTIVITY */
(async()=>{
  try{
    const session=await getSession();
    if(!session)return;
    const g=await api.getMyGuardianTree();
    if(!g)return;
    const treeId=g.publicTreeId||g.PublicTreeId||"";
    const year=Number(g.year||g.Year||new Date().getFullYear());
    const trees=await api.getPublicTrees();
    const tree=trees.find(x=>x.PublicTreeId===treeId);
    if(!tree)return;
    const data=await Promise.all([api.getMyPhotos(),api.getMyVisits(50)]);
    const photos=data[0]||[],visits=data[1]||[];
    const mine=photos.filter(p=>p.TreeId===tree.TreeId&&Number(p.RecordYear)===year&&p.PhotoType==="community");
    const by=new Map(mine.map(p=>[Number(p.RecordMonth),p]));
    const label=s=>({pending:"待審",approved:"已核准",rejected:"未通過"}[s]||s||"—");
    qs("#my-month-grid").innerHTML=Array.from({length:12},(_,i)=>{
      const m=i+1,p=by.get(m);
      return '<div class="month-cell"><strong>'+m+' 月</strong>'+(p?'<span class="status-pill status-'+escapeHtml(p.ReviewStatus)+'">'+escapeHtml(label(p.ReviewStatus))+'</span><div class="meta" style="margin-top:6px">'+escapeHtml(p.Caption||"已投稿")+'</div>':'<div class="meta">尚未投稿</div>')+'</div>';
    }).join("");
    const recent=visits.filter(v=>v.TreeId===tree.TreeId).slice(0,5);
    qs("#my-visit-list").innerHTML=recent.length?recent.map(v=>'<div class="activity-row"><strong>'+escapeHtml(new Date(v.VisitedAt).toLocaleDateString("zh-TW"))+'</strong><span class="meta">'+(v.DistanceToTreeM!=null?'距離約 '+escapeHtml(v.DistanceToTreeM)+' m':'已記錄造訪')+'</span></div>').join(""):'<div class="meta">還沒有造訪紀錄。</div>';
    qs("#my-activity").hidden=false;
  }catch{}
})();
