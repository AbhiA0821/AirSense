import { useEffect, useRef, useState, useCallback } from "react";
import { searchPlace } from "../lib/geocode";

export default function LocationSearch({
  placeholder,
  value = "",
  onSelect,
  onInvalidate,
  dotColor,
  id,
}) {
  const [query, setQuery] = useState(value || "");
  const [results, setResults] = useState([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [activeIndex, setActiveIndex] = useState(-1);

  const containerRef = useRef(null);
  const abortControllerRef = useRef(null);
  const debounceTimerRef = useRef(null);
  const lastSelectedValueRef = useRef(value || "");

  // Synchronize external value updates (e.g. from map click or current-location button)
  useEffect(() => {
    if (value !== undefined && value !== lastSelectedValueRef.current) {
      setQuery(value || "");
      lastSelectedValueRef.current = value || "";
      setOpen(false);
      setResults([]);
    }
  }, [value]);

  // Close dropdown on click outside
  useEffect(() => {
    function handleClickOutside(e) {
      if (containerRef.current && !containerRef.current.contains(e.target)) {
        setOpen(false);
        setActiveIndex(-1);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const executeSearch = useCallback(
    (searchTerm) => {
      if (abortControllerRef.current) {
        abortControllerRef.current.abort();
      }

      const trimmed = searchTerm.trim();
      if (trimmed.length < 2) {
        setResults([]);
        setLoading(false);
        setError(null);
        setOpen(false);
        return;
      }

      setLoading(true);
      setError(null);
      setOpen(true);

      const controller = new AbortController();
      abortControllerRef.current = controller;

      searchPlace(trimmed, controller.signal)
        .then((items) => {
          setResults(items || []);
          setActiveIndex(-1);
          setLoading(false);
        })
        .catch((err) => {
          if (err.name === "AbortError") return;
          setError("Location lookup failed. Please check your network or try again.");
          setResults([]);
          setLoading(false);
        });
    },
    []
  );

  const handleInputChange = (e) => {
    const nextVal = e.target.value;
    setQuery(nextVal);

    // Rule: Invalidate previously selected coordinates immediately when user edits text
    if (lastSelectedValueRef.current && nextVal !== lastSelectedValueRef.current) {
      lastSelectedValueRef.current = "";
      if (onInvalidate) onInvalidate();
    }

    if (debounceTimerRef.current) clearTimeout(debounceTimerRef.current);

    debounceTimerRef.current = setTimeout(() => {
      executeSearch(nextVal);
    }, 350);
  };

  const handlePick = (place) => {
    const displayName = place.name || place.address || "Selected Location";
    setQuery(displayName);
    lastSelectedValueRef.current = displayName;
    setOpen(false);
    setResults([]);
    setActiveIndex(-1);

    if (onSelect) {
      // Support both signatures for backwards compatibility
      onSelect(place.lat, place.lon, displayName, place);
    }
  };

  const handleKeyDown = (e) => {
    if (!open) {
      if (e.key === "ArrowDown" && results.length > 0) {
        setOpen(true);
        setActiveIndex(0);
        e.preventDefault();
      }
      return;
    }

    if (e.key === "ArrowDown") {
      e.preventDefault();
      setActiveIndex((prev) => (prev < results.length - 1 ? prev + 1 : 0));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActiveIndex((prev) => (prev > 0 ? prev - 1 : results.length - 1));
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (activeIndex >= 0 && activeIndex < results.length) {
        handlePick(results[activeIndex]);
      }
    } else if (e.key === "Escape") {
      setOpen(false);
      setActiveIndex(-1);
      e.target.blur();
    }
  };

  return (
    <div className="search-wrap" ref={containerRef}>
      <div className="search-input-row">
        {dotColor && <span className="dot" style={{ background: dotColor }} />}
        <input
          id={id}
          type="text"
          className="search-input"
          placeholder={placeholder}
          value={query}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          onFocus={() => {
            if (results.length > 0) setOpen(true);
            else if (query.trim().length >= 2) executeSearch(query);
          }}
          autoComplete="off"
          aria-autocomplete="list"
        />
        {loading && <span className="search-spinner" title="Searching locations…" />}
        {query && !loading && (
          <button
            type="button"
            className="search-clear-btn"
            onClick={() => {
              setQuery("");
              lastSelectedValueRef.current = "";
              setResults([]);
              setOpen(false);
              if (onInvalidate) onInvalidate();
            }}
            title="Clear location"
          >
            ×
          </button>
        )}
      </div>

      {open && (
        <div className="search-dropdown" role="listbox">
          {loading && results.length === 0 && (
            <div className="search-status-item loading">
              <span className="search-mini-spinner" /> Finding Delhi NCR locations…
            </div>
          )}

          {error && (
            <div className="search-status-item error">
              <span>{error}</span>
              <button
                type="button"
                className="search-retry-btn"
                onClick={() => executeSearch(query)}
              >
                Retry
              </button>
            </div>
          )}

          {!loading && !error && results.length === 0 && query.trim().length >= 2 && (
            <div className="search-status-item empty">
              No matching locations found in Delhi NCR. Try landmarks like &quot;India Gate&quot;, &quot;Connaught Place&quot;, or &quot;Anand Vihar&quot;.
            </div>
          )}

          {results.map((r, i) => {
            const isStation = r.type === "cpcb_station";
            const isLandmark = r.type === "landmark";
            return (
              <div
                key={`${r.lat}-${r.lon}-${i}`}
                role="option"
                aria-selected={i === activeIndex}
                className={`search-result ${i === activeIndex ? "search-result-active" : ""}`}
                onClick={() => handlePick(r)}
                onMouseEnter={() => setActiveIndex(i)}
              >
                <div className="search-result-main">
                  <span className="search-result-name">{r.name}</span>
                  {isStation && <span className="search-badge station">CPCB Monitor</span>}
                  {isLandmark && <span className="search-badge landmark">Landmark</span>}
                </div>
                {r.address && <div className="search-result-address">{r.address}</div>}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

