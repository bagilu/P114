import { getSession, signOut, onAuthStateChange } from "./auth.js";

function displayIdentity(session) {
  const email = session?.user?.email || "";
  if (!email) return "已登入";
  const name = email.split("@")[0];
  return `已登入 · ${name}`;
}

function render(session) {
  document.querySelectorAll("[data-auth-status]").forEach(el => {
    el.textContent = session ? displayIdentity(session) : "尚未登入";
    el.dataset.loggedIn = session ? "true" : "false";
  });

  document.querySelectorAll("[data-auth-action]").forEach(el => {
    if (session) {
      el.textContent = "登出";
      el.href = "#";
      el.dataset.authMode = "logout";
      el.classList.add("auth-logged-in");
      el.title = session.user?.email ? `目前登入：${session.user.email}` : "目前已登入";
    } else {
      el.textContent = "登入";
      el.href = "login.html";
      el.dataset.authMode = "login";
      el.classList.remove("auth-logged-in");
      el.title = "登入 P114";
    }
  });
}

async function init() {
  try {
    const session = await getSession();
    render(session);
  } catch {
    render(null);
  }

  document.addEventListener("click", async e => {
    const target = e.target.closest("[data-auth-action]");
    if (!target || target.dataset.authMode !== "logout") return;
    e.preventDefault();
    target.setAttribute("aria-busy", "true");
    target.textContent = "登出中…";
    try {
      await signOut();
      render(null);
      location.href = "index.html";
    } finally {
      target.removeAttribute("aria-busy");
    }
  });

  try {
    onAuthStateChange(session => render(session));
  } catch {}
}

init();
