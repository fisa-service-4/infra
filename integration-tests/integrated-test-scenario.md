# 통합 테스트 시나리오

> 위치: `infra/integration-tests/`
> 프레임워크: RestAssured + JUnit 5
> 서버가 실제로 동작 중인 상태에서 실행하는 **크로스 서버 E2E 통합 테스트**입니다.

---

## 전제 조건

### 필요 서버

| 서버 | 포트 | 역할 |
|------|------|------|
| service-backend | 8080 | 인증(JWT) 도메인 |
| bank-server | 8081 | 은행 원장 (Oracle) |
| stock-server | 8082 | 증권 원장 (Oracle) |
| transaction-server | 8083 | BaaS Gateway, Saga orchestrator |
| mydata-server | 8084 | 마이데이터 집계 |

### 필요 시드 데이터

통합 테스트는 페르소나 계정과 **별도로** 생성된 전용 테스트 계정을 사용합니다.
페르소나 계정(test_firebase_001~010)은 데모 데이터 용도이며 테스트에서 참조하지 않습니다.

**Oracle (bank-server / stock-server / transaction-server)**

| 항목 | 값 |
|------|-----|
| User1 Firebase UID | `integration_test_user1` |
| User1 Oracle user_id | `9001` |
| User1 은행 계좌 (수입통장) | account_id=`9001`, 신한(088), `110-9001-000001`, 잔액 50,000,000원 |
| User1 은행 계좌 (저축통장) | account_id=`9002`, 우리(020), `1002-9001-000001`, 잔액 30,000,000원 |
| User1 증권 계좌 | account_id=`9901`, 한국투자(243), `90000001-01`, 예수금 20,000,000원 |
| User2 Firebase UID | `integration_test_user2` |
| User2 Oracle user_id | `9002` |
| User2 은행 계좌 (수입통장) | account_id=`9003`, 신한(088), `110-9002-000001`, 잔액 50,000,000원 |

**PostgreSQL (service-backend)**

| 항목 | 값 |
|------|-----|
| User1 이메일 | `integration.user1@test.com` |
| User1 비밀번호 | `Test1234!` |
| User2 이메일 | `integration.user2@test.com` |
| User2 비밀번호 | `Test1234!` |
| 공통 PIN | `192837` |

---

## 실행 방법

```bash
cd infra/integration-tests

# 전체 실행
./gradlew test

# 특정 클래스만 실행
./gradlew test --tests "com.integration.health.*"
./gradlew test --tests "com.integration.auth.*"

# 서버 URL 오버라이드 (기본값은 localhost)
./gradlew test -DSERVICE_BACKEND_URL=http://host:8080 -DTRANSACTION_SERVER_URL=http://host:8083
```

---

## 시드 데이터 없이 실행 가능한 테스트

| 클래스 | 테스트 | 비고 |
|--------|--------|------|
| HealthCheckTest | 전체 5개 | 서버 가동 여부만 확인 |
| AuthFlowTest | `loginFailWithWrongPassword` | 잘못된 비밀번호 거부 확인 |
| AuthFlowTest | `getMyInfoWithoutToken` | 토큰 없는 요청 401 확인 |

나머지 테스트는 PostgreSQL 사용자 시드 또는 Oracle 계좌 시드가 필요합니다.

---

## 테스트 시나리오

---

### 1. HealthCheckTest — 서버 헬스 체크

**테스트 대상:** `com.integration.health.HealthCheckTest`
**인증 불필요 | 시드 불필요**

| # | 테스트명 | 호출 경로 | 검증 내용 |
|---|---------|-----------|-----------|
| 1 | bank-server 헬스 체크 | `GET /internal/v1/bank/health` (X-User-Id: 9001) | `data.server=UP`, `data.database=UP` |
| 2 | stock-server 헬스 체크 | `GET /internal/v1/stock/health` (X-User-Id: 9001) | `data.server=UP`, `data.database=UP` |
| 3 | service-backend Actuator | `GET /actuator/health` | HTTP 200 또는 503 반환 (서버 응답 자체 확인) |
| 4 | transaction-server 도달 확인 | `GET /baas/v1/bank/accounts` | HTTP 2xx~4xx (5xx 아님) |
| 5 | mydata-server 도달 확인 | `GET /mydata/v1/connections` | HTTP 2xx~4xx (5xx 아님) |

---

### 2. AuthFlowTest — 인증 플로우

**테스트 대상:** `com.integration.auth.AuthFlowTest`
**서버:** service-backend:8080
**시드 필요:** PostgreSQL User1 (integration.user1@test.com / Test1234!)

| # | 테스트명 | 호출 경로 | 검증 내용 |
|---|---------|-----------|-----------|
| 1 | 로그인 성공 | `POST /api/v1/auth/login` | 200, `accessToken`·`refreshToken` 반환, 이메일 일치 |
| 2 | 잘못된 비밀번호 로그인 | `POST /api/v1/auth/login` (WrongPassword) | 400~401, `error.code=AUTH_003` |
| 3 | 내 정보 조회 | `GET /api/v1/users/me` (Bearer Token) | 200, 이메일 일치 |
| 4 | 토큰 없이 내 정보 조회 | `GET /api/v1/users/me` | 401 |
| 5 | 토큰 재발급 | `POST /api/v1/auth/reissue` (refreshToken) | 200, 새 `accessToken` 반환 |
| 6 | 로그아웃 | `POST /api/v1/auth/logout` (Bearer Token) | 200 |

---

### 3. BankAccountQueryTest — 은행 계좌 조회

**테스트 대상:** `com.integration.account.BankAccountQueryTest`
**서버:** transaction-server:8083 → bank-server:8081
**인증:** JWT 불필요, `X-Firebase-Uid` 헤더 사용
**시드 필요:** Oracle User1 계좌 (account_id=9001)

| # | 테스트명 | 호출 경로 | 검증 내용 |
|---|---------|-----------|-----------|
| 1 | BaaS 계좌 목록 조회 | `GET /baas/v1/bank/accounts` (X-Firebase-Uid) | 200, content 비어있지 않음 |
| 2 | BaaS 계좌 상세 조회 | `GET /baas/v1/bank/accounts/9001` | 200, accountId=9001, bankCode=088 |
| 3 | BaaS 계좌 잔액 조회 | `GET /baas/v1/bank/accounts/9001/balance` | 200, balance ≥ 0 |
| 4 | BaaS 거래 내역 조회 | `GET /baas/v1/bank/accounts/9001/transactions` | 200, content 페이지네이션 반환 |
| 5 | Firebase-Uid 누락 | `GET /baas/v1/bank/accounts` (헤더 없음) | 400~499 |
| 6 | 존재하지 않는 계좌 조회 | `GET /baas/v1/bank/accounts/99999999` | 404 |
| 7 | bank-server 직접 잔액 조회 | `GET /internal/v1/bank/accounts/9001/balance` (X-User-Id: 9001) | 200, accountId=9001, balance > 0 |

---

### 4. BankToBankTransferTest — 은행 간 이체 플로우

**테스트 대상:** `com.integration.transfer.BankToBankTransferTest`
**서버:** transaction-server:8083 → bank-server:8081
**헤더:** `Idempotency-Key` 필수
**시드 필요:** User1 계좌 9001 (출금), User2 계좌 110-9002-000001 (입금)

| # | 테스트명 | 시나리오 | 검증 내용 |
|---|---------|----------|-----------|
| 1 | 이체 전체 플로우 | 잔액 조회 → 이체 요청(201) → 승인 → 결과 조회 → 잔액 감소 확인 | `transferStatus=SUCCESS`, 잔액이 이체 금액(1,000원)만큼 감소 |
| 2 | 중복 요청 멱등성 | 동일 Idempotency-Key로 이체 두 번 요청 | 200 또는 201, 동일한 `transferId` 반환 |
| 3 | Idempotency-Key 누락 | 헤더 없이 이체 요청 | 400~499 |

**이체 플로우**
```
POST /baas/v1/bank/transfers        → transferStatus: REQUESTED
POST /baas/v1/bank/transfers/{id}/approve → transferStatus: SUCCESS
GET  /baas/v1/bank/transfers/{id}   → 결과 확인
```

---

### 5. BankToStockTransferTest — 은행→증권 Saga 이체

**테스트 대상:** `com.integration.transfer.BankToStockTransferTest`
**서버:** transaction-server:8083 → bank-server:8081 + stock-server:8082
**Saga 경로:** `toBankCode=243` (한국투자증권) → 3-Step Saga 트리거
**시드 필요:** User1 은행 계좌 9001, 증권 계좌 9901

| # | 테스트명 | 시나리오 | 검증 내용 |
|---|---------|----------|-----------|
| 1 | BANK_TO_STOCK Saga 정상 플로우 | 잔액 조회 → 이체 요청 → Saga approve → 양쪽 잔액 검증 | bank 잔액 1,000원 감소 AND stock 예수금 1,000원 증가 |
| 2 | 증권 계좌 목록 조회 | `GET /baas/v1/stock/accounts` (X-Firebase-Uid) | 200, content 비어있지 않음 |
| 3 | 증권 예수금 조회 | `GET /baas/v1/stock/accounts/9901/cash-balance` | 200, cashBalance ≥ 0 |

**Saga 3단계**
```
Step 1: bank-server 출금 처리 (BANK_TRANSFER_REQUEST_CREATED)
Step 2: stock-server 예수금 입금 (STOCK_CASH_DEPOSIT)
Step 3: bank-server 이체 상태 확정 (BANK_TRANSFER_COMMIT)
```

---

### 6. TransferCompensationTest — 이체 실패 및 보상 트랜잭션

**테스트 대상:** `com.integration.transfer.TransferCompensationTest`
**서버:** transaction-server:8083 → bank-server:8081
**시드 필요:** User1 계좌 9001

| # | 테스트명 | 시나리오 | 검증 내용 |
|---|---------|----------|-----------|
| 1 | 잔액 초과 이체 | 이체 금액 999,999,999원 (잔액 초과) | `error.code=TRANSFER_002`, 이체 전후 잔액 동일 |
| 2 | 존재하지 않는 계좌로 이체 | toBankCode=088, toAccountNumber=000-00-000000 | 400~499, `success=false` |
| 3 | 이미 승인된 이체 재승인 | 승인 완료된 transferId로 approve 재호출 | 멱등이면 200+SUCCESS, 아니면 `error.code=TRANSFER_003` |

---

### 7. StockOrderFlowTest — 주식 주문 플로우

**테스트 대상:** `com.integration.stock.StockOrderFlowTest`
**서버:** transaction-server:8083 → stock-server:8082
**시드 필요:** User1 증권 계좌 9901, STOCK_MASTER에 `005930`(삼성전자) 존재 시 전체 검증

| # | 테스트명 | 호출 경로 | 검증 내용 |
|---|---------|-----------|-----------|
| 1 | 주문 가능 계좌 목록 조회 | `GET /baas/v1/stock/accounts` (X-Firebase-Uid) | 200, content 비어있지 않음 |
| 2 | 예수금 조회 | `GET /baas/v1/stock/accounts/9901/cash-balance` | 200, cashBalance ≥ 0 |
| 3 | 종목 검색 | `GET /baas/v1/stock/search?keyword=삼성` | 200, content 반환 |
| 4 | 현재가 조회 | `GET /baas/v1/stock/005930/price` | 200 또는 404 (종목 마스터 없으면 404) |
| 5 | 매수 주문 생성 | `POST /baas/v1/stock/accounts/9901/orders` (Idempotency-Key) | 201+`status=REQUESTED` 또는 400 (종목 마스터 없음) |
| 6 | 주문 생성 후 목록·상세 조회 | 주문 생성 → 목록 조회 → 상세 조회 | 생성된 orderId 포함, stockCode 일치 |
| 7 | 보유 종목 조회 | `GET /baas/v1/stock/accounts/9901/holdings` | 200, content 반환 |

---

### 8. MyDataSyncTest — MyData 집계 조회

**테스트 대상:** `com.integration.mydata.MyDataSyncTest`
**서버:** mydata-server:8084 → bank-server:8081 + stock-server:8082
**인증:** `X-Firebase-Uid` 헤더 사용
**시드 필요:** 연동 설정 존재 시 200, 없으면 404 허용

| # | 테스트명 | 호출 경로 | 검증 내용 |
|---|---------|-----------|-----------|
| 1 | 연동 목록 조회 | `GET /mydata/v1/connections` (X-Firebase-Uid) | 200 또는 404 |
| 2 | 마이데이터 연동 요청 | `POST /mydata/v1/connect` (provider: SHINHAN_BANK) | 200 (성공) 또는 400/409 (이미 연동) |
| 3 | 은행 계좌 집계 조회 | `GET /mydata/v1/bank/accounts` (X-Firebase-Uid) | 200 또는 404 |
| 4 | 증권 계좌 집계 조회 | `GET /mydata/v1/stock/accounts` (X-Firebase-Uid) | 200 또는 404 |
| 5 | 전체 자산 집계 조회 | `GET /mydata/v1/assets` (X-Firebase-Uid) | 200 또는 404 |
| 6 | Firebase-Uid 누락 | `GET /mydata/v1/connections` (헤더 없음) | 400~499 |

---

## 테스트 파일 구조

```
infra/integration-tests/
├── build.gradle                           Java 17, JUnit 5.11, RestAssured 5.5, AssertJ 3.26
└── src/test/java/com/integration/
    ├── config/ServerConfig.java           서버 URL 설정 (시스템 프로퍼티 오버라이드 가능)
    ├── support/
    │   ├── TestFixtures.java              시드 데이터 상수 (전용 테스트 계정 참조)
    │   └── AuthHelper.java               JWT 로그인 헬퍼
    ├── health/HealthCheckTest.java        5개 테스트
    ├── auth/AuthFlowTest.java             6개 테스트
    ├── account/BankAccountQueryTest.java  7개 테스트
    ├── transfer/
    │   ├── BankToBankTransferTest.java    3개 테스트
    │   ├── BankToStockTransferTest.java   3개 테스트
    │   └── TransferCompensationTest.java  3개 테스트
    ├── stock/StockOrderFlowTest.java      7개 테스트
    └── mydata/MyDataSyncTest.java         6개 테스트
```

**총 43개 테스트**

---

## 설계 원칙

- **전용 테스트 계정 분리**: 페르소나 계정(test_firebase_001~010)과 완전히 분리된 통합 테스트 전용 계정 사용
  - User1: `integration_test_user1` (Oracle user_id=9001), User2: `integration_test_user2` (Oracle user_id=9002)
  - 잔액 50,000,000원 이상으로 세팅하여 반복 실행 시 잔액 부족 문제 방지
- **BaaS 직접 호출**: service-backend가 아닌 transaction-server를 직접 호출하여 Oracle/PostgreSQL user_id 매핑 복잡성 회피
  - Oracle user_id(9001, 9002)와 PostgreSQL auto-generated user_id는 별개이므로 `X-Firebase-Uid`로 통일
- **JWT 불필요**: 이체·계좌·주식 테스트는 BaaS 경로로 JWT 없이 동작
- **멱등성 보장**: 이체/주문은 매 실행마다 `UUID.randomUUID()`로 새 Idempotency-Key 사용
- **잔액 영향 최소화**: 이체 테스트 금액 1,000원 (`SMALL_TRANSFER_AMOUNT`) 사용
- **Resilient assertions**: 시드 미존재 시 404 허용, 서버 부분 장애 시 503 허용 등 환경 의존성 완화
