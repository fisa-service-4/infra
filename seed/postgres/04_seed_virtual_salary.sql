SET search_path TO operational;

-- VIRTUAL_SALARY_SETTING 시드 (user_id 22~31)
-- ON CONFLICT (user_id): PK 기반 재실행 보호

INSERT INTO virtual_salary_setting
    (user_id, target_salary, payday, emergency_target_amount,
     investment_ratio, emergency_ratio, priority_order, updated_at)
SELECT u.user_id, v.target_salary, v.payday, v.emergency_target_amount,
       NULL, NULL, NULL, NOW()
FROM (
    VALUES
        ('test_firebase_001', 3500000.00, 25, 7000000.00),
        ('test_firebase_002', 2800000.00, 20, 5000000.00),
        ('test_firebase_003', 4500000.00, 15, 9000000.00),
        ('test_firebase_004', 3200000.00, 25, 6500000.00),
        ('test_firebase_005', 2500000.00, 10, 5000000.00),
        ('test_firebase_006', 3000000.00, 25, 6000000.00),
        ('test_firebase_007', 4000000.00, 20, 8000000.00),
        ('test_firebase_008', 2200000.00, 15, 4500000.00),
        ('test_firebase_009', 3000000.00, 25, 6000000.00),
        ('test_firebase_010', 3800000.00, 10, 7500000.00)
) AS v(firebase_uid, target_salary, payday, emergency_target_amount)
JOIN users u ON u.firebase_uid = v.firebase_uid
ON CONFLICT (user_id) DO NOTHING;


INSERT INTO virtual_salary_setting (user_id, target_salary, payday, updated_at)
SELECT u.user_id, 1500000, 25, NOW()
FROM users u
WHERE u.firebase_uid = 'test_firebase_001'
ON CONFLICT (user_id) DO UPDATE SET target_salary = 1500000, payday = 25, updated_at = NOW();


INSERT INTO virtual_salary_setting (user_id, target_salary, payday, updated_at)
SELECT u.user_id, 1200000, 25, NOW()
FROM users u
WHERE u.firebase_uid = 'test_firebase_002'
ON CONFLICT (user_id) DO UPDATE SET target_salary = 1200000, payday = 25, updated_at = NOW();


INSERT INTO virtual_salary_setting (user_id, target_salary, payday, updated_at)
SELECT u.user_id, 1800000, 25, NOW()
FROM users u
WHERE u.firebase_uid = 'test_firebase_004'
ON CONFLICT (user_id) DO UPDATE SET target_salary = 1800000, payday = 25, updated_at = NOW();


INSERT INTO virtual_salary_setting (user_id, target_salary, payday, updated_at)
SELECT u.user_id, 1700000, 25, NOW()
FROM users u
WHERE u.firebase_uid = 'test_firebase_005'
ON CONFLICT (user_id) DO UPDATE SET target_salary = 1700000, payday = 25, updated_at = NOW();


INSERT INTO virtual_salary_setting (user_id, target_salary, payday, updated_at)
SELECT u.user_id, 3000000, 25, NOW()
FROM users u
WHERE u.firebase_uid = 'test_firebase_007'
ON CONFLICT (user_id) DO UPDATE SET target_salary = 3000000, payday = 25, updated_at = NOW();
