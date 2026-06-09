-- LINKED_FINANCIAL_ACCOUNT 시드 (은행 20건 + 증권 20건 = 40건)
-- external_account_id: BANK_ACCOUNT.ACCOUNT_ID (2001~2020) / SECURITIES_ACCOUNT.SECURITIES_ACCOUNT_ID (1001~1020)
-- UNIQUE 제약 없음 → WHERE NOT EXISTS 로 재실행 보호

-- =============================================
-- 은행 계좌 (institution_type = 'BANK')
-- 신한(088): 110-0XX-000001 / 우리(020): 1002-0XX-000001
-- =============================================

INSERT INTO linked_financial_account
    (user_id, institution_type, institution_code, external_account_id, account_masking, synced_at)
SELECT u.user_id, v.institution_type, v.institution_code, v.external_account_id, v.account_masking, NOW()
FROM (
    VALUES
        ('test_firebase_001', 'BANK', '088', 2001::bigint, '110-0**-000001'),
        ('test_firebase_001', 'BANK', '020', 2002::bigint, '1002-0**-000001'),
        ('test_firebase_002', 'BANK', '088', 2003::bigint, '110-0**-000001'),
        ('test_firebase_002', 'BANK', '020', 2004::bigint, '1002-0**-000001'),
        ('test_firebase_003', 'BANK', '088', 2005::bigint, '110-0**-000001'),
        ('test_firebase_003', 'BANK', '020', 2006::bigint, '1002-0**-000001'),
        ('test_firebase_004', 'BANK', '088', 2007::bigint, '110-0**-000001'),
        ('test_firebase_004', 'BANK', '020', 2008::bigint, '1002-0**-000001'),
        ('test_firebase_005', 'BANK', '088', 2009::bigint, '110-0**-000001'),
        ('test_firebase_005', 'BANK', '020', 2010::bigint, '1002-0**-000001'),
        ('test_firebase_006', 'BANK', '088', 2011::bigint, '110-0**-000001'),
        ('test_firebase_006', 'BANK', '020', 2012::bigint, '1002-0**-000001'),
        ('test_firebase_007', 'BANK', '088', 2013::bigint, '110-0**-000001'),
        ('test_firebase_007', 'BANK', '020', 2014::bigint, '1002-0**-000001'),
        ('test_firebase_008', 'BANK', '088', 2015::bigint, '110-0**-000001'),
        ('test_firebase_008', 'BANK', '020', 2016::bigint, '1002-0**-000001'),
        ('test_firebase_009', 'BANK', '088', 2017::bigint, '110-0**-000001'),
        ('test_firebase_009', 'BANK', '020', 2018::bigint, '1002-0**-000001'),
        ('test_firebase_010', 'BANK', '088', 2019::bigint, '110-0**-000001'),
        ('test_firebase_010', 'BANK', '020', 2020::bigint, '1002-0**-000001')
) AS v(firebase_uid, institution_type, institution_code, external_account_id, account_masking)
JOIN users u ON u.firebase_uid = v.firebase_uid
WHERE NOT EXISTS (
    SELECT 1 FROM linked_financial_account x
    WHERE x.user_id = u.user_id
      AND x.institution_type = v.institution_type
      AND x.external_account_id = v.external_account_id
);

-- =============================================
-- 증권 계좌 (institution_type = 'SECURITIES')
-- 한국투자(243): XX000001-01 / NH투자(247): 302-00XX-0001-01
-- =============================================

INSERT INTO linked_financial_account
    (user_id, institution_type, institution_code, external_account_id, account_masking, synced_at)
SELECT u.user_id, v.institution_type, v.institution_code, v.external_account_id, v.account_masking, NOW()
FROM (
    VALUES
        ('test_firebase_001', 'SECURITIES', '243', 1001::bigint, '**000001-01'),
        ('test_firebase_001', 'SECURITIES', '247', 1002::bigint, '302-00**-0001-01'),
        ('test_firebase_002', 'SECURITIES', '243', 1003::bigint, '**000001-01'),
        ('test_firebase_002', 'SECURITIES', '247', 1004::bigint, '302-00**-0001-01'),
        ('test_firebase_003', 'SECURITIES', '243', 1005::bigint, '**000001-01'),
        ('test_firebase_003', 'SECURITIES', '247', 1006::bigint, '302-00**-0001-01'),
        ('test_firebase_004', 'SECURITIES', '243', 1007::bigint, '**000001-01'),
        ('test_firebase_004', 'SECURITIES', '247', 1008::bigint, '302-00**-0001-01'),
        ('test_firebase_005', 'SECURITIES', '243', 1009::bigint, '**000001-01'),
        ('test_firebase_005', 'SECURITIES', '247', 1010::bigint, '302-00**-0001-01'),
        ('test_firebase_006', 'SECURITIES', '243', 1011::bigint, '**000001-01'),
        ('test_firebase_006', 'SECURITIES', '247', 1012::bigint, '302-00**-0001-01'),
        ('test_firebase_007', 'SECURITIES', '243', 1013::bigint, '**000001-01'),
        ('test_firebase_007', 'SECURITIES', '247', 1014::bigint, '302-00**-0001-01'),
        ('test_firebase_008', 'SECURITIES', '243', 1015::bigint, '**000001-01'),
        ('test_firebase_008', 'SECURITIES', '247', 1016::bigint, '302-00**-0001-01'),
        ('test_firebase_009', 'SECURITIES', '243', 1017::bigint, '**000001-01'),
        ('test_firebase_009', 'SECURITIES', '247', 1018::bigint, '302-00**-0001-01'),
        ('test_firebase_010', 'SECURITIES', '243', 1019::bigint, '**000001-01'),
        ('test_firebase_010', 'SECURITIES', '247', 1020::bigint, '302-00**-0001-01')
) AS v(firebase_uid, institution_type, institution_code, external_account_id, account_masking)
JOIN users u ON u.firebase_uid = v.firebase_uid
WHERE NOT EXISTS (
    SELECT 1 FROM linked_financial_account x
    WHERE x.user_id = u.user_id
      AND x.institution_type = v.institution_type
      AND x.external_account_id = v.external_account_id
);
