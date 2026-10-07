CREATE TABLE IF NOT EXISTS etf (
    id         UUID         PRIMARY KEY,
    isin       VARCHAR(12)  NOT NULL,
    ticker     VARCHAR(20)  NOT NULL,
    exchange   VARCHAR(10)  NOT NULL,
    name       VARCHAR(255) NOT NULL,
    currency   VARCHAR(10)  NOT NULL,
    fetched_at TIMESTAMPTZ  NOT NULL,
    CONSTRAINT etf_isin_key UNIQUE (isin)
);
