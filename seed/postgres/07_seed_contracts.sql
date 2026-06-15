SET search_path TO operational;

-- User 22 Contracts
-- Contract 1: A Company
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2201, u.user_id, 'A사', 3000000, 'BUSINESS', 3.3, '2026-03-15', '2026-03-15', 'PAID', '2026-03-01'
FROM users u WHERE u.firebase_uid = 'test_firebase_001'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2201, 3.3, 99000, 2901000, '2026-03-15')
ON CONFLICT DO NOTHING;

-- Contract 2: B Company
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2202, u.user_id, 'B사', 4500000, 'BUSINESS', 3.3, '2026-04-10', '2026-04-10', 'PAID', '2026-04-01'
FROM users u WHERE u.firebase_uid = 'test_firebase_001'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2202, 3.3, 148500, 4351500, '2026-04-10')
ON CONFLICT DO NOTHING;

-- Contract 3: Maintenance
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2203, u.user_id, 'C사(유지보수)', 2500000, 'BUSINESS', 3.3, '2026-05-12', '2026-05-12', 'PAID', '2026-05-01'
FROM users u WHERE u.firebase_uid = 'test_firebase_001'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2203, 3.3, 82500, 2417500, '2026-05-12')
ON CONFLICT DO NOTHING;

-- User 23 Contracts
-- Contract 1: Shopping Mall Design (Mar 05)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2301, u.user_id, '소규모 쇼핑몰', 1200000, 'BUSINESS', 3.3, '2026-03-05', '2026-03-05', 'PAID', '2026-02-20'
FROM users u WHERE u.firebase_uid = 'test_firebase_002'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2301, 3.3, 39600, 1160400, '2026-03-05')
ON CONFLICT DO NOTHING;

-- No contract in April (Income Gap)

-- Contract 2: Startup App UI (May 08)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2302, u.user_id, '스타트업A', 4500000, 'BUSINESS', 3.3, '2026-05-08', '2026-05-08', 'PAID', '2026-04-15'
FROM users u WHERE u.firebase_uid = 'test_firebase_002'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2302, 3.3, 148500, 4351500, '2026-05-08')
ON CONFLICT DO NOTHING;

-- Contract 3: Banner Design (Jun 02)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2303, u.user_id, 'B사(배너)', 800000, 'BUSINESS', 3.3, '2026-06-02', '2026-06-02', 'PAID', '2026-05-25'
FROM users u WHERE u.firebase_uid = 'test_firebase_002'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2303, 3.3, 26400, 773600, '2026-06-02')
ON CONFLICT DO NOTHING;

-- User 25 Contracts
-- Contract 1: Fashion Brand Web (Mar 07)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2501, u.user_id, '패션브랜드A', 3500000, 'BUSINESS', 3.3, '2026-03-07', '2026-03-07', 'PAID', '2026-02-15'
FROM users u WHERE u.firebase_uid = 'test_firebase_004'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2501, 3.3, 115500, 3384500, '2026-03-07')
ON CONFLICT DO NOTHING;

-- Contract 2: Online Mall (Apr 11)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2502, u.user_id, '쇼핑몰B', 4800000, 'BUSINESS', 3.3, '2026-04-11', '2026-04-11', 'PAID', '2026-03-20'
FROM users u WHERE u.firebase_uid = 'test_firebase_004'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2502, 3.3, 158400, 4641600, '2026-04-11')
ON CONFLICT DO NOTHING;

-- Contract 3: Landing Page (May 15)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2503, u.user_id, '랜딩페이지C', 2700000, 'BUSINESS', 3.3, '2026-05-15', '2026-05-15', 'PAID', '2026-05-01'
FROM users u WHERE u.firebase_uid = 'test_firebase_004'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2503, 3.3, 89100, 2610900, '2026-05-15')
ON CONFLICT DO NOTHING;

-- User 26 Contracts
-- Contract 1: Bootcamp Backend (Jun 05)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2601, u.user_id, '부트캠프 운영사', 7000000, 'BUSINESS', 3.3, '2026-06-05', '2026-06-05', 'PAID', '2026-05-15'
FROM users u WHERE u.firebase_uid = 'test_firebase_005'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2601, 3.3, 231000, 6769000, '2026-06-05')
ON CONFLICT DO NOTHING;

-- Contract 2: Corporate Spring Training (Jul 12)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2602, u.user_id, '기업교육센터', 1500000, 'BUSINESS', 3.3, '2026-07-12', '2026-07-12', 'PAID', '2026-06-20'
FROM users u WHERE u.firebase_uid = 'test_firebase_005'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2602, 3.3, 49500, 1450500, '2026-07-12')
ON CONFLICT DO NOTHING;

-- Contract 3: Online Special Lecture (Aug 08)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2603, u.user_id, '온라인플랫폼', 800000, 'BUSINESS', 3.3, '2026-08-08', '2026-08-08', 'PAID', '2026-07-30'
FROM users u WHERE u.firebase_uid = 'test_firebase_005'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2603, 3.3, 26400, 773600, '2026-08-08')
ON CONFLICT DO NOTHING;

-- User 28 Contracts
-- Contract 1: US SaaS Startup (Mar 04)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2801, u.user_id, '미국 SaaS 스타트업', 12000000, 'BUSINESS', 0.0, '2026-03-04', '2026-03-04', 'PAID', '2026-02-10'
FROM users u WHERE u.firebase_uid = 'test_firebase_007'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2801, 0.0, 0, 12000000, '2026-03-04')
ON CONFLICT DO NOTHING;

-- Contract 2: Fintech API (Apr 05)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2802, u.user_id, '미국 핀테크 기업', 15000000, 'BUSINESS', 0.0, '2026-04-05', '2026-04-05', 'PAID', '2026-03-15'
FROM users u WHERE u.firebase_uid = 'test_firebase_007'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2802, 0.0, 0, 15000000, '2026-04-05')
ON CONFLICT DO NOTHING;

-- Contract 3: Maintenance (May 06)
INSERT INTO contract (contract_id, user_id, client_name, contract_amount, tax_type, tax_rate, expected_payment_date, actual_payment_date, contract_status, created_at)
SELECT 2803, u.user_id, '고객사 유지보수', 10000000, 'BUSINESS', 0.0, '2026-05-06', '2026-05-06', 'PAID', '2026-04-20'
FROM users u WHERE u.firebase_uid = 'test_firebase_007'
ON CONFLICT (contract_id) DO NOTHING;

INSERT INTO contract_settlement (contract_id, tax_rate, deducted_amount, actual_income, calculated_at)
VALUES (2803, 0.0, 0, 10000000, '2026-05-06')
ON CONFLICT DO NOTHING;

