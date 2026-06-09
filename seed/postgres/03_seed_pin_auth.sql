-- PIN_AUTH 시드 (user_id 22~31)
-- PIN: 192837 (모든 계정 동일)
-- pin_hash: BCrypt("192837") = $2b$10$k7rCggSnA6fOS/P4ufgsM.ZnDAOG.GcPmibZECFLeH0YE2igQNGye
-- ON CONFLICT (user_id): PK 기반 재실행 보호

INSERT INTO pin_auth (user_id, pin_hash, fail_count, locked_yn, locked_at, pin_changed_at)
SELECT u.user_id,
       '$2b$10$k7rCggSnA6fOS/P4ufgsM.ZnDAOG.GcPmibZECFLeH0YE2igQNGye',
       0,
       false,
       NULL,
       NULL
FROM users u
WHERE u.firebase_uid IN (
    'test_firebase_001', 'test_firebase_002', 'test_firebase_003',
    'test_firebase_004', 'test_firebase_005', 'test_firebase_006',
    'test_firebase_007', 'test_firebase_008', 'test_firebase_009',
    'test_firebase_010'
)
ON CONFLICT (user_id) DO NOTHING;
