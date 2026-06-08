-- App layer schema separation (all in single 'finance' DB)
CREATE SCHEMA IF NOT EXISTS operational;  -- service-backend
CREATE SCHEMA IF NOT EXISTS analytics;   -- service-ai-server (분석 데이터)
CREATE SCHEMA IF NOT EXISTS log;         -- 감사/로그 데이터
CREATE SCHEMA IF NOT EXISTS vector;      -- service-ai-server (RAG 임베딩)

CREATE EXTENSION IF NOT EXISTS vector;
