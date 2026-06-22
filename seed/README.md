# DB 시드 데이터 적재 가이드

볼륨 초기화 후 테스트 사용자 10명과 관련 금융 데이터를 재현하는 스크립트입니다.

---

## 스크립트 목록

| 스크립트               | 환경                                        | 대상 DB                                      |
|----------------------|---------------------------------------------|----------------------------------------------|
| `seed-local-total.sh`| 로컬 (docker-compose-onpremise)             | `postgres-operational` + `oracle-onpremise`  |
| `seed-test-app.sh`   | OpenStack 인스턴스 1 (docker-compose-app)   | `postgres` / `finance`                       |
| `seed-test-core.sh`  | OpenStack 인스턴스 2 (docker-compose-core)  | `oracle` / `XEPDB1`                          |
| `seed-prod-core.sh`  | Core 온프레미스 서버 (docker-compose-prod-core) | `oracle` / `XEPDB1`                      |
| `seed-prod-rds.sh`   | APP EC2 서버 (docker-compose-prod-app)      | AWS RDS PostgreSQL                           |

---

## 로컬 실행 방법 (docker-compose-onpremise)

### 전제 조건

1. `docker-compose-onpremise.yml`로 전체 컨테이너 기동
2. **`service-backend`가 완전히 기동되어야 JPA가 PostgreSQL 스키마를 생성합니다** — seed 실행 전 확인 필요
3. Oracle이 `healthy` 상태여야 합니다 (`docker ps`에서 `(healthy)` 확인)

```bash
# 컨테이너 상태 확인
docker ps | grep -E "service-backend|oracle-onpremise"
```

### 실행

```bash
# infra 루트에서 실행
bash seed/seed-local-total.sh
```

스크립트가 `service-backend` 기동을 감지할 때까지 자동 대기합니다(최대 2분).

### 적재 확인

```bash
# PostgreSQL
docker exec postgres-operational psql -U admin -d finance_operational \
  -c "SELECT email, user_name FROM users ORDER BY created_at;"

# Oracle — 은행 계좌
docker exec -i oracle-onpremise sqlplus -S BANK/bank123@XEPDB1 <<'EOF'
SELECT ACCOUNT_ID, USER_ID, ACCOUNT_NUMBER, BALANCE FROM BANK_ACCOUNT
WHERE ACCOUNT_ID BETWEEN 2001 AND 2028
ORDER BY ACCOUNT_ID;
EXIT;
EOF
```

---

## OpenStack 테스트 환경 실행 방법

```bash
# 인스턴스 1 — Oracle
bash seed/seed-test-core.sh

# 인스턴스 2 — PostgreSQL
bash seed/seed-test-app.sh
```

---

## 테스트 계정 (10명)

> 비밀번호와 PIN은 모든 계정 동일합니다.

| Oracle USER_ID | firebase_uid         | 이름   | 이메일              | 비밀번호    | PIN    | 직업         | 프리랜서 | 통신사 |
|:--------------:|----------------------|--------|---------------------|------------|--------|--------------|:--------:|--------|
| 22             | test_firebase_001    | 김민준  | minjun@test.com     | Test1234!  | 192837 | DEVELOPER    | Y        | SKT    |
| 23             | test_firebase_002    | 이서연  | seoyeon@test.com    | Test1234!  | 192837 | DESIGNER     | Y        | KT     |
| 24             | test_firebase_003    | 박지호  | jiho@test.com       | Test1234!  | 192837 | MARKETER     | N        | LGU+   |
| 25             | test_firebase_004    | 최유진  | yujin@test.com      | Test1234!  | 192837 | DEVELOPER    | Y        | SKT    |
| 26             | test_firebase_005    | 정수현  | suhyun@test.com     | Test1234!  | 192837 | WRITER       | Y        | KT     |
| 27             | test_firebase_006    | 강지은  | jieun@test.com      | Test1234!  | 192837 | PHOTOGRAPHER | Y        | LGU+   |
| 28             | test_firebase_007    | 조민서  | minseo@test.com     | Test1234!  | 192837 | DEVELOPER    | N        | SKT    |
| 29             | test_firebase_008    | 윤하준  | hajun@test.com      | Test1234!  | 192837 | TRANSLATOR   | Y        | KT     |
| 30             | test_firebase_009    | 임채원  | chaewon@test.com    | Test1234!  | 192837 | DESIGNER     | Y        | LGU+   |
| 31             | test_firebase_010    | 한예진  | yejin@test.com      | Test1234!  | 192837 | MARKETER     | N        | SKT    |

> **Oracle USER_ID(22~31)는 Oracle 스키마에 하드코딩된 값입니다.**
> PostgreSQL의 `user_id`는 시퀀스 자동 생성이므로 환경마다 다릅니다.
> `SELECT user_id FROM users WHERE email = 'xxx@test.com';` 으로 확인하세요.

---

## 은행 계좌 (Oracle BANK 스키마)

### 완전 구성된 사용자 (5명) — 4개 계좌 + 카드

| Oracle USER_ID | 이름   | 계좌 ID | 계좌번호          | 은행        | 종류(역할)    | 잔액(초기)      |
|:--------------:|--------|:-------:|-------------------|-------------|--------------|---------------:|
| 22             | 김민준  | 2001    | 110-22-000001     | 신한 (088)  | 수입계좌      | 1,000,000      |
| 22             | 김민준  | 2002    | 1002-22-000001    | 우리 (020)  | 생활비계좌    | 825,620        |
| 22             | 김민준  | 2003    | 110-22-000002     | 신한 (088)  | 비상금계좌    | 1,500,000      |
| 22             | 김민준  | 2004    | 110-22-000003     | 신한 (088)  | 투자계좌      | 4,000,000      |
| 23             | 이서연  | 2005    | 110-23-000001     | 신한 (088)  | 수입계좌      | 1,900,000      |
| 23             | 이서연  | 2006    | 1002-23-000001    | 우리 (020)  | 생활비계좌    | 644,820        |
| 23             | 이서연  | 2007    | 110-23-000002     | 신한 (088)  | 비상금계좌    | 400,000        |
| 23             | 이서연  | 2008    | 110-23-000003     | 신한 (088)  | 투자계좌      | 400,000        |
| 25             | 최유진  | 2009    | 110-25-000001     | 신한 (088)  | 수입계좌      | 5,000,000      |
| 25             | 최유진  | 2010    | 1002-25-000001    | 우리 (020)  | 생활비계좌    | 946,440        |
| 25             | 최유진  | 2011    | 110-25-000002     | 신한 (088)  | 비상금계좌    | 1,000,000      |
| 25             | 최유진  | 2012    | 110-25-000003     | 신한 (088)  | 투자계좌      | 700,000        |
| 26             | 정수현  | 2013    | 110-26-000001     | 신한 (088)  | 수입계좌      | 5,700,000      |
| 26             | 정수현  | 2014    | 1002-26-000001    | 우리 (020)  | 생활비계좌    | 811,300        |
| 26             | 정수현  | 2015    | 110-26-000002     | 신한 (088)  | 비상금계좌    | 1,900,000      |
| 26             | 정수현  | 2016    | 110-26-000003     | 신한 (088)  | 투자계좌      | 3,300,000      |
| 28             | 조민서  | 2025    | 110-28-000001     | 신한 (088)  | 수입계좌      | 14,500,000     |
| 28             | 조민서  | 2026    | 1002-28-000001    | 우리 (020)  | 생활비계좌    | 2,969,950      |
| 28             | 조민서  | 2027    | 110-28-000002     | 신한 (088)  | 비상금계좌    | 7,500,000      |
| 28             | 조민서  | 2028    | 110-28-000003     | 신한 (088)  | 투자계좌      | 71,000,000     |

### 기본 구성 사용자 (5명) — 2개 계좌, 카드 없음

| Oracle USER_ID | 이름   | 계좌 ID | 계좌번호          | 은행        | 잔액(초기)   |
|:--------------:|--------|:-------:|-------------------|-------------|-------------:|
| 24             | 박지호  | 3001    | 110-024-000001    | 신한 (088)  | 4,680,000    |
| 24             | 박지호  | 3002    | 1002-024-000001   | 우리 (020)  | 1,230,000    |
| 27             | 강지은  | 3003    | 110-027-000001    | 신한 (088)  | 1,870,000    |
| 27             | 강지은  | 3004    | 1002-027-000001   | 우리 (020)  | 3,200,000    |
| 29             | 윤하준  | 3005    | 110-029-000001    | 신한 (088)  | 720,000      |
| 29             | 윤하준  | 3006    | 1002-029-000001   | 우리 (020)  | 1,560,000    |
| 30             | 임채원  | 3007    | 110-030-000001    | 신한 (088)  | 2,940,000    |
| 30             | 임채원  | 3008    | 1002-030-000001   | 우리 (020)  | 410,000      |
| 31             | 한예진  | 3009    | 110-031-000001    | 신한 (088)  | 1,650,000    |
| 31             | 한예진  | 3010    | 1002-031-000001   | 우리 (020)  | 2,870,000    |

---

## 증권 계좌 (Oracle STOCK 스키마)

전체 10명 각 2개씩 (한국투자 + NH투자) — 총 20건

| Oracle USER_ID | 이름   | 계좌 ID | 계좌번호             | 증권사            |
|:--------------:|--------|:-------:|----------------------|-------------------|
| 22             | 김민준  | 1001    | 22000001-01          | 한국투자 (243)    |
| 22             | 김민준  | 1002    | 302-0022-0001-01     | NH투자 (247)      |
| 23             | 이서연  | 1003    | 23000001-01          | 한국투자 (243)    |
| 23             | 이서연  | 1004    | 302-0023-0001-01     | NH투자 (247)      |
| 24             | 박지호  | 1005    | 24000001-01          | 한국투자 (243)    |
| 24             | 박지호  | 1006    | 302-0024-0001-01     | NH투자 (247)      |
| 25             | 최유진  | 1007    | 25000001-01          | 한국투자 (243)    |
| 25             | 최유진  | 1008    | 302-0025-0001-01     | NH투자 (247)      |
| 26             | 정수현  | 1009    | 26000001-01          | 한국투자 (243)    |
| 26             | 정수현  | 1010    | 302-0026-0001-01     | NH투자 (247)      |
| 27             | 강지은  | 1011    | 27000001-01          | 한국투자 (243)    |
| 27             | 강지은  | 1012    | 302-0027-0001-01     | NH투자 (247)      |
| 28             | 조민서  | 1013    | 28000001-01          | 한국투자 (243)    |
| 28             | 조민서  | 1014    | 302-0028-0001-01     | NH투자 (247)      |
| 29             | 윤하준  | 1015    | 29000001-01          | 한국투자 (243)    |
| 29             | 윤하준  | 1016    | 302-0029-0001-01     | NH투자 (247)      |
| 30             | 임채원  | 1017    | 30000001-01          | 한국투자 (243)    |
| 30             | 임채원  | 1018    | 302-0030-0001-01     | NH투자 (247)      |
| 31             | 한예진  | 1019    | 31000001-01          | 한국투자 (243)    |
| 31             | 한예진  | 1020    | 302-0031-0001-01     | NH투자 (247)      |

### 보유 종목 기준가 (매입단가)

| 종목명    | 종목코드   | 매입단가      |
|----------|------------|-------------:|
| 삼성전자  | 005930     | 35,693원     |
| SK하이닉스| 000660     | 812,061원    |
| 카카오   | 035720     | 3,262원      |

> 잔액이 큰 계좌(1001, 1005, 1008, 1011, 1016, 1019)는 SK하이닉스 포함 3종목, 나머지는 2종목.

---

## 카드 (Oracle CARD 스키마)

완전 구성된 5명만 카드가 있습니다. 카드는 각 사용자의 **생활비계좌(우리은행)**에 연결됩니다.

| Oracle USER_ID | 이름   | card_id | 카드번호              | 연결 계좌 ID |
|:--------------:|--------|:-------:|-----------------------|:-----------:|
| 22             | 김민준  | 2022    | 9400-0022-0000-0001   | 2002        |
| 23             | 이서연  | 2023    | 9400-0023-0000-0001   | 2006        |
| 25             | 최유진  | 2025    | 9400-0025-0000-0001   | 2010        |
| 26             | 정수현  | 2026    | 9400-0026-0000-0001   | 2014        |
| 28             | 조민서  | 2028    | 9400-0028-0000-0001   | 2026        |

---

## 계좌 역할 매핑 (PostgreSQL — account_mapping)

완전 구성된 5명만 `account_mapping` 테이블에 역할이 등록됩니다.

| firebase_uid      | 이름   | INCOME (수입) | SALARY (생활비) | EMERGENCY (비상금) | STOCK (투자) |
|-------------------|--------|:------------:|:---------------:|:-----------------:|:-----------:|
| test_firebase_001 | 김민준  | 2001         | 2002            | 2003              | 2004        |
| test_firebase_002 | 이서연  | 2005         | 2006            | 2007              | 2008        |
| test_firebase_004 | 최유진  | 2009         | 2010            | 2011              | 2012        |
| test_firebase_005 | 정수현  | 2013         | 2014            | 2015              | 2016        |
| test_firebase_007 | 조민서  | 2025         | 2026            | 2027              | 2028        |

---

## 가상 급여 설정 (PostgreSQL — virtual_salary_setting)

완전 구성된 5명만 설정이 있습니다.

| firebase_uid      | 이름   | 목표 급여(원)  | 급여일 | 비상금 목표(원) |
|-------------------|--------|---------------:|:------:|---------------:|
| test_firebase_001 | 김민준  | 1,500,000      | 25일   | 7,000,000      |
| test_firebase_002 | 이서연  | 1,200,000      | 25일   | 5,000,000      |
| test_firebase_004 | 최유진  | 1,800,000      | 25일   | 6,500,000      |
| test_firebase_005 | 정수현  | 1,700,000      | 25일   | 5,000,000      |
| test_firebase_007 | 조민서  | 3,000,000      | 25일   | 6,000,000      |

---

## 계약 (PostgreSQL — contract)

완전 구성된 5명이 각 3건의 계약을 보유합니다. 모두 `PAID` 상태, 세율 3.3% (조민서는 해외 계약 0%).

| contract_id | firebase_uid      | 이름   | 거래처              | 금액(원)   | 실수령액(원) | 지급일      |
|:-----------:|-------------------|--------|---------------------|----------:|-------------:|-------------|
| 2201        | test_firebase_001 | 김민준  | A사                 | 3,000,000 | 2,901,000   | 2026-03-15  |
| 2202        | test_firebase_001 | 김민준  | B사                 | 4,500,000 | 4,351,500   | 2026-04-10  |
| 2203        | test_firebase_001 | 김민준  | C사(유지보수)        | 2,500,000 | 2,417,500   | 2026-05-12  |
| 2301        | test_firebase_002 | 이서연  | 소규모 쇼핑몰        | 1,200,000 | 1,160,400   | 2026-03-05  |
| 2302        | test_firebase_002 | 이서연  | 스타트업A            | 4,500,000 | 4,351,500   | 2026-05-08  |
| 2303        | test_firebase_002 | 이서연  | B사(배너)            | 800,000   | 773,600     | 2026-06-02  |
| 2501        | test_firebase_004 | 최유진  | 패션브랜드A          | 3,500,000 | 3,384,500   | 2026-03-07  |
| 2502        | test_firebase_004 | 최유진  | 쇼핑몰B              | 4,800,000 | 4,641,600   | 2026-04-11  |
| 2503        | test_firebase_004 | 최유진  | 랜딩페이지C          | 2,700,000 | 2,610,900   | 2026-05-15  |
| 2601        | test_firebase_005 | 정수현  | 부트캠프 운영사       | 7,000,000 | 6,769,000   | 2026-06-05  |
| 2602        | test_firebase_005 | 정수현  | 기업교육센터          | 1,500,000 | 1,450,500   | 2026-07-12  |
| 2603        | test_firebase_005 | 정수현  | 온라인플랫폼          | 800,000   | 773,600     | 2026-08-08  |
| 2801        | test_firebase_007 | 조민서  | 미국 SaaS 스타트업   | 12,000,000| 12,000,000  | 2026-03-04  |
| 2802        | test_firebase_007 | 조민서  | 미국 핀테크 기업      | 15,000,000| 15,000,000  | 2026-04-05  |
| 2803        | test_firebase_007 | 조민서  | 고객사 유지보수       | 10,000,000| 10,000,000  | 2026-05-06  |

> 조민서(test_firebase_007)는 해외 기업 계약으로 세율 0% (원천징수 없음)

---

## 재실행 안전성 (idempotent)

스크립트는 몇 번을 실행해도 중복 삽입되지 않습니다.

| 테이블                          | 충돌 방지 전략                                         |
|-------------------------------|------------------------------------------------------|
| PostgreSQL `users`            | `ON CONFLICT (firebase_uid) DO NOTHING`              |
| PostgreSQL `user_profile` 등  | `ON CONFLICT (user_id) DO NOTHING`                   |
| PostgreSQL `linked_financial_account` | `WHERE NOT EXISTS (...)`                    |
| PostgreSQL `contract`         | `ON CONFLICT (contract_id) DO NOTHING`               |
| Oracle `BANK_ACCOUNT`         | `MERGE INTO ... ON (ACCOUNT_ID)`                     |
| Oracle `SECURITIES_ACCOUNT`   | `MERGE INTO ... ON (ACCOUNT_NUMBER)`                 |
| Oracle `STOCK_HOLDING`        | `MERGE INTO ... ON (SECURITIES_ACCOUNT_ID, STOCK_CODE)` |
| Oracle `CARD_MASTER`          | `MERGE INTO ... ON (CARD_ID)`                        |
| Oracle `USER_MASTER`          | `MERGE INTO ... ON (user_id)`                        |

---

## 데이터 검증 쿼리

```bash
# PostgreSQL — 전체 유저 확인
docker exec postgres-operational psql -U admin -d finance_operational \
  -c "SELECT user_id, user_name, email FROM users ORDER BY user_id;"

# PostgreSQL — 계좌 매핑 확인
docker exec postgres-operational psql -U admin -d finance_operational \
  -c "SELECT u.user_name, am.mapping_type, lfa.external_account_id
      FROM account_mapping am
      JOIN users u ON u.user_id = am.user_id
      JOIN linked_financial_account lfa ON lfa.linked_account_id = am.linked_account_id
      ORDER BY u.user_name, am.mapping_type;"

# Oracle — 은행 계좌 잔액
docker exec -i oracle-onpremise sqlplus -S BANK/bank123@XEPDB1 <<'EOF'
SELECT ACCOUNT_ID, USER_ID, ACCOUNT_NUMBER, BALANCE FROM BANK_ACCOUNT
WHERE ACCOUNT_ID IN (2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,
                     2011,2012,2013,2014,2015,2016,2025,2026,2027,2028)
ORDER BY ACCOUNT_ID;
EXIT;
EOF

# Oracle — 카드 목록
docker exec -i oracle-onpremise sqlplus -S CARD/card123@XEPDB1 <<'EOF'
SELECT CARD_ID, USER_ID, CARD_NUMBER, LINKED_ACCOUNT_ID, CARD_STATUS
FROM CARD_MASTER ORDER BY CARD_ID;
EXIT;
EOF

# Oracle — 증권 계좌 및 보유 종목
docker exec -i oracle-onpremise sqlplus -S STOCK/stock123@XEPDB1 <<'EOF'
SELECT s.SECURITIES_ACCOUNT_ID, s.USER_ID, s.ACCOUNT_NUMBER, h.STOCK_CODE,
       h.HOLDING_QUANTITY, h.AVERAGE_PURCHASE_PRICE
FROM SECURITIES_ACCOUNT s
JOIN STOCK_HOLDING h ON h.SECURITIES_ACCOUNT_ID = s.SECURITIES_ACCOUNT_ID
ORDER BY s.SECURITIES_ACCOUNT_ID, h.STOCK_CODE;
EXIT;
EOF
```

---

## 문제 해결

### Oracle이 준비되지 않은 경우

```bash
docker ps | grep oracle-onpremise
# STATUS 열에 (healthy) 가 나올 때까지 대기
```

### PostgreSQL 스키마가 없는 경우

```
ERROR: relation "users" does not exist
```

`service-backend`가 아직 실행 중이지 않거나 초기화가 완료되지 않은 것입니다.

```bash
docker compose -f docker-compose-onpremise.yml up service-backend -d
# 로그 확인 — "Started ServiceBackendApplication" 메시지 대기
docker logs service-backend --tail 20
```

### 특정 파일만 재실행 (로컬)

```bash
# PostgreSQL 단일 파일
sed 's/SET search_path TO operational/SET search_path TO public/g' \
  seed/postgres/01_seed_users.sql | \
  docker exec -i postgres-operational psql -U admin -d finance_operational -f -

# Oracle 단일 파일
docker exec -i -e NLS_LANG="KOREAN_KOREA.AL32UTF8" oracle-onpremise \
  sqlplus -S BANK/bank123@XEPDB1 < seed/oracle/01_seed_bank.sql
```
