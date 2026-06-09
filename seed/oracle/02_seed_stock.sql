SET DEFINE OFF;
WHENEVER SQLERROR EXIT FAILURE;

-- SECURITIES_ACCOUNT (20건)
-- 한국투자(243): XX000001-01 / NH투자(247): 302-00XX-0001-01
-- MERGE ON ACCOUNT_NUMBER (UNIQUE) → 재실행 보호

MERGE INTO SECURITIES_ACCOUNT t
USING (
    SELECT 1001 AS aid, 22 AS uid, '243' AS bcode, '22000001-01'      AS anum, '한국투자 위탁계좌' AS aname, 2636923 AS cb, 2636923 AS wb FROM DUAL UNION ALL
    SELECT 1002,         22,        '247',           '302-0022-0001-01', 'NH투자 위탁계좌',              1276205,   1276205           FROM DUAL UNION ALL
    SELECT 1003,         23,        '243',           '23000001-01',      '한국투자 위탁계좌',             1173187,   1173187           FROM DUAL UNION ALL
    SELECT 1004,         23,        '247',           '302-0023-0001-01', 'NH투자 위탁계좌',              2146309,   2146309           FROM DUAL UNION ALL
    SELECT 1005,         24,        '243',           '24000001-01',      '한국투자 위탁계좌',             4897210,   4897210           FROM DUAL UNION ALL
    SELECT 1006,         24,        '247',           '302-0024-0001-01', 'NH투자 위탁계좌',              823167,    823167            FROM DUAL UNION ALL
    SELECT 1007,         25,        '243',           '25000001-01',      '한국투자 위탁계좌',             2002798,   2002798           FROM DUAL UNION ALL
    SELECT 1008,         25,        '247',           '302-0025-0001-01', 'NH투자 위탁계좌',              3122051,   3122051           FROM DUAL UNION ALL
    SELECT 1009,         26,        '243',           '26000001-01',      '한국투자 위탁계좌',             378579,    378579            FROM DUAL UNION ALL
    SELECT 1010,         26,        '247',           '302-0026-0001-01', 'NH투자 위탁계좌',              1612470,   1612470           FROM DUAL UNION ALL
    SELECT 1011,         27,        '243',           '27000001-01',      '한국투자 위탁계좌',             7156833,   7156833           FROM DUAL UNION ALL
    SELECT 1012,         27,        '247',           '302-0027-0001-01', 'NH투자 위탁계좌',              1203033,   1203033           FROM DUAL UNION ALL
    SELECT 1013,         28,        '243',           '28000001-01',      '한국투자 위탁계좌',             2904168,   2904168           FROM DUAL UNION ALL
    SELECT 1014,         28,        '247',           '302-0028-0001-01', 'NH투자 위탁계좌',              2992891,   2992891           FROM DUAL UNION ALL
    SELECT 1015,         29,        '243',           '29000001-01',      '한국투자 위탁계좌',             1300514,   1300514           FROM DUAL UNION ALL
    SELECT 1016,         29,        '247',           '302-0029-0001-01', 'NH투자 위탁계좌',              5056086,   5056086           FROM DUAL UNION ALL
    SELECT 1017,         30,        '243',           '30000001-01',      '한국투자 위탁계좌',             1784714,   1784714           FROM DUAL UNION ALL
    SELECT 1018,         30,        '247',           '302-0030-0001-01', 'NH투자 위탁계좌',              555324,    555324            FROM DUAL UNION ALL
    SELECT 1019,         31,        '243',           '31000001-01',      '한국투자 위탁계좌',             5892228,   5892228           FROM DUAL UNION ALL
    SELECT 1020,         31,        '247',           '302-0031-0001-01', 'NH투자 위탁계좌',              2638795,   2638795           FROM DUAL
) s ON (t.ACCOUNT_NUMBER = s.anum)
WHEN NOT MATCHED THEN
    INSERT (SECURITIES_ACCOUNT_ID, USER_ID, BROKER_CODE, ACCOUNT_NUMBER, ACCOUNT_NAME,
            CASH_BALANCE, WITHDRAWABLE_BALANCE, ACCOUNT_STATUS, OPENED_AT, CREATED_AT, UPDATED_AT)
    VALUES (s.aid, s.uid, s.bcode, s.anum, s.aname,
            s.cb, s.wb, 'ACTIVE', TIMESTAMP '2024-01-15 09:00:00', SYSTIMESTAMP, SYSTIMESTAMP);

COMMIT;

-- STOCK_HOLDING (46건)
-- 매입단가: 삼성전자 35,693 / SK하이닉스 812,061 / 카카오 3,262
-- 잔액 큰 계좌(1001,1005,1008,1011,1016,1019) 3종목, 나머지 2종목
-- MERGE ON (SECURITIES_ACCOUNT_ID, STOCK_CODE) → 재실행 보호

MERGE INTO STOCK_HOLDING t
USING (
    SELECT 1001 AS said, '000660' AS scode,  2 AS qty,  812061 AS avg_p,  1624122 AS total_p FROM DUAL UNION ALL
    SELECT 1001,         '005930',           95,          35693,            3390835             FROM DUAL UNION ALL
    SELECT 1001,         '035720',          260,           3262,             848120             FROM DUAL UNION ALL
    SELECT 1002,         '005930',           29,          35693,            1035097             FROM DUAL UNION ALL
    SELECT 1002,         '035720',          579,           3262,            1888698             FROM DUAL UNION ALL
    SELECT 1003,         '005930',           47,          35693,            1677571             FROM DUAL UNION ALL
    SELECT 1003,         '035720',          291,           3262,             949242             FROM DUAL UNION ALL
    SELECT 1004,         '005930',           30,          35693,            1070790             FROM DUAL UNION ALL
    SELECT 1004,         '035720',          241,           3262,             786142             FROM DUAL UNION ALL
    SELECT 1005,         '000660',            1,         812061,             812061             FROM DUAL UNION ALL
    SELECT 1005,         '005930',           40,          35693,            1427720             FROM DUAL UNION ALL
    SELECT 1005,         '035720',          110,           3262,             358820             FROM DUAL UNION ALL
    SELECT 1006,         '005930',            9,          35693,             321237             FROM DUAL UNION ALL
    SELECT 1006,         '035720',           49,           3262,             159838             FROM DUAL UNION ALL
    SELECT 1007,         '005930',           27,          35693,             963711             FROM DUAL UNION ALL
    SELECT 1007,         '035720',          164,           3262,             534968             FROM DUAL UNION ALL
    SELECT 1008,         '000660',            1,         812061,             812061             FROM DUAL UNION ALL
    SELECT 1008,         '005930',           15,          35693,             535395             FROM DUAL UNION ALL
    SELECT 1008,         '035720',          163,           3262,             531706             FROM DUAL UNION ALL
    SELECT 1009,         '005930',            8,          35693,             285544             FROM DUAL UNION ALL
    SELECT 1009,         '035720',           41,           3262,             133742             FROM DUAL UNION ALL
    SELECT 1010,         '005930',           17,          35693,             606781             FROM DUAL UNION ALL
    SELECT 1010,         '035720',           87,           3262,             283794             FROM DUAL UNION ALL
    SELECT 1011,         '000660',            2,         812061,            1624122             FROM DUAL UNION ALL
    SELECT 1011,         '005930',           25,          35693,             892325             FROM DUAL UNION ALL
    SELECT 1011,         '035720',           99,           3262,             322938             FROM DUAL UNION ALL
    SELECT 1012,         '005930',           14,          35693,             499702             FROM DUAL UNION ALL
    SELECT 1012,         '035720',           92,           3262,             300104             FROM DUAL UNION ALL
    SELECT 1013,         '005930',           29,          35693,            1035097             FROM DUAL UNION ALL
    SELECT 1013,         '035720',          172,           3262,             561064             FROM DUAL UNION ALL
    SELECT 1014,         '005930',           27,          35693,             963711             FROM DUAL UNION ALL
    SELECT 1014,         '035720',          167,           3262,             544754             FROM DUAL UNION ALL
    SELECT 1015,         '005930',           16,          35693,             571088             FROM DUAL UNION ALL
    SELECT 1015,         '035720',          101,           3262,             329462             FROM DUAL UNION ALL
    SELECT 1016,         '000660',            1,         812061,             812061             FROM DUAL UNION ALL
    SELECT 1016,         '005930',           33,          35693,            1177869             FROM DUAL UNION ALL
    SELECT 1016,         '035720',          138,           3262,             450156             FROM DUAL UNION ALL
    SELECT 1017,         '005930',           22,          35693,             785246             FROM DUAL UNION ALL
    SELECT 1017,         '035720',          130,           3262,             424060             FROM DUAL UNION ALL
    SELECT 1018,         '005930',            8,          35693,             285544             FROM DUAL UNION ALL
    SELECT 1018,         '035720',           50,           3262,             163100             FROM DUAL UNION ALL
    SELECT 1019,         '000660',            1,         812061,             812061             FROM DUAL UNION ALL
    SELECT 1019,         '005930',           36,          35693,            1284948             FROM DUAL UNION ALL
    SELECT 1019,         '035720',          155,           3262,             505610             FROM DUAL UNION ALL
    SELECT 1020,         '005930',           28,          35693,             999404             FROM DUAL UNION ALL
    SELECT 1020,         '035720',          172,           3262,             561064             FROM DUAL
) s ON (t.SECURITIES_ACCOUNT_ID = s.said AND t.STOCK_CODE = s.scode)
WHEN NOT MATCHED THEN
    INSERT (SECURITIES_ACCOUNT_ID, STOCK_CODE, HOLDING_QUANTITY, AVERAGE_PURCHASE_PRICE,
            TOTAL_PURCHASE_AMOUNT, UPDATED_AT)
    VALUES (s.said, s.scode, s.qty, s.avg_p, s.total_p, SYSTIMESTAMP);

COMMIT;
EXIT;
