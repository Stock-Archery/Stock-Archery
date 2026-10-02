export default function Pagination({ page, totalPages, limit, onPageChange, onLimitChange }) {
  return (
    <div className="pagination">
      <select value={limit} onChange={(e) => onLimitChange(Number(e.target.value))}>
        {[25, 50, 100, 200].map((n) => (
          <option key={n} value={n}>{n} / page</option>
        ))}
      </select>

      <div className="pagination-controls">
        <button type="button" disabled={page <= 1} onClick={() => onPageChange(1)}>«</button>
        <button type="button" disabled={page <= 1} onClick={() => onPageChange(page - 1)}>‹</button>
        <span>Page {page} of {totalPages}</span>
        <button type="button" disabled={page >= totalPages} onClick={() => onPageChange(page + 1)}>›</button>
        <button type="button" disabled={page >= totalPages} onClick={() => onPageChange(totalPages)}>»</button>
      </div>
    </div>
  );
}
