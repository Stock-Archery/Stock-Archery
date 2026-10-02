const OCCUPATION_LABELS = {
  student: "Student",
  business: "Business",
  self_employed: "Self Employed",
  government_job: "Government Job",
  private_sector_job: "Private Sector Job",
};

export const DEFAULT_FILTERS = {
  search: "",
  state: "all",
  occupation: "all",
  gender: "all",
  tradingExperience: "all",
  premium: "all",
  from: "",
  to: "",
  sortBy: "createdAt",
  order: "desc",
};

export default function FiltersBar({ filters, meta, onChange }) {
  const set = (key) => (e) => onChange({ ...filters, [key]: e.target.value });

  return (
    <div className="filters-bar">
      <input
        className="search-input"
        type="search"
        placeholder="Search name, email or phone…"
        value={filters.search}
        onChange={set("search")}
      />

      <select value={filters.premium} onChange={set("premium")}>
        <option value="all">All users</option>
        <option value="premium">Premium only</option>
        <option value="free">Free only</option>
      </select>

      <select value={filters.state} onChange={set("state")}>
        <option value="all">All states</option>
        {meta.states.map((s) => (
          <option key={s} value={s}>{s}</option>
        ))}
      </select>

      <select value={filters.occupation} onChange={set("occupation")}>
        <option value="all">All occupations</option>
        {meta.occupations.map((o) => (
          <option key={o} value={o}>{OCCUPATION_LABELS[o] || o}</option>
        ))}
      </select>

      <select value={filters.gender} onChange={set("gender")}>
        <option value="all">All genders</option>
        {meta.genders.map((g) => (
          <option key={g} value={g}>{g.charAt(0).toUpperCase() + g.slice(1)}</option>
        ))}
      </select>

      <select value={filters.tradingExperience} onChange={set("tradingExperience")}>
        <option value="all">Any experience</option>
        {meta.tradingExperiences.map((t) => (
          <option key={t} value={t}>{t.charAt(0).toUpperCase() + t.slice(1)}</option>
        ))}
      </select>

      <div className="date-range">
        <label>
          Signed up from
          <input type="date" value={filters.from} onChange={set("from")} />
        </label>
        <label>
          to
          <input type="date" value={filters.to} onChange={set("to")} />
        </label>
      </div>

      <select
        value={`${filters.sortBy}:${filters.order}`}
        onChange={(e) => {
          const [sortBy, order] = e.target.value.split(":");
          onChange({ ...filters, sortBy, order });
        }}
      >
        <option value="createdAt:desc">Newest signups first</option>
        <option value="createdAt:asc">Oldest signups first</option>
        <option value="name:asc">Name A–Z</option>
        <option value="name:desc">Name Z–A</option>
        <option value="textChatCount:desc">Most chat activity</option>
      </select>

      <button type="button" className="btn-ghost" onClick={() => onChange(DEFAULT_FILTERS)}>
        Reset filters
      </button>
    </div>
  );
}
