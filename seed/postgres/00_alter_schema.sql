SET search_path TO operational;

ALTER TABLE user_profile
    ADD COLUMN IF NOT EXISTS resident_number_front VARCHAR(7),
    ADD COLUMN IF NOT EXISTS telecom               VARCHAR(20);

ALTER TABLE payment_matching
    ADD COLUMN IF NOT EXISTS transaction_amount DECIMAL(18, 2);
