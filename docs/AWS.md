\# FLON AWS 1차 배포 진행 현황 (인수인계용)



\## 프로젝트 개요



FLON은 프리랜서 자산관리 서비스이며, AWS 기반의 1차 운영 환경 구축을 진행 중이다.



현재 목표는 다음과 같다.



\* AWS 상에 서비스 운영 인프라 구축

\* GitHub Actions → GHCR → EC2 배포 자동화 구축

\* ALB + Route53 기반 HTTPS 서비스 오픈

\* 온프레미스 금융망과 VPN 연동



\---



\# 1. 완료된 사항



\## 1-1. 도메인 / 인증서



완료 사항



\* 도메인 구매 완료

\* Route53 Hosted Zone 생성 완료

\* ACM 인증서 발급 완료



\---



\# 2. AWS 네트워크 구축 완료



\## VPC



| 항목             | 값               |

| -------------- | --------------- |

| VPC 이름         | `FLON-VPC`      |

| CIDR           | `172.16.0.0/16` |

| DNS Hostnames  | 활성화             |

| DNS Resolution | 활성화             |



\---



\## Subnet 구성



\### Public



| 이름                    | CIDR            |

| --------------------- | --------------- |

| PUBLIC-MGMT-SUBNET-2A | `172.16.0.0/24` |

| PUBLIC-MGMT-SUBNET-2C | `172.16.1.0/24` |



\### Private - APP



| 이름                    | CIDR             |

| --------------------- | ---------------- |

| PRIVATE-APP-SUBNET-2A | `172.16.10.0/24` |

| PRIVATE-APP-SUBNET-2C | `172.16.11.0/24` |



\### Private - EXTERNAL



| 이름                         | CIDR             |

| -------------------------- | ---------------- |

| PRIVATE-EXTERNAL-SUBNET-2A | `172.16.20.0/24` |

| PRIVATE-EXTERNAL-SUBNET-2C | `172.16.21.0/24` |



\### Private - DATA



| 이름                     | CIDR             |

| ---------------------- | ---------------- |

| PRIVATE-DATA-SUBNET-2A | `172.16.30.0/24` |

| PRIVATE-DATA-SUBNET-2C | `172.16.31.0/24` |



\---



\## Internet Gateway



| 항목    | 값          |

| ----- | ---------- |

| 이름    | `FLON-IGW` |

| 연결 대상 | `FLON-VPC` |



\---



\## NAT Gateway



| 항목         | 값                       |

| ---------- | ----------------------- |

| 위치         | `PUBLIC-MGMT-SUBNET-2A` |

| Elastic IP | 연결 완료                   |



\---



\## Route Table



\### FLON-PUBLIC-RT



\#### Route



| Destination     | Target |

| --------------- | ------ |

| `172.16.0.0/16` | local  |

| `0.0.0.0/0`     | IGW    |



\#### Associated Subnet



\* PUBLIC-MGMT-SUBNET-2A

\* PUBLIC-MGMT-SUBNET-2C



\---



\### FLON-PRIVATE-RT



\#### Route



| Destination     | Target      |

| --------------- | ----------- |

| `172.16.0.0/16` | local       |

| `0.0.0.0/0`     | NAT Gateway |



\#### Associated Subnet



\* PRIVATE-APP-SUBNET-2A

\* PRIVATE-APP-SUBNET-2C

\* PRIVATE-EXTERNAL-SUBNET-2A

\* PRIVATE-EXTERNAL-SUBNET-2C

\* PRIVATE-DATA-SUBNET-2A

\* PRIVATE-DATA-SUBNET-2C



\---



\# 3. Security Group 완료



\## FLON-ALB-SG



\### Inbound



\* HTTP 80 / `0.0.0.0/0`

\* HTTPS 443 / `0.0.0.0/0`



\---



\## FLON-BASTION-SG



\### Inbound



\* SSH 22 / 팀원 공인 IP



\---



\## FLON-APP-SG



\### Inbound



\* TCP 3000 / FLON-ALB-SG

\* TCP 8080 / FLON-ALB-SG

\* TCP 8000 / FLON-ALB-SG

\* SSH 22 / FLON-BASTION-SG



\---



\## FLON-MYDATA-SG



\### Inbound



\* TCP 8084 / FLON-APP-SG

\* SSH 22 / FLON-BASTION-SG



\---



\## FLON-DATA-SG



\### Inbound



\* TCP 5432 / FLON-APP-SG

\* TCP 6379 / FLON-APP-SG

\* SSH 22 / FLON-BASTION-SG



\---



\## FLON-DATA-RDS-SG



\### Inbound



\* TCP 5432 / FLON-APP-SG



\---



\# 4. EC2 구축 완료



\## Bastion



| 항목         | 값                 |

| ---------- | ----------------- |

| 이름         | `FLON-BASTION-2A` |

| OS         | Ubuntu            |

| Elastic IP | 연결 완료             |

| SSH        | 로컬 → Bastion 성공   |



\---



\## APP



| 항목 | 값                     |

| -- | --------------------- |

| 이름 | `FLON-APP-2A`         |

| 위치 | PRIVATE-APP-SUBNET-2A |



완료 사항



\* SSH 성공

\* Docker 설치 완료

\* Docker Compose 설치 완료

\* Git 설치 완료

\* Infra Repository Clone 완료



\---



\## MYDATA



| 항목 | 값                          |

| -- | -------------------------- |

| 이름 | `FLON-MYDATA-2A`           |

| 위치 | PRIVATE-EXTERNAL-SUBNET-2A |



완료 사항



\* SSH 성공

\* Docker 설치 완료

\* Docker Compose 설치 완료

\* Git 설치 완료

\* Infra Repository Clone 완료



\---



\## DATA



| 항목 | 값                      |

| -- | ---------------------- |

| 이름 | `FLON-DATA-2A`         |

| 위치 | PRIVATE-DATA-SUBNET-2A |



완료 사항



\* SSH 성공

\* Docker 설치 완료

\* Docker Compose 설치 완료

\* Git 설치 완료

\* Infra Repository Clone 완료



\---



\# 5. RDS 구축 완료



\## RDS 기본 정보



| 항목          | 값                   |

| ----------- | ------------------- |

| DB 엔진       | PostgreSQL 16       |

| DB 식별자      | `FLON-RDS`          |

| 인스턴스 클래스    | `db.t4g.micro`      |

| 스토리지        | `20 GiB (gp3)`      |

| 가용 영역 구성    | Single AZ           |

| 접근 방식       | Private Access Only |

| 초기 DB 이름    | `flonrdsdb`         |

| 스토리지 암호화    | 활성화                 |

| 자동 백업 보존 기간 | 2일                  |



\---



\## 마스터 계정 정보



| 항목         | 값              |

| ---------- | -------------- |

| 마스터 사용자 이름 | `postgres`     |

| 자격 증명 관리   | 자체 관리          |

| 마스터 암호     | `abcdefg` (임시) |



> 운영 환경 배포 전 반드시 비밀번호 변경 필요.



\---



\## 접속 정보



| 항목    | 값                                                        |

| ----- | -------------------------------------------------------- |

| 엔드포인트 | `flon-rds.cdioywgcg35u.ap-northeast-2.rds.amazonaws.com` |

| 포트    | `5432`                                                   |



\---



\## 완료 사항



\* RDS 생성 완료

\* Endpoint 확인 완료

\* PostgreSQL 접속 성공

\* DB 연결 확인 완료



\---



\# 6. 현재 아키텍처 상태



```text

Internet

&#x20;   ↓

ALB (미구축)

&#x20;   ↓

Public-Mgmt-Subnet

├─ Bastion

└─ NAT Gateway

&#x20;   ↓

Private-App-Subnet

└─ APP EC2

&#x20;   ↓

Private-External-Subnet

└─ MYDATA EC2

&#x20;   ↓

Private-Data-Subnet

├─ DATA EC2

└─ RDS

```



\---



\# 남은 작업



\## 최우선 작업



\### Docker Compose 재작성



AWS 환경 기준으로 Compose 분리 필요



\* APP 서버용

\* MYDATA 서버용

\* DATA 서버용



\---



\### AWS 실행 스크립트 작성



필요 작업



\* docker login ghcr.io

\* docker compose pull

\* docker compose up -d

\* docker image prune

\* restart 스크립트 작성



\---



\### GitHub Actions 수정



GHCR Push 기준으로 변경 필요



대상 서비스



\* frontend

\* backend

\* ai

\* mydata



\---



\# 인프라 작업



\## ALB 생성



필요 사항



\* HTTPS Listener

\* HTTP → HTTPS Redirect

\* ACM 인증서 연결



\---



\## Target Group 생성



필요 대상



\* frontend

\* backend

\* ai



추가 작업



\* Health Check 설정



\---



\## Route53 연결



필요 작업



\* ALB Alias 설정

\* 서비스 도메인 연결



\---



\# 서버별 구성 작업



\## DATA 서버



Docker Compose 작성 필요



예상 구성



\* redis

\* postgres-analysis

\* postgres-pgvector



추가 고려 사항



\* Volume 설계



\---



\## APP 서버



Docker Compose 작성 필요



예상 구성



\* frontend

\* backend

\* ai



추가 고려 사항



\* 환경변수 정리



\---



\## MYDATA 서버



Docker Compose 작성 필요



예상 구성



\* mydata-server



\---



\# VPN / 온프레미스 연동



현재 상태



\* 미착수



선택지



\## AWS Site-to-Site VPN



장점



\* AWS 관리형

\* 운영 편의성 우수



단점



\* 비용 발생



\---



\## StrongSwan 기반 IPSec



구성



AWS EC2

\+

온프레미스 StrongSwan



장점



\* 비용 절감



단점



\* 직접 운영 필요

\* IPSec 구성 필요



필요 작업



\* IPSec 정책 정의

\* Tunnel 설정

\* 온프레미스 구성

\* 라우팅 구성

\* 통신 테스트



\---



\# 현재 진행률



| 항목      | 진행률  |

| ------- | ---- |

| 네트워크    | 100% |

| 컴퓨팅     | 100% |

| RDS     | 100% |

| 배포 자동화  | 40%  |

| 서비스 배포  | 0%   |

| ALB     | 0%   |

| Route53 | 0%   |

| VPN     | 0%   |



\---



\# 전체 체감 진행률



\*\*약 70%\*\*

