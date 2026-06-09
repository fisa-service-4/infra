-- USER_PROFILE 시드 (user_id 22~31)
-- 00_alter_schema.sql 실행 후 resident_number_front, telecom 컬럼이 존재해야 함
-- ON CONFLICT (user_id): PK 기반 재실행 보호

INSERT INTO user_profile (user_id, freelancer_yn, job_type, resident_number_front, telecom)
SELECT u.user_id, v.freelancer_yn, v.job_type, v.resident_number_front, v.telecom
FROM (
    VALUES
        ('test_firebase_001', true,  'DEVELOPER',    '9910011', 'SKT'),
        ('test_firebase_002', true,  'DESIGNER',     '9501522', 'KT'),
        ('test_firebase_003', false, 'MARKETER',     '9205031', 'LGU'),
        ('test_firebase_004', true,  'DEVELOPER',    '9308072', 'SKT'),
        ('test_firebase_005', true,  'WRITER',       '9611143', 'KT'),
        ('test_firebase_006', true,  'PHOTOGRAPHER', '9001274', 'LGU'),
        ('test_firebase_007', false, 'DEVELOPER',    '9403115', 'SKT'),
        ('test_firebase_008', true,  'TRANSLATOR',   '9709016', 'KT'),
        ('test_firebase_009', true,  'DESIGNER',     '9112047', 'LGU'),
        ('test_firebase_010', false, 'MARKETER',     '9802258', 'SKT')
) AS v(firebase_uid, freelancer_yn, job_type, resident_number_front, telecom)
JOIN users u ON u.firebase_uid = v.firebase_uid
ON CONFLICT (user_id) DO NOTHING;
