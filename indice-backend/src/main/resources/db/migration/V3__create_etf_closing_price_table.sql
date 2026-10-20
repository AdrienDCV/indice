CREATE TABLE IF NOT EXISTS etf_closing_price (
    id             UUID           PRIMARY KEY,
    etf_id         UUID           NOT NULL REFERENCES etf (id) ON DELETE CASCADE,
    trading_date   DATE           NOT NULL,
    adjusted_close NUMERIC(19, 6) NOT NULL,
    fetched_at     TIMESTAMPTZ    NOT NULL,
    CONSTRAINT etf_closing_price_etf_date_key UNIQUE (etf_id, trading_date)
);
