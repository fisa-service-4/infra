SET search_path TO operational;

DO $$
BEGIN
    ALTER TABLE user_profile
        ADD COLUMN IF NOT EXISTS resident_number_front VARCHAR(7),
        ADD COLUMN IF NOT EXISTS telecom               VARCHAR(20);
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE payment_matching
        ADD COLUMN IF NOT EXISTS transaction_amount DECIMAL(18, 2);
EXCEPTION
    WHEN undefined_table THEN NULL;
END $$;
