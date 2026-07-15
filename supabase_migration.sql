-- ============================================================
-- Supabase Migration for Quality & Sustainability Dashboard
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- 1. Create the dashboard_metrics table
CREATE TABLE IF NOT EXISTS public.dashboard_metrics (
    id BIGSERIAL PRIMARY KEY,
    year TEXT NOT NULL,
    metric_id TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT '',
    color TEXT NOT NULL DEFAULT '#64748b',
    type TEXT NOT NULL DEFAULT 'bar',
    jan NUMERIC DEFAULT 0,
    feb NUMERIC DEFAULT 0,
    mar NUMERIC DEFAULT 0,
    apr NUMERIC DEFAULT 0,
    may NUMERIC DEFAULT 0,
    jun NUMERIC DEFAULT 0,
    jul NUMERIC DEFAULT 0,
    aug NUMERIC DEFAULT 0,
    sep NUMERIC DEFAULT 0,
    oct NUMERIC DEFAULT 0,
    nov NUMERIC DEFAULT 0,
    dec NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the dashboard_titles table
CREATE TABLE IF NOT EXISTS public.dashboard_titles (
    id BIGSERIAL PRIMARY KEY,
    title_id TEXT NOT NULL UNIQUE,
    title_text TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Add unique composite constraint for upsert to work on metrics
--    This is CRITICAL: without it, .upsert() will INSERT duplicates
ALTER TABLE public.dashboard_metrics
    DROP CONSTRAINT IF EXISTS dashboard_metrics_year_metric_unique;
ALTER TABLE public.dashboard_metrics
    ADD CONSTRAINT dashboard_metrics_year_metric_unique UNIQUE (year, metric_id);

-- 4. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_dashboard_metrics_year ON public.dashboard_metrics (year);
CREATE INDEX IF NOT EXISTS idx_dashboard_metrics_metric_id ON public.dashboard_metrics (metric_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_titles_title_id ON public.dashboard_titles (title_id);

-- 5. Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_dashboard_metrics_updated_at ON public.dashboard_metrics;
CREATE TRIGGER trigger_dashboard_metrics_updated_at
    BEFORE UPDATE ON public.dashboard_metrics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_dashboard_titles_updated_at ON public.dashboard_titles;
CREATE TRIGGER trigger_dashboard_titles_updated_at
    BEFORE UPDATE ON public.dashboard_titles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.dashboard_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dashboard_titles ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies: Allow anonymous read/write (adjust if you add auth later)
--    These are required for the anon key to work with the dashboard

-- Metrics: allow SELECT
DROP POLICY IF EXISTS "Allow anonymous select on dashboard_metrics" ON public.dashboard_metrics;
CREATE POLICY "Allow anonymous select on dashboard_metrics"
    ON public.dashboard_metrics FOR SELECT
    USING (true);

-- Metrics: allow INSERT
DROP POLICY IF EXISTS "Allow anonymous insert on dashboard_metrics" ON public.dashboard_metrics;
CREATE POLICY "Allow anonymous insert on dashboard_metrics"
    ON public.dashboard_metrics FOR INSERT
    WITH CHECK (true);

-- Metrics: allow UPDATE
DROP POLICY IF EXISTS "Allow anonymous update on dashboard_metrics" ON public.dashboard_metrics;
CREATE POLICY "Allow anonymous update on dashboard_metrics"
    ON public.dashboard_metrics FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- Metrics: allow DELETE
DROP POLICY IF EXISTS "Allow anonymous delete on dashboard_metrics" ON public.dashboard_metrics;
CREATE POLICY "Allow anonymous delete on dashboard_metrics"
    ON public.dashboard_metrics FOR DELETE
    USING (true);

-- Titles: allow SELECT
DROP POLICY IF EXISTS "Allow anonymous select on dashboard_titles" ON public.dashboard_titles;
CREATE POLICY "Allow anonymous select on dashboard_titles"
    ON public.dashboard_titles FOR SELECT
    USING (true);

-- Titles: allow INSERT
DROP POLICY IF EXISTS "Allow anonymous insert on dashboard_titles" ON public.dashboard_titles;
CREATE POLICY "Allow anonymous insert on dashboard_titles"
    ON public.dashboard_titles FOR INSERT
    WITH CHECK (true);

-- Titles: allow UPDATE
DROP POLICY IF EXISTS "Allow anonymous update on dashboard_titles" ON public.dashboard_titles;
CREATE POLICY "Allow anonymous update on dashboard_titles"
    ON public.dashboard_titles FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- Titles: allow DELETE
DROP POLICY IF EXISTS "Allow anonymous delete on dashboard_titles" ON public.dashboard_titles;
CREATE POLICY "Allow anonymous delete on dashboard_titles"
    ON public.dashboard_titles FOR DELETE
    USING (true);

-- 8. Enable Realtime on both tables (required for live sync)
ALTER PUBLICATION supabase_realtime ADD TABLE public.dashboard_metrics;
ALTER PUBLICATION supabase_realtime ADD TABLE public.dashboard_titles;
