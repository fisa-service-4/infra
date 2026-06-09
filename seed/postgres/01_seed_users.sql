-- USERS 시드 (user_id 22~31)
-- password_hash: BCrypt("Test1234!") = $2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.
-- ON CONFLICT (firebase_uid): firebase_uid UNIQUE 제약 기반 재실행 보호

INSERT INTO users (firebase_uid, email, password_hash, user_name, phone_number,
                   role, status, notification_consent_yn, terms_consent_yn,
                   mydata_consent_yn, created_at)
VALUES
    ('test_firebase_001', 'minjun@test.com',  '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '김민준', '01012345678', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_002', 'seoyeon@test.com', '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '이서연', '01023456789', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_003', 'jiho@test.com',    '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '박지호', '01034567890', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_004', 'yujin@test.com',   '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '최유진', '01045678901', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_005', 'suhyun@test.com',  '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '정수현', '01056789012', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_006', 'jieun@test.com',   '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '강지은', '01067890123', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_007', 'minseo@test.com',  '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '조민서', '01078901234', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_008', 'hajun@test.com',   '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '윤하준', '01089012345', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_009', 'chaewon@test.com', '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '임채원', '01090123456', 'USER', 'ACTIVE', true, true, true, NOW()),
    ('test_firebase_010', 'yejin@test.com',   '$2b$10$GtYeMhO44tVhRHMulLRw2OcWUR1YFpRm3vVT1amLQmBCxzLcHDA8.', '한예진', '01011223344', 'USER', 'ACTIVE', true, true, true, NOW())
ON CONFLICT (firebase_uid) DO NOTHING;
