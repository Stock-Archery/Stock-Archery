const OCCUPATION_LABELS = {
  student: "Student",
  business: "Business",
  self_employed: "Self Employed",
  government_job: "Government",
  private_sector_job: "Private Sector",
};

function formatDate(value) {
  if (!value) return "—";
  return new Date(value).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" });
}

export default function UsersTable({ users, loading, sortBy, order, onSortChange, onRowClick }) {
  const sortableHeader = (field, label) => {
    const active = sortBy === field;
    return (
      <th
        className={`sortable ${active ? "active" : ""}`}
        onClick={() => onSortChange(field, active && order === "desc" ? "asc" : "desc")}
      >
        {label} {active ? (order === "desc" ? "▼" : "▲") : ""}
      </th>
    );
  };

  return (
    <div className="table-wrap">
      <table className="users-table">
        <thead>
          <tr>
            {sortableHeader("name", "Name")}
            <th>Email</th>
            <th>Phone</th>
            <th>State</th>
            <th>Occupation</th>
            <th>Plan</th>
            {sortableHeader("textChatCount", "Chats Today")}
            {sortableHeader("createdAt", "Signed Up")}
          </tr>
        </thead>
        <tbody>
          {loading && (
            <tr>
              <td colSpan={8} className="empty-row">Loading…</td>
            </tr>
          )}
          {!loading && users.length === 0 && (
            <tr>
              <td colSpan={8} className="empty-row">No users match these filters.</td>
            </tr>
          )}
          {!loading &&
            users.map((u) => (
              <tr key={u._id} onClick={() => onRowClick(u)}>
                <td>{u.name}</td>
                <td>{u.email}</td>
                <td>{u.phoneNumber}</td>
                <td>{u.state || "—"}</td>
                <td>{OCCUPATION_LABELS[u.occupation] || "—"}</td>
                <td>
                  {u.isPremium ? (
                    <span className="badge badge-premium">Premium</span>
                  ) : (
                    <span className="badge">Free</span>
                  )}
                </td>
                <td>{u.textChatCount ?? 0}</td>
                <td>{formatDate(u.createdAt)}</td>
              </tr>
            ))}
        </tbody>
      </table>
    </div>
  );
}
