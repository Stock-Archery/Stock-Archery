const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:3000";
const TOKEN_KEY = "sa_admin_token";

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}
export function setToken(token) {
  localStorage.setItem(TOKEN_KEY, token);
}
export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
}

async function request(path, { method = "GET", body, responseType = "json" } = {}) {
  const headers = {};
  if (body) headers["Content-Type"] = "application/json";
  const token = getToken();
  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 401) {
    clearToken();
    const err = new Error("Session expired. Please log in again.");
    err.unauthorized = true;
    throw err;
  }

  if (responseType === "blob") {
    if (!res.ok) throw new Error("Export failed");
    return res.blob();
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.message || "Request failed");
  }
  return data;
}

export function login(password) {
  return request("/admin/login", { method: "POST", body: { password } });
}

export function fetchUsers(params) {
  const qs = new URLSearchParams(params).toString();
  return request(`/admin/users?${qs}`);
}

export function fetchMeta() {
  return request("/admin/meta");
}

export function fetchStats() {
  return request("/admin/stats");
}

export async function downloadUsersExport(params) {
  const qs = new URLSearchParams(params).toString();
  const blob = await request(`/admin/users/export?${qs}`, { responseType: "blob" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `users-export-${new Date().toISOString().slice(0, 10)}.xlsx`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}
