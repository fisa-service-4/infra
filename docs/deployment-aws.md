# AWS 운영 배포 가이드

도메인: **flon.cloud**  
VPC: `172.16.0.0/16` | 리전: `ap-northeast-2` (서울)

---

## 아키텍처

```
Internet (HTTPS 443)
    ↓
  ALB: flon.cloud  (FLON-ALB-SG)
    ↓
  APP EC2 x2  (172.16.10.10 / 172.16.11.10)
    ├─ service-frontend  :3000
    ├─ service-backend   :8080  → RDS :5432
    │                           → DATA EC2 :6379   (redis)
    │                           → DATA EC2 :5432   (postgres-log, postgres-analysis)
    │                           → MYDATA EC2 :8084
    │                           → CORE :8083       (VPN)
    └─ service-ai-server :8000  → DATA EC2 :5432   (postgres-pgvector)

  MYDATA EC2  (172.16.20.10 / 172.16.21.10)
    └─ mydata-server :8084

  DATA EC2  (172.16.30.10)
    ├─ redis            :6379
    ├─ postgres-log     :5432  (finance_log DB)
    ├─ postgres-analysis :5432  (finance_analytics DB)
    └─ postgres-pgvector :5432  (finance_vector DB)

  RDS PostgreSQL 16  (flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com:5432)
    └─ flonrdsdb  (service-backend 운영 DB)

  CORE 온프레미스  (10.10.4.15 / Site-to-Site VPN 연결)
    ├─ transaction-server :8083
    ├─ bank-server        :8081
    ├─ stock-server       :8082
    ├─ kafka              :9092
    └─ oracle             :1521
```

---

## 접속 방법

```bash
# 1. Bastion (로컬 → Bastion)
ssh -i "C:\Users\shlee\fisa-final-pj\FLON-RSA-KEY.pem" ubuntu@43.203.52.141

# 2. Bastion → 각 EC2 (Bastion에서 실행)
ssh -i ~/.ssh/FLON-RSA-KEY.pem ubuntu@172.16.10.10   # APP-2A
ssh -i ~/.ssh/FLON-RSA-KEY.pem ubuntu@172.16.11.10   # APP-2C
ssh -i ~/.ssh/FLON-RSA-KEY.pem ubuntu@172.16.20.10   # MYDATA-2A
ssh -i ~/.ssh/FLON-RSA-KEY.pem ubuntu@172.16.21.10   # MYDATA-2C
ssh -i ~/.ssh/FLON-RSA-KEY.pem ubuntu@172.16.30.10   # DATA-2A

# 3. CORE 온프레미스
ssh -i %USERPROFILE%\team04-jooho.pem ubuntu@172.21.33.243
```

---

## 브랜치 전략 및 배포 소스

### 서비스 레포 (service-backend, service-frontend, service-ai-server, mydata-server)

```
feat/aws ──→ prod   (merge)
```

- `feat/aws`는 develop에서 분기 후 AWS 수정사항을 추가한 브랜치 (최신)
- `prod` 브랜치에만 있는 GitHub Actions CI/CD workflow는 conflict 없이 유지됨
- 각 레포에서 실행:

```bash
git checkout prod
git merge feat/aws
git push origin prod
```

### infra 레포

```
feat/#10-set-aws-infra ──→ develop ──→ (prod 생성 또는 merge)
```

- `feat/#10-set-aws-infra`에 prod 스크립트, docker-compose, env.example 전부 포함
- PR로 develop 머지 후 각 EC2에서 `git pull` 하면 반영됨

### 배포 이미지 소스

- 모든 서비스 이미지는 GHCR (`ghcr.io/fisa-service-4/<서비스명>:prod`)에서 pull
- `prod` 브랜치 push → GitHub Actions가 이미지 빌드 및 GHCR push → EC2에서 `restart` 스크립트 실행

---

## 최초 배포 절차

### 사전 준비 (각 EC2 공통)

```bash
# infra 레포 클론 (최초 1회)
git clone https://github.com/fisa-service-4/infra.git ~/infra
cd ~/infra

# GHCR 로그인
docker login ghcr.io
# Username: GitHub 아이디
# Password: GitHub PAT (read:packages 권한)
```

### 배포 순서: DATA → MYDATA → APP → CORE

---

### 1. DATA EC2 (172.16.30.10)

```bash
cd ~/infra

# env 파일 생성 (최초 1회)
cp envs/redis.prod.env.example envs/redis.prod.env
cp envs/postgres.prod.env.example envs/postgres.prod.env
# 실제 패스워드 입력
vi envs/redis.prod.env
vi envs/postgres.prod.env

# 배포
bash scripts/prod/deploy-prod-data.sh

# 상태 확인
docker compose -f docker-compose-prod-data.yml ps
```

---

### 2. MYDATA EC2 (172.16.20.10)

```bash
cd ~/infra

# 배포
bash scripts/prod/deploy-prod-mydata.sh

# 상태 확인
docker compose -f docker-compose-prod-mydata.yml ps
```

---

### 3. APP EC2 (172.16.10.10, 172.16.11.10)

**DATA EC2와 RDS가 먼저 healthy 상태여야 함.**

```bash
cd ~/infra

# env 파일 생성 (최초 1회)
cp envs/backend.prod.env.example envs/backend.prod.env
cp envs/frontend.prod.env.example envs/frontend.prod.env
cp envs/ai.prod.env.example envs/ai.prod.env
# 실제 값 입력 (RDS 비밀번호, Redis IP, CORE IP 등)
vi envs/backend.prod.env

# Firebase 서비스 계정 키 배치 (최초 1회)
# 로컬에서 전송: scp -i FLON-RSA-KEY.pem firebase.json ubuntu@43.203.52.141:~/
# bastion에서: scp -i ~/.ssh/FLON-RSA-KEY.pem firebase.json ubuntu@172.16.10.10:~/infra/secrets/
mkdir -p secrets
# secrets/firebase.json 확인

# 배포
bash scripts/prod/deploy-prod-app.sh

# service-backend healthy 확인 후 frontend 강제 재시작
docker inspect --format='{{.State.Health.Status}}' service-backend
docker compose -f docker-compose-prod-app.yml up -d service-frontend
```

#### RDS 초기화 (최초 1회만)

```bash
# APP EC2에서
psql -h flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com \
     -U postgres -d flonrdsdb
# 비밀번호: backend.prod.env의 SPRING_DATASOURCE_PASSWORD 값
```

---

### 4. CORE 온프레미스 (10.10.4.15)

```bash
cd ~/infra

# env 파일 생성 (최초 1회)
cp envs/oracle.prod.env.example envs/oracle.prod.env
cp envs/stock.prod.env.example envs/stock.prod.env
# KIS API 키 등 입력
vi envs/stock.prod.env

# 배포 (Oracle 초기화 최대 5분 소요)
bash scripts/prod/deploy-prod-core.sh
```

> **주의**: `deploy-prod-core.sh` 내부에 `BRANCH="feat/#9-set-aws-infra"` 하드코딩 되어 있음 → `develop`으로 수정 필요

---

## VPN 운영 주의사항 (StrongSwan + Docker)

온프레미스 서버 **재부팅 후** Docker iptables와 StrongSwan 정책이 충돌하여 AWS → CORE 통신이 차단될 수 있음.

### 증상

```bash
# APP EC2에서 테스트
curl --connect-timeout 5 http://10.10.4.15:8083/baas/v1/health
# 응답 없음 또는 RST
```

### 해결 (CORE 온프레미스에서)

```bash
# VPN 재시작
sudo ipsec restart

# Docker iptables 초기화 및 재시작
sudo systemctl stop docker
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -t raw -F
sudo iptables -X
sudo systemctl start docker

# 컨테이너 재기동
cd ~/infra
docker compose -f docker-compose-prod-core.yml up -d
```

### VPN 상태 확인

```bash
sudo ipsec statusall
# Security Associations (2 up, 0 connecting) → 정상
# bytes_i, bytes_o 둘 다 증가 → 양방향 통신 정상

# AWS에서 접근 테스트
curl --connect-timeout 5 http://10.10.4.15:8083/baas/v1/health
```

---

## 롤링 업데이트 (이미지 재배포)

```bash
# APP EC2
bash scripts/prod/restart-prod-app.sh

# MYDATA EC2
bash scripts/prod/restart-prod-mydata.sh

# DATA EC2
bash scripts/prod/restart-prod-data.sh

# CORE 온프레미스
bash scripts/prod/restart-prod-core.sh
```

특정 서비스만:

```bash
docker compose -f docker-compose-prod-app.yml pull service-backend
docker compose -f docker-compose-prod-app.yml up -d --force-recreate service-backend
# healthy 확인 후
docker compose -f docker-compose-prod-app.yml up -d service-frontend
```

---

## 알려진 이슈 및 해결

### 1. postgres-log UnknownHostException

`application-aws.yml`이 이미지에 없는 경우 `app` 프로파일의 `postgres-log` 하드코딩 값이 사용됨.

**해결**: `backend.prod.env`에 relaxed binding 형식으로 설정
```
LOG_DATASOURCE_URL=jdbc:postgresql://172.16.30.10:5432/finance_log
LOG_DATASOURCE_USERNAME=admin
LOG_DATASOURCE_PASSWORD=...
ANALYTICS_DATASOURCE_URL=jdbc:postgresql://172.16.30.10:5432/finance_analytics
```

### 2. RestClient Bad authority (TRANSACTION_SERVER_URL)

플레이스홀더 `<CORE_VPN_OR_PUBLIC_IP>` 미치환 시 앱 기동 실패.

**해결**: `backend.prod.env`에 실제 VPN IP 또는 임시 주소 설정
```
TRANSACTION_SERVER_URL=http://10.10.4.15:8083
BANK_SERVER_URL=http://10.10.4.15:8081
```

### 3. FirebaseConfig no JSON input found

`secrets/firebase.json` 파일 미존재.

**해결**: Firebase 콘솔 → 서비스 계정 → JSON 발급 → EC2에 업로드
```bash
# 로컬 → Bastion → APP EC2
scp -i FLON-RSA-KEY.pem firebase.json ubuntu@43.203.52.141:~
# Bastion에서
scp -i ~/.ssh/FLON-RSA-KEY.pem ~/firebase.json ubuntu@172.16.10.10:~/infra/secrets/firebase.json
```

### 4. service-backend healthcheck unhealthy

`/actuator/health`가 Spring Security에 막혀 401 반환 → healthcheck 실패.

**해결**: `SecurityConfig.java`의 PUBLIC_URLS에 `/actuator/**` 추가 후 이미지 재빌드

### 5. Could not resolve placeholder 'bank.server.url'

`BankAdminClient` 빈 생성 실패로 앱 시작 불가.

**해결**: `backend.prod.env`에 추가
```
BANK_SERVER_URL=http://10.10.4.15:8081
```

### 6. service-frontend가 Created 상태에서 멈춤

`service-backend`가 `(healthy)`가 될 때까지 `service-frontend`가 대기. backend healthy 확인 후 수동 시작.

```bash
docker inspect --format='{{.State.Health.Status}}' service-backend
# healthy 확인 후
docker compose -f docker-compose-prod-app.yml up -d service-frontend
```

---

## 전체 상태 확인

```bash
# APP EC2
docker compose -f docker-compose-prod-app.yml ps

# MYDATA EC2
docker compose -f docker-compose-prod-mydata.yml ps

# DATA EC2
docker compose -f docker-compose-prod-data.yml ps

# CORE (온프레미스)
docker compose -f docker-compose-prod-core.yml ps

# 서비스 헬스체크
curl https://flon.cloud
curl https://flon.cloud/api/actuator/health

# CORE VPN 연결 확인 (APP EC2에서)
curl --connect-timeout 5 http://10.10.4.15:8083/baas/v1/health

# RDS 접속 (APP EC2에서)
psql -h flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com -U postgres -d flonrdsdb
```

---

## 체크리스트

- [ ] `envs/*.prod.env` 파일의 모든 `<...>` placeholder 교체
- [ ] `envs/*.prod.env`가 `.gitignore`에 포함되어 있는지 확인 — 커밋 금지
- [ ] `secrets/firebase.json` 각 APP EC2에 배치
- [ ] `deploy-prod-core.sh` 내 BRANCH 변수 `develop`으로 수정
- [ ] 온프레미스 재부팅 후 VPN + Docker iptables 초기화 절차 수행
- [ ] ALB Target Group에 APP-2A, APP-2C 둘 다 healthy 확인
- [ ] `flon.cloud` HTTPS 접속 확인
- [ ] `prod` 브랜치 merge 완료 확인 (각 서비스 레포: `develop` → `prod`)
