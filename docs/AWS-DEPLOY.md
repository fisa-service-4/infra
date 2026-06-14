# FLON AWS 운영 배포 가이드

도메인: **flon.cloud**  
VPC: `172.16.0.0/16`  
리전: `ap-northeast-2` (서울)

---

## 아키텍처 개요

```
Internet
    ↓ HTTPS (443)
  ALB (flon.cloud)
    ├─ /          → APP EC2 :3000  (service-frontend)
    ├─ /api       → APP EC2 :8080  (service-backend)
    └─ /ai        → APP EC2 :8000  (service-ai-server)

APP EC2 (PRIVATE-APP-SUBNET-2A, 172.16.10.x)
  ├─ service-frontend  :3000
  ├─ service-backend   :8080  → RDS (운영 DB)
  │                           → DATA EC2 :6379   (Redis)
  │                           → DATA EC2 :5434   (postgres-log)
  │                           → MYDATA EC2 :8084  (mydata-server)
  │                           → CORE :8083        (transaction-server / VPN)
  └─ service-ai-server :8000  → DATA EC2 :5433   (postgres-analysis)
                              → DATA EC2 :5435   (postgres-pgvector)

MYDATA EC2 (PRIVATE-EXTERNAL-SUBNET-2A, 172.16.20.x)
  └─ mydata-server :8084

DATA EC2 (PRIVATE-DATA-SUBNET-2A, 172.16.30.x)
  ├─ redis            :6379
  ├─ postgres-log     :5434  (finance_log)
  ├─ postgres-analysis :5433  (finance_analytics)
  └─ postgres-pgvector :5435  (finance_vector)

RDS (PRIVATE-DATA-SUBNET)
  └─ PostgreSQL 16   :5432  (flonrdsdb)
      endpoint: flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com

CORE 온프레미스 (VPN 연동)
  ├─ transaction-server :8083  ← AWS 서비스에서 진입
  ├─ bank-server        :8081
  ├─ stock-server       :8082
  ├─ kafka              :9092
  └─ oracle             :1521
```

---

## 0. 사전 준비

### 공통 (각 EC2)

```bash
# Docker + Compose 설치 확인
docker --version          # 24.x 이상
docker compose version    # v2.x 이상

# infra 저장소 클론 (이미 되어 있으면 git pull)
git clone https://github.com/fisa-service-4/infra.git ~/infra
cd ~/infra
```

### GHCR 인증 토큰 설정

각 EC2의 환경변수로 설정하거나 `~/.bashrc`에 추가:

```bash
export GHCR_USER=<GitHub_Username>
export GHCR_TOKEN=<GitHub_PAT_with_read_packages_scope>
```

수동 로그인:
```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
```

---

## 1. DATA EC2 배포 (가장 먼저 실행)

APP EC2의 backend/ai가 DATA EC2의 DB를 참조하므로 **DATA 먼저 올려야 합니다.**

```bash
cd ~/infra

# 1) env 파일 생성 (최초 1회)
cp envs/redis.env.example            envs/redis.env
cp envs/postgres-log.env.example     envs/postgres-log.env
cp envs/postgres-analysis.env.example envs/postgres-analysis.env
cp envs/postgres-pgvector.env.example envs/postgres-pgvector.env

# 각 파일의 <...> 자리에 실제 패스워드 입력
vi envs/redis.env
vi envs/postgres-log.env
vi envs/postgres-analysis.env
vi envs/postgres-pgvector.env

# 2) 배포
bash scripts/deploy-prod-data.sh

# 3) 상태 확인
docker compose -f docker-compose-prod-data.yml ps
docker compose -f docker-compose-prod-data.yml logs -f
```

**주의**: `postgres-pgvector` 최초 기동 시 `postgres-init-pgvector/01_init.sql`이 실행되어 `vector` 익스텐션을 활성화합니다. 이미 볼륨이 존재하면 init 스크립트는 실행되지 않습니다.

---

## 2. MYDATA EC2 배포

```bash
cd ~/infra

# 1) env 파일 생성
cp envs/mydata.env.example envs/mydata.env

# 2) 배포
bash scripts/deploy-prod-mydata.sh

# 3) 상태 확인
docker compose -f docker-compose-prod-mydata.yml ps
```

---

## 3. APP EC2 배포

**DATA EC2와 MYDATA EC2가 먼저 healthy 상태여야 합니다.**

```bash
cd ~/infra

# 1) env 파일 생성
cp envs/frontend.env.example envs/frontend.env
cp envs/backend.env.example  envs/backend.env
cp envs/ai.env.example       envs/ai.env

# DATA EC2 private IP 및 MYDATA EC2 private IP 확인 후 각 파일 편집
# (AWS 콘솔 → EC2 → 해당 인스턴스 → Private IPv4 address)
vi envs/frontend.env   # MYDATA_URL, TRANSACTION_URL
vi envs/backend.env    # RDS 비밀번호, Redis/Log DB 설정, DATA/MYDATA/CORE IP
vi envs/ai.env         # LLM API 키, DATA EC2 DB 접속 정보

# 2) Firebase 서비스 계정 키 배치
mkdir -p secrets
# secrets/firebase.json 을 직접 복사 (git에 포함 금지)

# 3) 배포
bash scripts/deploy-prod-app.sh

# 4) 상태 확인
docker compose -f docker-compose-prod-app.yml ps
docker compose -f docker-compose-prod-app.yml logs service-backend -f
```

### RDS 초기 DB 설정 (최초 1회)

RDS에는 init 스크립트가 자동 실행되지 않습니다. Bastion을 통해 접속하여 수동으로 실행하세요:

```bash
# Bastion에서
psql -h flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com \
     -U postgres -d flonrdsdb \
     -f ~/infra/postgres-init/01_init.sql
```

---

## 4. CORE 온프레미스 배포

```bash
cd ~/infra   # 온프레미스 서버에서

# 1) env 파일 생성
cp envs/oracle.env.example      envs/oracle.env
cp envs/kafka.env.example       envs/kafka.env
cp envs/bank.env.example        envs/bank.env
cp envs/stock.env.example       envs/stock.env
cp envs/transaction.env.example envs/transaction.env

vi envs/oracle.env   # Oracle 시스템 패스워드, BANK 계정 패스워드
vi envs/stock.env    # KIS API 키

# 2) 배포 (Oracle 초기화에 최대 5분 소요)
bash scripts/deploy-prod-core.sh
```

---

## 5. 서비스별 재배포 (롤링 업데이트)

```bash
# APP EC2에서
bash scripts/restart-prod-app.sh

# MYDATA EC2에서
bash scripts/restart-prod-mydata.sh

# DATA EC2에서 (DB 컨테이너 재시작 — 볼륨 유지)
bash scripts/restart-prod-data.sh

# CORE 온프레미스에서
bash scripts/restart-prod-core.sh
```

특정 서비스만 재시작:
```bash
docker compose -f docker-compose-prod-app.yml up -d --force-recreate service-backend
```

---

## 6. ALB + Route53 설정 (미완료)

### ALB Target Group

| 이름 | 프로토콜 | 포트 | Health Check 경로 |
|------|----------|------|-------------------|
| `flon-tg-frontend` | HTTP | 3000 | `/` |
| `flon-tg-backend`  | HTTP | 8080 | `/actuator/health` |
| `flon-tg-ai`       | HTTP | 8000 | `/health` |

### ALB Listener 규칙 (HTTPS 443)

| 조건 | 대상 |
|------|------|
| `Host: flon.cloud`, Path: `/api/*` | `flon-tg-backend` |
| `Host: flon.cloud`, Path: `/ai/*`  | `flon-tg-ai` |
| `Host: flon.cloud`, Default        | `flon-tg-frontend` |

HTTP 80 → HTTPS 443 Redirect 규칙 추가.

### Route53

| 레코드 | 타입 | 값 |
|--------|------|----|
| `flon.cloud` | A (Alias) | ALB DNS |
| `www.flon.cloud` | CNAME | `flon.cloud` |

---

## 7. VPN 연동 (미완료)

CORE 온프레미스의 `transaction-server:8083`을 AWS에서 안전하게 호출하기 위한 VPN이 필요합니다.

### 옵션 A — AWS Site-to-Site VPN (관리형, 권장)

1. AWS 콘솔 → VPC → Virtual Private Gateway 생성 → FLON-VPC 연결
2. Customer Gateway 생성 (온프레미스 공인 IP 입력)
3. Site-to-Site VPN Connection 생성
4. 온프레미스 라우터에 VPN 설정 다운로드 및 적용
5. `FLON-PRIVATE-RT`에 온프레미스 CIDR → VGW 라우트 추가

### 옵션 B — StrongSwan IPSec (비용 절감)

```bash
# AWS EC2 (VPN 게이트웨이 역할)에서
sudo apt install strongswan -y
# /etc/ipsec.conf, /etc/ipsec.secrets 설정 후
sudo ipsec start
```

### VPN 구축 전 임시 대응 (발표용)

`envs/frontend.env`, `envs/backend.env`의 `TRANSACTION_URL`에 온프레미스 머신의 **공인 IP**를 직접 사용:

```bash
TRANSACTION_URL=http://<온프레미스_공인_IP>:8083
```

온프레미스 방화벽에서 APP EC2 공인 IP → 8083 포트 허용 필요.

---

## 8. 운영 관리

### 로그 확인

```bash
# 실시간 로그
docker compose -f docker-compose-prod-app.yml logs -f service-backend

# 최근 100줄
docker compose -f docker-compose-prod-app.yml logs --tail=100 service-ai-server
```

### 헬스체크 상태

```bash
docker inspect --format='{{.State.Health.Status}}' service-backend
docker inspect --format='{{.State.Health.Status}}' oracle
```

### 전체 서비스 상태

```bash
# 각 EC2에서 실행
docker compose -f docker-compose-prod-app.yml ps      # APP EC2
docker compose -f docker-compose-prod-mydata.yml ps   # MYDATA EC2
docker compose -f docker-compose-prod-data.yml ps     # DATA EC2
docker compose -f docker-compose-prod-core.yml ps     # CORE
```

### 긴급 중단

```bash
docker compose -f docker-compose-prod-app.yml down     # 컨테이너만 중단 (볼륨 유지)
docker compose -f docker-compose-prod-data.yml down    # DB 컨테이너 중단 (볼륨 유지)
```

---

## 9. 주의 사항 및 체크리스트

- [ ] 모든 `<...>` placeholder를 실제 값으로 교체
- [ ] `envs/*.env` 파일을 `.gitignore`에 추가 확인 (`envs/*.env` 패턴)
- [ ] `secrets/firebase.json`을 `.gitignore`에 추가 확인
- [ ] RDS 마스터 비밀번호 `abcdefg` → 운영 배포 전 반드시 변경
- [ ] `postgres-log`, `postgres-analysis`, `postgres-pgvector` 각 서비스의 패스워드가 서로 다른지 확인
- [ ] DATA EC2 Security Group (`FLON-DATA-SG`): APP EC2 SG에서만 5432-5435, 6379 허용 확인
- [ ] MYDATA EC2 Security Group (`FLON-MYDATA-SG`): APP EC2 SG에서만 8084 허용 확인
- [ ] ALB ACM 인증서 `flon.cloud` 와일드카드 또는 정확한 도메인 연결 확인
- [ ] Oracle 볼륨(`flon-core_oracle_data`) 별도 백업 계획 수립
