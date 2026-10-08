import { signIn } from "../auth.js";
import { qs, setState, footerHtml } from "../ui.js";
import { friendlyError } from "../errors.js";

qs("#footer").innerHTML = footerHtml();
qs("#register-link").href = window.P114_CONFIG?.P130_REGISTER_URL || "#";
qs("#forgot-link").href = window.P114_CONFIG?.P130_FORGOT_PASSWORD_URL || "#";

qs("#login-form").addEventListener("submit", async e => {
  e.preventDefault();
  const state = qs("#login-state");
  state.hidden = false;
  setState(state, "登入中…");
  try {
    await signIn(qs("#email").value.trim(), qs("#password").value);
    const rt = new URLSearchParams(location.search).get("returnTo");
    location.href = rt || "index.html";
  } catch (err) {
    setState(state, friendlyError(err), "error");
  }
});