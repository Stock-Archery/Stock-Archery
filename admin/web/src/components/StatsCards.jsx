export default function StatsCards({ stats }) {
  const cards = [
    { label: "Total Users", value: stats.total },
    { label: "Premium", value: stats.premium },
    { label: "Free", value: stats.free },
    { label: "New Today", value: stats.newToday },
    { label: "New This Week", value: stats.newThisWeek },
    { label: "New This Month", value: stats.newThisMonth },
  ];

  return (
    <div className="stats-grid">
      {cards.map((c) => (
        <div className="stat-card" key={c.label}>
          <div className="stat-value">{c.value.toLocaleString("en-IN")}</div>
          <div className="stat-label">{c.label}</div>
        </div>
      ))}
    </div>
  );
}
