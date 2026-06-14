# Task 체크리스트

---

## Task 1 — prod CI/CD 테스트

### 1-1. GitHub Secrets 등록

4개 레포 각각 `Settings → Secrets and variables → Actions → New repository secret`
(또는 Organization Secrets으로 한 번만 등록)

| Secret 이름 | 값 | 대상 레포 |
|---|---|---|
| `AWS_SSH_PRIVATE_KEY` | `FLON-RSA-KEY.pem` 파일 전체 내용 (`cat FLON-RSA-KEY.pem`) | 4개 전체 |
| `AWS_BASTION_HOST` | `43.203.52.141` | 4개 전체 |
| `AWS_BASTION_USER` | `ubuntu` | 4개 전체 |

**Variables** (Secrets 아님) — service-frontend만:

| Variable 이름 | 위치 |
|---|---|
| `AWS_TRANSACTION_URL` | service-frontend → Settings → Variables → `AWS_TRANSACTION_URL` = `http://10.10.4.15:8083` |

---

### 1-2. EC2 사전 준비 (2C 서버)

AWS.md 기준 APP-2A / MYDATA-2A는 완료. **2C 서버들은 별도 확인 필요.**

```bash
# Bastion 경유 APP-2C 접속
ssh -i FLON-RSA-KEY.pem -o ProxyCommand="ssh -i FLON-RSA-KEY.pem -W %h:%p ubuntu@43.203.52.141" ubuntu@172.16.11.10

# APP-2C에서 확인/준비
docker --version          # Docker 설치 확인
ls ~/infra                # infra clone 확인
# 없으면:
git clone <infra-repo-url> ~/infra
```

```bash
# MYDATA-2C (172.16.21.10) 동일하게 확인
ssh -i FLON-RSA-KEY.pem -o ProxyCommand="ssh -i FLON-RSA-KEY.pem -W %h:%p ubuntu@43.203.52.141" ubuntu@172.16.21.10
```

---

### 1-3. 테스트 실행

```bash
# 각 레포 prod 브랜치에서 빈 커밋 push
git checkout prod
git commit --allow-empty -m "test: trigger CI-Prod"
git push origin prod
```

**확인 순서:**
1. GitHub → Actions 탭 → `CI-Prod` workflow 트리거됨
2. `build-and-push` 완료 → GHCR에 `:prod` 태그 이미지 생성
3. `deploy-app-2a` 완료 후 `deploy-app-2c` 시작 (순차 확인)
4. EC2에서 컨테이너 확인:

```bash
# APP-2A 접속 후
docker compose -f ~/infra/docker-compose-prod-app.yml ps
```

---

## Task 2 — Seed 데이터 적재

### 2-1. PostgreSQL (AWS RDS)

**실행 서버:** APP-2A (`172.16.10.10`)
- 이유: FLON-DATA-RDS-SG가 FLON-APP-SG(APP-2A/2C)만 5432 허용

```bash
# 1. Bastion 경유 APP-2A 접속
ssh -i FLON-RSA-KEY.pem \
  -o ProxyCommand="ssh -i FLON-RSA-KEY.pem -W %h:%p ubuntu@43.203.52.141" \
  ubuntu@172.16.10.10

# 2. APP-2A 안에서
sudo apt install -y postgresql-client   # psql 없으면 설치
cd ~/infra && git pull

# 3. 실행
RDS_PASSWORD="<비밀번호>" bash seed/seed-prod-rds.sh
```

적재 파일 순서 (FK 의존성 때문에 고정):
```
00_alter_schema.sql → 01_seed_users.sql → 02_seed_user_profile.sql
→ 03_seed_pin_auth.sql → 04_seed_virtual_salary.sql
→ 05_seed_linked_accounts.sql → 07_seed_contracts.sql
```

적재 확인:
```bash
PGPASSWORD="<비밀번호>" psql \
  -h flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com \
  -U postgres -d flonrdsdb \
  -c "SELECT user_id, user_name, email FROM operational.users WHERE user_id BETWEEN 22 AND 31;"
```

---

### 2-2. Oracle (온프레미스)

**실행 서버:** 온프레미스 Core 서버 (docker-compose-prod-core.yml 실행 중인 서버)

```bash
# Core 서버 SSH 접속 후
cd ~/infra && git pull
bash seed/seed-prod-core.sh
```

적재 파일:
```
01_seed_bank.sql  (BANK)
02_seed_stock.sql (STOCK)
03_seed_trans.sql (TRANS)
04_seed_card.sql  (CARD) ← 기존 test 스크립트엔 없었음
```

적재 확인:
```bash
# 은행 계좌
docker exec -i oracle sqlplus -S BANK/bank123@XEPDB1 <<'EOF'
SELECT ACCOUNT_ID, USER_ID, BALANCE FROM BANK_ACCOUNT WHERE ACCOUNT_ID BETWEEN 2001 AND 2020;
EXIT;
EOF

# 카드
docker exec -i oracle sqlplus -S CARD/card123@XEPDB1 <<'EOF'
SELECT CARD_ID, USER_ID FROM CARD_MASTER WHERE USER_ID BETWEEN 22 AND 31;
EXIT;
EOF
```

---

## 주의

- RDS_PASSWORD는 절대 파일/커밋에 포함 금지
- RDS에 `operational` 스키마가 없으면 seed 전에 Spring Boot 한 번 기동해서 JPA DDL로 스키마 생성 필요
- Oracle healthy 상태 확인 후 seed 실행: `docker ps | grep oracle`
