import { getSession, signIn, signOut, onAuthStateChange } from "../auth.js";
import { qs, setState, footerHtml } from "../ui.js";
import { friendlyError } from "../errors.js";
import { api } from "../api.js";

qs("#footer").innerHTML = footerHtml();

const state = qs("#login-state");
const form = qs("#login-form");
const submitBtn = qs("#login-submit");
const sessionBox = qs("#existing-session");
const sessionEmail = qs("#existing-session-email");
const headerStatus = qs("#login-header-status");

function safeReturnTo(value) {
  if (!value) return "index.html";
  try {
    const url = new URL(value, location.href);
    if (url.origin !== location.origin) return "index.html";
    return url.pathname + url.search + url.hash;
  } catch {
    return "index.html";
  }
}

function validExternalUrl(value) {
  return typeof value === "string" &&
    value.trim() &&
    value.trim() !== "#" &&
    /^https?:\/\//i.test(value.trim());
}

function wireP130Link(selector, configuredUrl, label) {
  const el = qs(selector);
  if (validExternalUrl(configuredUrl)) {
    el.href = configuredUrl;
    el.target = "_self";
    return;
  }
  el.href = "#";
  el.addEventListener("click", e => {
    e.preventDefault();
    state.hidden = false;
    setState(
      state,
      `${label}連結尚未設定。請在 config.js 填入正確的 P130 URL。`,
      "error"
    );
  });
}

wireP130Link("#register-link", window.P114_CONFIG?.P130_REGISTER_URL, "P130 註冊");
wireP130Link("#forgot-link", window.P114_CONFIG?.P130_FORGOT_PASSWORD_URL, "P130 忘記密碼");

function renderSession(session) {
  if (session) {
    headerStatus.textContent = "P114 已登入";
    sessionBox.hidden = false;
    sessionEmail.textContent = session.user?.email || "";
    form.hidden = true;
  } else {
    headerStatus.textContent = "P114 尚未登入";
    sessionBox.hidden = true;
    form.hidden = false;
  }
}

(async () => {
  try {
    renderSession(await getSession());
  } catch {
    renderSession(null);
  }
})();

try {
  onAuthStateChange(renderSession);
} catch {}

qs("#password-toggle").addEventListener("click", () => {
  const input = qs("#password");
  const showing = input.type === "text";
  input.type = showing ? "password" : "text";
  qs("#password-toggle").textContent = showing ? "顯示密碼" : "隱藏密碼";
  qs("#password-toggle").setAttribute("aria-pressed", String(!showing));
  input.focus();
});

form.addEventListener("submit", async e => {
  e.preventDefault();
  state.hidden = false;
  submitBtn.disabled = true;
  submitBtn.textContent = "登入中…";
  setState(state, "正在驗證帳號…");

  try {
    const session = await signIn(
      qs("#email").value.trim(),
      qs("#password").value
    );

    renderSession(session);
    const provision = await api.ensureMemberAccess();
    setState(state, `登入成功：${session.user?.email || ""}。${provision === "member_created" ? "已自動開通 P114 member。" : "P114 權限已確認。"} 正在返回 P114…`, "success");

    const returnTo = safeReturnTo(new URLSearchParams(location.search).get("returnTo"));
    window.setTimeout(() => {
      location.href = returnTo;
    }, 850);
  } catch (err) {
    renderSession(null);
    setState(state, `登入失敗：${friendlyError(err)}`, "error");
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = "登入";
  }
});

qs("#login-page-logout").addEventListener("click", async () => {
  state.hidden = false;
  setState(state, "登出中…");
  try {
    await signOut();
    renderSession(null);
    setState(state, "已登出 P114。", "success");
  } catch (err) {
    setState(state, friendlyError(err), "error");
  }
});
