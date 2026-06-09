# DB 시드 데이터 적재 가이드

볼륨 초기화 후 테스트 사용자 10명(user_id 22~31)과 관련 금융 데이터를 재현하는 스크립트입니다.

---

## 스크립트 목록

| 스크립트               | 실행 위치                              | 대상 컨테이너                          |
|----------------------|--------------------------------------|--------------------------------------|
| `seed-test-app.sh`   | OpenStack 인스턴스 1 (docker-compose-app)  | `postgres` / `finance`               |
| `seed-test-core.sh`  | OpenStack 인스턴스 2 (docker-compose-core) | `oracle` / `XEPDB1`                  |
| `seed-local.sh`      | 로컬 (docker-compose-onpremise)        | `postgres-operational` + `oracle-onpremise` |

---

## 전제 조건

- Docker 컨테이너가 모두 **실행 중**이어야 합니다.
- Oracle 컨테이너는 **healthy** 상태여야 합니다 (`docker ps`로 확인).
- `infra` 레포를 각 서버에서 `git pull` 한 뒤 실행하세요.

---

## OpenStack 인스턴스 2 — PostgreSQL (docker-compose-app)

```bash
cd ~/infra
git pull origin develop
cd seed
bash seed-test-app.sh
```

**적재 확인**

```bash
docker exec -i postgres psql -U admin -d finance \
  -c "SELECT user_id, user_name, email FROM users WHERE user_id BETWEEN 22 AND 31;"
```

---

## OpenStack 인스턴스 1 — Oracle (docker-compose-core)

```bash
cd ~/infra
git pull origin develop
cd seed
bash seed-test-core.sh
```

**적재 확인**

```bash
# 은행 계좌
docker exec -i oracle sqlplus -S BANK/bank123@XEPDB1 <<'EOF'
SELECT ACCOUNT_ID, USER_ID, BANK_CODE, BALANCE FROM BANK_ACCOUNT
WHERE ACCOUNT_ID BETWEEN 2001 AND 2020;
EXIT;
EOF

# 증권 계좌
docker exec -i oracle sqlplus -S STOCK/stock123@XEPDB1 <<'EOF'
SELECT SECURITIES_ACCOUNT_ID, USER_ID, BROKER_CODE, CASH_BALANCE FROM SECURITIES_ACCOUNT
WHERE SECURITIES_ACCOUNT_ID BETWEEN 1001 AND 1020;
EXIT;
EOF

# TRANS 매핑
docker exec -i oracle sqlplus -S TRANS/trans123@XEPDB1 <<'EOF'
SELECT user_id, user_name, phone_number FROM user_master ORDER BY user_id;
EXIT;
EOF
```

---

## 로컬 — PostgreSQL + Oracle (docker-compose-onpremise)

로컬은 두 DB가 같은 머신에 있으므로 스크립트 하나로 실행합니다.

```bash
cd ~/infra/seed
bash seed-local.sh
```

**적재 확인**

```bash
# PostgreSQL
docker exec -i postgres-operational psql -U admin -d finance_operational \
  -c "SELECT user_id, user_name, email FROM users WHERE user_id BETWEEN 22 AND 31;"

# Oracle
docker exec -i oracle-onpremise sqlplus -S BANK/bank123@XEPDB1 <<'EOF'
SELECT ACCOUNT_ID, USER_ID, BALANCE FROM BANK_ACCOUNT WHERE ACCOUNT_ID BETWEEN 2001 AND 2020;
EXIT;
EOF
```

---

## 실행 순서 (전체)

```
[인스턴스 1 / 로컬]          [인스턴스 2 / 로컬]
Oracle                        PostgreSQL
─────────────────────         ─────────────────────
01_seed_bank.sql              00_alter_schema.sql
02_seed_stock.sql             01_seed_users.sql
03_seed_trans.sql             02_seed_user_profile.sql
                              03_seed_pin_auth.sql
                              04_seed_virtual_salary.sql
                              05_seed_linked_accounts.sql
```

> PostgreSQL과 Oracle은 순서 의존성이 없으므로 두 인스턴스에서 동시에 실행해도 됩니다.

---

## 재실행 (idempotent)

스크립트는 몇 번을 실행해도 중복 삽입되지 않습니다.

| 테이블                         | 충돌 방지 전략                                              |
|------------------------------|----------------------------------------------------------|
| PostgreSQL USERS             | `ON CONFLICT (firebase_uid) DO NOTHING`                  |
| PostgreSQL USER_PROFILE 등   | `ON CONFLICT (user_id) DO NOTHING`                       |
| PostgreSQL LINKED_FINANCIAL_ACCOUNT | `WHERE NOT EXISTS (...)`                          |
| Oracle BANK_ACCOUNT          | `MERGE INTO ... ON (ACCOUNT_NUMBER)`                     |
| Oracle SECURITIES_ACCOUNT    | `MERGE INTO ... ON (ACCOUNT_NUMBER)`                     |
| Oracle STOCK_HOLDING         | `MERGE INTO ... ON (SECURITIES_ACCOUNT_ID, STOCK_CODE)`  |
| Oracle USER_MASTER           | `MERGE INTO ... ON (user_id)`                            |
| Oracle USER_ACCOUNT_MAPPING  | `MERGE INTO ... ON (account_id, account_type)`           |

---

## 적재 데이터 요약

### 테스트 계정 (10명)

| user_id | 이름   | 이메일             | 비밀번호      | PIN    |
|---------|--------|------------------|-----------|--------|
| 22      | 김민준  | minjun@test.com  | Test1234! | 192837 |
| 23      | 이서연  | seoyeon@test.com | Test1234! | 192837 |
| 24      | 박지호  | jiho@test.com    | Test1234! | 192837 |
| 25      | 최유진  | yujin@test.com   | Test1234! | 192837 |
| 26      | 정수현  | suhyun@test.com  | Test1234! | 192837 |
| 27      | 강지은  | jieun@test.com   | Test1234! | 192837 |
| 28      | 조민서  | minseo@test.com  | Test1234! | 192837 |
| 29      | 윤하준  | hajun@test.com   | Test1234! | 192837 |
| 30      | 임채원  | chaewon@test.com | Test1234! | 192837 |
| 31      | 한예진  | yejin@test.com   | Test1234! | 192837 |

> **주의**: 테스트 전용 계정입니다. 운영 환경에 절대 사용 금지.

### 금융 계좌

| 종류              | 건수  | 계좌 ID 범위       | 스키마         |
|-----------------|------|-----------------|--------------|
| 은행 계좌          | 20건  | 2001 ~ 2020     | Oracle BANK  |
| 증권 계좌          | 20건  | 1001 ~ 1020     | Oracle STOCK |
| 보유 종목          | 46건  | (계좌별 2~3종목)  | Oracle STOCK |
| TRANS 매핑        | 40건  | -               | Oracle TRANS |
| 연결 계좌 (PG)     | 40건  | -               | PostgreSQL   |

### 보유 종목 기준가 (매입단가)

| 종목명     | 종목코드   | 매입단가      |
|----------|--------|------------|
| 삼성전자   | 005930 | 35,693원   |
| SK하이닉스  | 000660 | 812,061원  |
| 카카오     | 035720 | 3,262원    |

> 잔액이 큰 계좌(1001, 1005, 1008, 1011, 1016, 1019)는 SK하이닉스 포함 3종목, 나머지는 2종목.

---

## 문제 해결

### Oracle 컨테이너가 준비되지 않은 경우

```bash
# STATUS(healthy) 확인 후 실행
docker ps | grep oracle
```

### psql에서 `$` 기호 오류

`-c` 옵션으로 BCrypt 해시를 직접 전달하면 쉘이 `$`를 변수로 인식해 해시가 깨집니다.
반드시 `-f -` + 파일 리다이렉트 방식을 사용하세요 (스크립트가 이미 이 방식으로 동작합니다).

```bash
# 올바른 방법
docker exec -i postgres psql -U admin -d finance -f - < postgres/01_seed_users.sql
```

### 특정 파일만 재실행

```bash
# PostgreSQL 단일 파일 (인스턴스 1)
docker exec -i postgres psql -U admin -d finance -f - < seed/postgres/03_seed_pin_auth.sql

# Oracle 단일 파일 (인스턴스 2)
docker exec -i oracle sqlplus -S BANK/bank123@XEPDB1 < seed/oracle/01_seed_bank.sql
```
