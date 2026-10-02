import { useState, useEffect, useCallback, useRef } from "react";
import { fetchUsers, fetchMeta, fetchStats, downloadUsersExport } from "../api.js";
import StatsCards from "./StatsCards.jsx";
import ServerAwakeTracker from "./ServerAwakeTracker.jsx";
import FiltersBar, { DEFAULT_FILTERS } from "./FiltersBar.jsx";
import UsersTable from "./UsersTable.jsx";
import Pagination from "./Pagination.jsx";
import UserDetailModal from "./UserDetailModal.jsx";

// Strips "all"/"" placeholder values so they aren't sent as real query params.
function cleanParams(obj) {
  const out = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value !== "" && value !== "all") out[key] = value;
  }
  return out;
}

export default function Dashboard({ onLogout, onUnauthorized }) {
  const [filters, setFilters] = useState(DEFAULT_FILTERS);
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(25);

  const [users, setUsers] = useState([]);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [stats, setStats] = useState(null);
  const [meta, setMeta] = useState({ states: [], occupations: [], genders: [], tradingExperiences: [] });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [selectedUser, setSelectedUser] = useState(null);
  const [exporting, setExporting] = useState(false);

  const handleError = useCallback(
    (err) => {
      if (err.unauthorized) {
        onUnauthorized();
        return;
      }
      setError(err.message || "Something went wrong");
    },
    [onUnauthorized]
  );

  // Meta (filter dropdown options) and stats load once; stats are cheap
  // enough to also refresh whenever the user list reloads, so the cards
  // stay roughly in sync after an admin changes someone's plan elsewhere.
  useEffect(() => {
    fetchMeta().then(setMeta).catch(handleError);
  }, [handleError]);

  const refreshStats = useCallback(() => {
    fetchStats().then(setStats).catch(handleError);
  }, [handleError]);

  useEffect(() => {
    refreshStats();
  }, [refreshStats]);

  // Debounce the free-text search so every keystroke doesn't fire a request.
  const [searchInput, setSearchInput] = useState("");
  const debounceRef = useRef(null);
  useEffect(() => {
    clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      setFilters((prev) => (prev.search === searchInput ? prev : { ...prev, search: searchInput }));
      setPage(1);
    }, 350);
    return () => clearTimeout(debounceRef.current);
  }, [searchInput]);

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const params = cleanParams({ ...filters, page, limit });
      const data = await fetchUsers(params);
      setUsers(data.users);
      setTotal(data.total);
      setTotalPages(data.totalPages);
    } catch (err) {
      handleError(err);
    } finally {
      setLoading(false);
    }
  }, [filters, page, limit, handleError]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const handleFilterChange = (next) => {
    setFilters(next);
    setSearchInput(next.search);
    setPage(1);
  };

  const handleExport = async () => {
    setExporting(true);
    setError("");
    try {
      await downloadUsersExport(cleanParams(filters));
    } catch (err) {
      handleError(err);
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="dashboard">
      <header className="topbar">
        <div>
          <h1>Stock Archery</h1>
          <span className="subtitle">Admin Panel — Users</span>
        </div>
        <button type="button" className="btn-ghost" onClick={onLogout}>Log out</button>
      </header>

      <ServerAwakeTracker />

      {stats && <StatsCards stats={stats} />}

      <FiltersBar
        filters={{ ...filters, search: searchInput }}
        meta={meta}
        onChange={(next) => {
          setSearchInput(next.search);
          handleFilterChange(next);
        }}
      />

      <div className="table-toolbar">
        <div className="result-count">
          {total.toLocaleString("en-IN")} user{total === 1 ? "" : "s"}
        </div>
        <button type="button" className="btn-primary" onClick={handleExport} disabled={exporting || total === 0}>
          {exporting ? "Preparing file…" : "⬇ Export to Excel"}
        </button>
      </div>

      {error && <div className="banner-error">{error}</div>}

      <UsersTable
        users={users}
        loading={loading}
        sortBy={filters.sortBy}
        order={filters.order}
        onSortChange={(sortBy, order) => handleFilterChange({ ...filters, sortBy, order })}
        onRowClick={setSelectedUser}
      />

      <Pagination
        page={page}
        totalPages={totalPages}
        limit={limit}
        onPageChange={setPage}
        onLimitChange={(l) => {
          setLimit(l);
          setPage(1);
        }}
      />

      {selectedUser && <UserDetailModal user={selectedUser} onClose={() => setSelectedUser(null)} />}
    </div>
  );
}
