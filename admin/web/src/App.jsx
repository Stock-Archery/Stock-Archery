import { useState } from "react";
import Login from "./components/Login.jsx";
import Dashboard from "./components/Dashboard.jsx";
import { getToken, clearToken } from "./api.js";

export default function App() {
  const [authed, setAuthed] = useState(!!getToken());

  const handleLogout = () => {
    clearToken();
    setAuthed(false);
  };

  return authed ? (
    <Dashboard onLogout={handleLogout} onUnauthorized={handleLogout} />
  ) : (
    <Login onSuccess={() => setAuthed(true)} />
  );
}
