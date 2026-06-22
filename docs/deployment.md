# 배포 운영 가이드

> 개발(로컬/온프레미스 테스트) 환경 기준.  
> 운영(AWS) 배포는 [AWS-DEPLOY.md](./AWS-DEPLOY.md) 참고.

---

## 1. 시스템 구성 개요

```
클라이언트
    ↓
service-frontend (3000)
    ↓
service-backend (8080)  ─────────────────────────────────────────────┐
mydata-server   (8084)  ─── extra_hosts → transaction-server:8083   │
                                                ↓                    │
                                     transaction-server (8083)       │
                                       ├─ bank-server   (8081)       │
                                       └─ stock-server  (8082)       │
                                                ↓                    │
                                            Oracle DB (1521)         │
                                                                      │
                              PostgreSQL (5432) ←────────────────────┘
                              Redis      (6379)
```

### 환경 분리

| 구분 | 위치 | Docker Compose | 주요 서비스 |
|------|------|----------------|-------------|
| **core** (온프레미스) | 온프레미스 서버 | `docker-compose-core.yml` | oracle, kafka, bank-server, stock-server, transaction-server |
| **app** (클라우드) | AWS EC2 | `docker-compose-app.yml` | postgres, redis, service-backend, service-ai-server, mydata-server, service-frontend |

---

## 2. 서비스별 포트 및 프로파일

| 서비스 | 포트 | Spring Profile | DB |
|--------|------|----------------|----|
| service-frontend | 3000 | - | - |
| service-backend | 8080 | `app` | PostgreSQL (5432) |
| service-ai-server | 8000 | - | PostgreSQL (5432, pgvector) |
| mydata-server | 8084 | `app` | - (외부 API 집계) |
| transaction-server | 8083 | `core` | Oracle (1521) |
| bank-server | 8081 | `core` | Oracle (1521) |
| stock-server | 8082 | `core` | Oracle (1521) |
| kafka | 9092 | - | - |
| kafka-ui | 8085 | - | - |

### 서버 간 호출 흐름

```
service-backend / mydata-server
  → extra_hosts: transaction-server:10.10.4.107
  → transaction-server:8083 (/baas/v1/*)

transaction-server
  → bank-server:8081    (/internal/v1/bank/*)
  → stock-server:8082   (/internal/v1/stock/*)
```

---

## 3. 개발 환경 기동 순서

### 3-1. Core (온프레미스) 기동

```bash
cd ~/infra

# env 파일 준비 (최초 1회)
cp stock-server.env.example stock-server.env
# KIS API 키 등 실제 값 입력
vi stock-server.env

# 기동 (Oracle 초기화 최대 5분 소요)
docker compose -f docker-compose-core.yml up -d

# 상태 확인
docker compose -f docker-compose-core.yml ps
docker compose -f docker-compose-core.yml logs oracle -f
```

Oracle이 healthy 상태가 된 후 bank-server, stock-server, transaction-server가 자동 기동됩니다.

### 3-2. App (클라우드) 기동

```bash
# Firebase 서비스 계정 키 배치 (최초 1회)
mkdir -p secrets
# secrets/firebase.json 복사 (git 커밋 금지)

docker compose -f docker-compose-app.yml up -d

# 상태 확인
docker compose -f docker-compose-app.yml ps
```

---

## 4. Seed 데이터

### Oracle Seed (Core 서버)

```bash
# core 프로파일로 stock-server 단독 실행 — init 스크립트가 자동으로 Oracle에 초기 데이터를 삽입
# (docker-compose-core.yml 정상 기동 시 자동 처리)
```

Oracle init 스크립트는 `oracle-init/` 디렉터리에 있으며, 컨테이너 최초 기동 시 자동 실행됩니다.  
이미 볼륨이 존재하면 init 스크립트는 실행되지 않습니다.

| 파일 | 내용 |
|------|------|
| `seed/oracle/01_seed_bank.sql` | BANK_ACCOUNT, BANK_TRANSACTION |
| `seed/oracle/02_seed_stock.sql` | SECURITIES_ACCOUNT, STOCK_HOLDING |
| `seed/oracle/03_seed_trans.sql` | TRANSFER_TRANSACTION |
| `seed/oracle/04_seed_card.sql` | CARD_MASTER |

> **`STOCK_PRICE_HISTORY`(차트 데이터)는 SQL seed 없음.**  
> stock-server가 `core` 프로파일로 기동할 때 `DataInitializer`가 자동으로 60일치를 삽입합니다.  
> 자세한 내용은 [§5 알려진 이슈 #1](#1-stock-server-차트-데이터-미삽입--get-baasv1stockcodecharts-500) 참고.

### PostgreSQL Seed (App 서버)

`docker-compose-app.yml` 기동 시 `postgres-init/` 디렉터리의 SQL이 자동 실행됩니다.

| 파일 | 내용 |
|------|------|
| `seed/postgres/01_seed_users.sql` | USERS |
| `seed/postgres/02_seed_user_profile.sql` | USER_PROFILE |
| `seed/postgres/03_seed_pin_auth.sql` | PIN_AUTH |
| `seed/postgres/04_seed_virtual_salary.sql` | VIRTUAL_SALARY_SETTING |
| `seed/postgres/05_seed_linked_accounts.sql` | LINKED_FINANCIAL_ACCOUNT, ACCOUNT_MAPPING |
| `seed/postgres/07_seed_contracts.sql` | CONTRACT |

---

## 5. 알려진 이슈

### 이슈 #1 — stock-server 차트 데이터 미삽입 → `GET /baas/v1/stock/{code}/charts` 500

**증상**

```
STOCK_003: 차트 데이터 없음
```

**원인**

`application-seed.yaml`이 `stock.mock.enabled: false`를 선언합니다.  
`SPRING_PROFILES_ACTIVE=core,seed`로 실행하면 seed 프로파일이 core 프로파일을 오버라이드하여 mock이 꺼집니다.  
mock이 꺼지면 `MockStockPriceProvider` 빈이 생성되지 않고, `DataInitializer`가 `initDailyCandles()`를 건너뜁니다.  
결과적으로 Oracle `STOCK_PRICE_HISTORY` 테이블이 비어 있어 차트 조회 시 500 반환.

```
core,seed 프로파일 → MockStockPriceProvider 미생성
→ DataInitializer.init() → "real 모드 — skip" 로그 출력
→ STOCK_PRICE_HISTORY 비어있음
→ getChart() → histories.isEmpty() → STOCK_003 → 500
```

**해결**

`seed` 프로파일 없이 `core` 프로파일만으로 기동합니다.  
`docker-compose-core.yml`의 stock-server는 이미 `SPRING_PROFILES_ACTIVE: core`로 설정되어 있습니다.

```bash
# 올바른 방법 — docker-compose-core.yml 그대로 사용
docker compose -f docker-compose-core.yml up -d stock-server

# 잘못된 방법 — seed 프로파일 추가 금지
# docker compose -f docker-compose-core.yml run --rm \
#   -e SPRING_PROFILES_ACTIVE=core,seed stock-server
```

`core` 프로파일 단독 기동 시:
- `stock.mock.enabled: true` 활성화
- `MockStockPriceProvider` 빈 생성
- 기동 시 모든 종목에 60 영업일치 `STOCK_PRICE_HISTORY` 자동 삽입

---

### 이슈 #2 — `GET /api/v1/virtual-salary/summary` 500 (`NonUniqueResultException`)

**증상**

```
org.springframework.dao.IncorrectResultSizeDataAccessException: NonUniqueResultException
```

**원인**

`operational.account_mapping` 테이블에 동일 `(user_id, mapping_type)` 조합의 중복 행 존재.  
`05_seed_linked_accounts.sql`의 INSERT가 `ON CONFLICT DO NOTHING`이 아닌 단순 INSERT로 구성되어  
seed를 여러 번 실행하면 중복 삽입됨.

**해결 (이미 적용됨)**

`seed/postgres/05_seed_linked_accounts.sql`을 `WHERE NOT EXISTS` 패턴으로 수정 완료.  
기존 DB에 중복이 있다면 아래 SQL로 정리:

```sql
DELETE FROM operational.account_mapping
WHERE mapping_id NOT IN (
    SELECT MIN(mapping_id)
    FROM operational.account_mapping
    GROUP BY user_id, mapping_type
);
```

PostgreSQL 컨테이너 내부에서 실행:

```bash
docker exec -it postgres psql -U admin -d finance \
  -c "DELETE FROM operational.account_mapping WHERE mapping_id NOT IN (SELECT MIN(mapping_id) FROM operational.account_mapping GROUP BY user_id, mapping_type);"
```

---

### 이슈 #3 — AWS 배포 트러블슈팅

AWS 배포 시 발생한 문제들은 [aws_problems.md](./aws_problems.md)에 정리되어 있습니다.

주요 항목:
- `UnknownHostException: postgres-log` → Spring relaxed binding으로 환경변수 오버라이드
- `Bad authority` (RestClient baseUrl) → `<CORE_VPN_OR_PUBLIC_IP>` 플레이스홀더 미치환
- `FirebaseConfig: no JSON input found` → `secrets/firebase.json` 파일 미배치
- `service-backend healthcheck unhealthy` → SecurityConfig에 `/actuator/**` 허용 추가 필요
- `Could not resolve placeholder 'bank.server.url'` → `backend.prod.env`에 `BANK_SERVER_URL` 추가 필요

---

## 6. Spring Profile 참고

| 서버 | 프로파일 | 역할 |
|------|----------|------|
| service-backend | `app` | PostgreSQL 연결, Firebase 인증 등 클라우드 환경 설정 |
| mydata-server | `app` | 클라우드 환경 설정 |
| bank-server | `core` | Oracle 연결 등 온프레미스 환경 설정 |
| stock-server | `core` | Oracle 연결 + **mock 활성화** (`stock.mock.enabled: true`) |
| transaction-server | `core` | Oracle/Kafka 온프레미스 환경 설정 |

> `application-seed.yaml`은 KIS API 연동 테스트 전용입니다.  
> **일반 개발/데모 기동 시에는 `seed` 프로파일을 절대 추가하지 마세요.**

---

## 7. 자주 쓰는 명령

```bash
# 전체 core 재기동
docker compose -f docker-compose-core.yml down && docker compose -f docker-compose-core.yml up -d

# 특정 서비스만 재시작
docker compose -f docker-compose-core.yml restart stock-server

# 이미지 최신화 후 재기동
docker compose -f docker-compose-core.yml pull stock-server
docker compose -f docker-compose-core.yml up -d --force-recreate stock-server

# 로그 확인
docker compose -f docker-compose-core.yml logs stock-server -f
docker compose -f docker-compose-core.yml logs transaction-server --tail=100

# Oracle 헬스 상태 확인
docker inspect --format='{{.State.Health.Status}}' oracle

# PostgreSQL 접속 (seed 확인 등)
docker exec -it postgres psql -U admin -d finance
```
