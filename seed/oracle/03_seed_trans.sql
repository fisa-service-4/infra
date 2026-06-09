SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE;

-- USER_MASTER (10 rows)
MERGE INTO user_master t
USING (
    SELECT 22 AS uid, 22 AS xuid, 'test_firebase_001' AS fbuid, '김민준' AS uname, '01012345678' AS phone FROM DUAL UNION ALL
    SELECT 23,        23,          'test_firebase_002',          '이서연',        '01023456789'                  FROM DUAL UNION ALL
    SELECT 24,        24,          'test_firebase_003',          '박지호',        '01034567890'                  FROM DUAL UNION ALL
    SELECT 25,        25,          'test_firebase_004',          '최유진',        '01045678901'                  FROM DUAL UNION ALL
    SELECT 26,        26,          'test_firebase_005',          '정수현',        '01056789012'                  FROM DUAL UNION ALL
    SELECT 27,        27,          'test_firebase_006',          '강지은',        '01067890123'                  FROM DUAL UNION ALL
    SELECT 28,        28,          'test_firebase_007',          '조민서',        '01078901234'                  FROM DUAL UNION ALL
    SELECT 29,        29,          'test_firebase_008',          '윤하준',        '01089012345'                  FROM DUAL UNION ALL
    SELECT 30,        30,          'test_firebase_009',          '임채원',        '01090123456'                  FROM DUAL UNION ALL
    SELECT 31,        31,          'test_firebase_010',          '한예진',        '01011223344'                  FROM DUAL
) s ON (t.user_id = s.uid)
WHEN NOT MATCHED THEN
    INSERT (user_id, x_user_id, firebase_uid, user_name, phone_number, linked_at)
    VALUES (s.uid, s.xuid, s.fbuid, s.uname, s.phone, SYSTIMESTAMP);

COMMIT;

-- USER_ACCOUNT_MAPPING (40 rows: BANK 20 + STOCK 20)
MERGE INTO user_account_mapping t
USING (
    SELECT 2001 AS acid, 'BANK'  AS atype, 22 AS uid, 22 AS xuid FROM DUAL UNION ALL
    SELECT 2002,         'BANK',            22,         22              FROM DUAL UNION ALL
    SELECT 2003,         'BANK',            23,         23              FROM DUAL UNION ALL
    SELECT 2004,         'BANK',            23,         23              FROM DUAL UNION ALL
    SELECT 2005,         'BANK',            24,         24              FROM DUAL UNION ALL
    SELECT 2006,         'BANK',            24,         24              FROM DUAL UNION ALL
    SELECT 2007,         'BANK',            25,         25              FROM DUAL UNION ALL
    SELECT 2008,         'BANK',            25,         25              FROM DUAL UNION ALL
    SELECT 2009,         'BANK',            26,         26              FROM DUAL UNION ALL
    SELECT 2010,         'BANK',            26,         26              FROM DUAL UNION ALL
    SELECT 2011,         'BANK',            27,         27              FROM DUAL UNION ALL
    SELECT 2012,         'BANK',            27,         27              FROM DUAL UNION ALL
    SELECT 2013,         'BANK',            28,         28              FROM DUAL UNION ALL
    SELECT 2014,         'BANK',            28,         28              FROM DUAL UNION ALL
    SELECT 2015,         'BANK',            29,         29              FROM DUAL UNION ALL
    SELECT 2016,         'BANK',            29,         29              FROM DUAL UNION ALL
    SELECT 2017,         'BANK',            30,         30              FROM DUAL UNION ALL
    SELECT 2018,         'BANK',            30,         30              FROM DUAL UNION ALL
    SELECT 2019,         'BANK',            31,         31              FROM DUAL UNION ALL
    SELECT 2020,         'BANK',            31,         31              FROM DUAL UNION ALL
    SELECT 1001,         'STOCK',           22,         22              FROM DUAL UNION ALL
    SELECT 1002,         'STOCK',           22,         22              FROM DUAL UNION ALL
    SELECT 1003,         'STOCK',           23,         23              FROM DUAL UNION ALL
    SELECT 1004,         'STOCK',           23,         23              FROM DUAL UNION ALL
    SELECT 1005,         'STOCK',           24,         24              FROM DUAL UNION ALL
    SELECT 1006,         'STOCK',           24,         24              FROM DUAL UNION ALL
    SELECT 1007,         'STOCK',           25,         25              FROM DUAL UNION ALL
    SELECT 1008,         'STOCK',           25,         25              FROM DUAL UNION ALL
    SELECT 1009,         'STOCK',           26,         26              FROM DUAL UNION ALL
    SELECT 1010,         'STOCK',           26,         26              FROM DUAL UNION ALL
    SELECT 1011,         'STOCK',           27,         27              FROM DUAL UNION ALL
    SELECT 1012,         'STOCK',           27,         27              FROM DUAL UNION ALL
    SELECT 1013,         'STOCK',           28,         28              FROM DUAL UNION ALL
    SELECT 1014,         'STOCK',           28,         28              FROM DUAL UNION ALL
    SELECT 1015,         'STOCK',           29,         29              FROM DUAL UNION ALL
    SELECT 1016,         'STOCK',           29,         29              FROM DUAL UNION ALL
    SELECT 1017,         'STOCK',           30,         30              FROM DUAL UNION ALL
    SELECT 1018,         'STOCK',           30,         30              FROM DUAL UNION ALL
    SELECT 1019,         'STOCK',           31,         31              FROM DUAL UNION ALL
    SELECT 1020,         'STOCK',           31,         31              FROM DUAL
) s ON (t.account_id = s.acid AND t.account_type = s.atype)
WHEN NOT MATCHED THEN
    INSERT (account_id, account_type, user_id, x_user_id)
    VALUES (s.acid, s.atype, s.uid, s.xuid);

COMMIT;
EXIT;
