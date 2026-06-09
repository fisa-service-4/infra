-- BANK 스키마 시드 (BANK 유저로 실행)
-- BANK_ACCOUNT 20건 (ACCOUNT_ID 2001~2020)
-- 신한(088): 110-0XX-000001 / 우리(020): 1002-0XX-000001
-- MERGE ON ACCOUNT_NUMBER (UNIQUE) → 재실행 보호
SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE;

MERGE INTO BANK_ACCOUNT t
USING (
    SELECT 2001 AS aid, 22 AS uid, '088' AS bcode, '110-022-000001'  AS anum, '신한 입출금계좌' AS aname, 2250000   AS bal FROM DUAL UNION ALL
    SELECT 2002,         22,        '020',            '1002-022-000001', '우리 입출금계좌',           780000            FROM DUAL UNION ALL
    SELECT 2003,         23,        '088',            '110-023-000001',  '신한 입출금계좌',           1120000           FROM DUAL UNION ALL
    SELECT 2004,         23,        '020',            '1002-023-000001', '우리 입출금계좌',           550000            FROM DUAL UNION ALL
    SELECT 2005,         24,        '088',            '110-024-000001',  '신한 입출금계좌',           4680000           FROM DUAL UNION ALL
    SELECT 2006,         24,        '020',            '1002-024-000001', '우리 입출금계좌',           1230000           FROM DUAL UNION ALL
    SELECT 2007,         25,        '088',            '110-025-000001',  '신한 입출금계좌',           890000            FROM DUAL UNION ALL
    SELECT 2008,         25,        '020',            '1002-025-000001', '우리 입출금계좌',           2100000           FROM DUAL UNION ALL
    SELECT 2009,         26,        '088',            '110-026-000001',  '신한 입출금계좌',           3450000           FROM DUAL UNION ALL
    SELECT 2010,         26,        '020',            '1002-026-000001', '우리 입출금계좌',           670000            FROM DUAL UNION ALL
    SELECT 2011,         27,        '088',            '110-027-000001',  '신한 입출금계좌',           1870000           FROM DUAL UNION ALL
    SELECT 2012,         27,        '020',            '1002-027-000001', '우리 입출금계좌',           3200000           FROM DUAL UNION ALL
    SELECT 2013,         28,        '088',            '110-028-000001',  '신한 입출금계좌',           5120000           FROM DUAL UNION ALL
    SELECT 2014,         28,        '020',            '1002-028-000001', '우리 입출금계좌',           980000            FROM DUAL UNION ALL
    SELECT 2015,         29,        '088',            '110-029-000001',  '신한 입출금계좌',           720000            FROM DUAL UNION ALL
    SELECT 2016,         29,        '020',            '1002-029-000001', '우리 입출금계좌',           1560000           FROM DUAL UNION ALL
    SELECT 2017,         30,        '088',            '110-030-000001',  '신한 입출금계좌',           2940000           FROM DUAL UNION ALL
    SELECT 2018,         30,        '020',            '1002-030-000001', '우리 입출금계좌',           410000            FROM DUAL UNION ALL
    SELECT 2019,         31,        '088',            '110-031-000001',  '신한 입출금계좌',           1650000           FROM DUAL UNION ALL
    SELECT 2020,         31,        '020',            '1002-031-000001', '우리 입출금계좌',           2870000           FROM DUAL
) s ON (t.ACCOUNT_NUMBER = s.anum)
WHEN NOT MATCHED THEN
    INSERT (ACCOUNT_ID, USER_ID, BANK_CODE, ACCOUNT_NUMBER, ACCOUNT_NAME,
            BALANCE, ACCOUNT_STATUS, OPENED_AT)
    VALUES (s.aid, s.uid, s.bcode, s.anum, s.aname,
            s.bal, 'ACTIVE', TIMESTAMP '2024-01-15 09:00:00');

COMMIT;
EXIT;
