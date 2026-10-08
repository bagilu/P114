import { api } from "../api.js";
import { publicMediaUrl } from "../storage.js";
import { treeCardHtml, setState, hide, qs, footerHtml } from "../ui.js";
import { friendlyError } from "../errors.js";

qs("#footer").innerHTML = footerHtml();

(async () => {
  const state = qs("#home-state");
  const grid = qs("#founding-grid");
  try {
    const trees = await api.getFoundingTrees(6);
    if (!trees.length) {
      setState(state, "Founding Trees 尚未建立。");
      return;
    }
    grid.innerHTML = trees.map(t => treeCardHtml(t, t.HeroPhotoPath ? publicMediaUrl(t.HeroPhotoPath) : null)).join("");
    hide(state);
    grid.hidden = false;
  } catch (err) {
    setState(state, friendlyError(err), "error");
  }
})();