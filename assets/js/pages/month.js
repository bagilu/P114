import{api}from"../api.js";import{getSession}from"../auth.js";import{publicMediaUrl}from"../storage.js";import{qs,setState,hide,footerHtml,escapeHtml}from"../ui.js";import{friendlyError}from"../errors.js";qs("#footer").innerHTML=footerHtml();(async()=>{const now=new Date(),year=now.getFullYear(),month=now.getMonth()+1;qs("#month-label").textContent=`${year} 年 ${month} 月`;const s=qs("#month-page-state"),g=qs("#month-page-grid");try{const trees=await api.getPublicTrees();if(!trees.length)return setState(s,"目前沒有公開樹木。");const rows=[];for(const t of trees){try{const ps=await api.getTreeMonthlyPhotos(t.PublicTreeId,year),p=(ps||[]).find(x=>Number(x.RecordMonth)===month&&x.PhotoType==="community");rows.push({t,p})}catch{rows.push({t,p:null})}}g.innerHTML=rows.map(({t,p})=>`<a class="card" href="tree.html?id=${encodeURIComponent(t.PublicTreeId)}">${p?.FilePath?`<img src="${publicMediaUrl(p.FilePath)}" alt="${escapeHtml(t.CommonNameZh||"")}" style="width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:12px">`:'<div style="aspect-ratio:4/3;background:var(--surface-soft);border-radius:12px;display:grid;place-items:center" class="meta">本月尚未有代表照</div>'}<div class="eyebrow" style="margin-top:12px">${escapeHtml(t.PublicTreeId||"")}</div><h3 style="margin:.2rem 0">${escapeHtml(t.CommonNameZh||"未命名樹")}</h3><div class="meta">${p?"本月代表照已完成":"等待本月一影"}</div></a>`).join("");hide(s);g.hidden=false}catch(e){setState(s,friendlyError(e),"error")}})();

/* V0008_MY_MONTH */
(async()=>{
  try{
    const session=await getSession();
    if(!session)return;
    const access=await api.getProjectAccess();
    if(!access.authorized)return;
    const now=new Date(),year=now.getFullYear(),month=now.getMonth()+1;
    const data=await Promise.all([api.getMyPhotos(),api.getPublicTrees()]);
    const mine=(data[0]||[]).filter(p=>Number(p.RecordYear)===year&&Number(p.RecordMonth)===month&&p.PhotoType==="community");
    const treeMap=new Map((data[1]||[]).map(t=>[t.TreeId,t]));
    const box=qs("#my-month-summary");
    const label=s=>({pending:"待審",approved:"已核准",rejected:"未通過"}[s]||s||"—");
    box.hidden=false;
    box.innerHTML='<div class="section-head"><div><h2>我的本月投稿</h2><p>'+(mine.length?'已投稿 '+mine.length+' 棵樹':'本月還沒有投稿')+'</p></div><a class="btn" href="my-tree.html">我的樹</a></div>'+(mine.length?'<div class="activity-list">'+mine.map(p=>{const t=treeMap.get(p.TreeId);return '<a class="activity-row" href="tree.html?id='+encodeURIComponent(t?.PublicTreeId||"")+'"><span><strong>'+escapeHtml(t?.PublicTreeId||"")+'</strong> · '+escapeHtml(t?.CommonNameZh||"")+'</span><span class="status-pill status-'+escapeHtml(p.ReviewStatus)+'">'+escapeHtml(label(p.ReviewStatus))+'</span></a>';}).join("")+'</div>':'<div class="meta">到任一棵樹的檔案頁，上傳本月一影。</div>');
  }catch{}
})();
