-- user_profile 컬럼 추가 (본인인증용, schema.sql 누락분 보완)
ALTER TABLE user_profile
    ADD COLUMN IF NOT EXISTS resident_number_front VARCHAR(7),
    ADD COLUMN IF NOT EXISTS telecom               VARCHAR(20);

-- payment_matching transaction_amount 보완 (runtime 오류 방지)
ALTER TABLE payment_matching
    ADD COLUMN IF NOT EXISTS transaction_amount DECIMAL(18, 2);
