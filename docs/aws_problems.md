# AWS 배포 트러블슈팅 기록

> 환경: AWS EC2 (service-backend, service-frontend, service-ai-server)
> 날짜: 2026-06-10

---

## 1. postgres-log UnknownHostException

**증상**
```
UnknownHostException: postgres-log
```
`backend.prod.env`에 `LOG_DATASOURCE_URL=jdbc:postgresql://172.16.30.10:5432/finance_log`로 설정했는데,
실제 실행 로그에서는 `postgres-log` 호스트로 접속 시도.

**원인**
`application-aws.yml`이 Docker 이미지에 포함되어 있지 않았음.
`SPRING_PROFILES_ACTIVE=app,aws`로 `aws` 프로파일이 활성화되지만 파일이 없으니 로드 실패.
결국 `application-app.yaml`의 하드코딩된 `postgres-log` 값이 그대로 사용됨.

**해결**
Spring의 `SystemEnvironmentPropertySource` relaxed binding 활용.
환경변수명 규칙: 점(`.`)과 하이픈(`-`)을 언더스코어(`_`)로, 전체 대문자.

`backend.prod.env`에 아래 형식으로 설정:
```
LOG_DATASOURCE_URL=jdbc:postgresql://172.16.30.10:5432/finance_log
LOG_DATASOURCE_USERNAME=admin
LOG_DATASOURCE_PASSWORD=...
ANALYTICS_DATASOURCE_URL=jdbc:postgresql://172.16.30.10:5432/finance_analytics
ANALYTICS_DATASOURCE_USERNAME=admin
ANALYTICS_DATASOURCE_PASSWORD=...
```

> `@Value("${log.datasource.url}")` 는 relaxed binding 미지원이지만
> `SystemEnvironmentPropertySource`는 지원하므로 환경변수로 주입 가능.

---

## 2. RestClient Bad authority (transactionServerRestClient)

**증상**
```
Bad authority: <CORE_VPN_OR_PUBLIC_IP>
```
앱 컨텍스트 초기화 중 `RestClient.builder().baseUrl()` 호출 시 발생.

**원인**
`backend.prod.env`의 `TRANSACTION_SERVER_URL` 값이 `<CORE_VPN_OR_PUBLIC_IP>` 그대로 (플레이스홀더 미치환).
Spring `RestClient`는 컨텍스트 초기화 시점에 base URL을 즉시 파싱/검증하므로,
플레이스홀더 문자열(`<`, `>` 포함)이 들어오면 URL 파싱 실패.

**해결**
VPN/온프레미스 IP가 확정될 때까지 임시 주소로 대체:
```
TRANSACTION_SERVER_URL=http://172.0.0.1:8083
MYDATA_SERVER_URL=http://172.16.20.10:8084
```

> 실제 IP 확정 시 값 교체 필요.

---

## 3. FirebaseConfig: no JSON input found

**증상**
```
FirebaseConfig: no JSON input found
```
앱 시작 시 Firebase Admin SDK 초기화 실패.

**원인**
`docker-compose-prod-app.yml`에서 `./secrets/firebase.json:/app/firebase.json:ro` 볼륨 마운트가 설정되어 있으나,
EC2의 `~/infra/secrets/firebase.json` 파일이 없었음.

**해결**
Firebase 콘솔에서 서비스 계정 JSON을 발급받아 EC2에 직접 업로드:
```bash
# 로컬에서 EC2로 전송
scp firebase.json ubuntu@<EC2_IP>:~/infra/secrets/firebase.json
```

---

## 4. service-backend healthcheck unhealthy

**증상**
앱은 정상 기동(`Started ServiceBackendApplication in 17s`)되는데
`docker ps`에서 `(unhealthy)` 상태.
`service-frontend`는 `service_healthy` 조건 미충족으로 `Created` 상태에서 멈춤.

**원인**
Docker Compose healthcheck:
```yaml
test: ["CMD-SHELL", "curl -sf http://localhost:8080/actuator/health || exit 1"]
```
`/actuator/health` 엔드포인트가 Spring Security의 `anyRequest().authenticated()` 규칙에 걸려 **401** 반환.
`curl -sf`는 4xx를 오류로 처리하므로 exit 1 → healthcheck 실패.

**해결**
`SecurityConfig.java`의 `PUBLIC_URLS`에 `/actuator/**` 추가:
```java
private static final String[] PUBLIC_URLS = {
    "/api/v1/auth/...",
    ...
    "/actuator/**",   // 추가
};
```

> `/actuator/health` 엔드포인트는 Spring Boot Actuator가 자동으로 생성하므로 별도 코드 추가 불필요.
> Security 허용만 추가하면 됨.

---

## 5. bank.server.url 프로퍼티 누락

**증상**
```
Could not resolve placeholder 'bank.server.url' in value "${bank.server.url}"
```
`BankAdminClient` 빈 생성 실패로 앱 시작 자체가 불가.

**원인**
새 이미지에 `BankAdminClient`가 추가되었는데, 이 클래스가 `@Value("${bank.server.url}")`로
bank-server URL을 주입받음. 해당 프로퍼티가 `backend.prod.env`에 없었음.

**사용처**
- `BankAdminClient` → `AdminLogService` → `AdminLogController`
- 호출 API: `GET {bank.server.url}/internal/v1/bank/admin/transfers` (관리자 이체 이력 조회)

**해결**
`backend.prod.env`에 추가:
```
BANK_SERVER_URL=http://<BANK_SERVER_IP>:8081
```

> bank-server는 온프레미스에 있으므로 VPN 연결 후 실제 IP로 교체 필요.
> 앱 기동만 필요하다면 임시 주소(`http://localhost:8081`)도 가능 (실제 API 호출 시에만 오류 발생).

---

## 기타

### backend.prod.env gitignore 주의
`backend.prod.env`는 `.gitignore`에 등록되어 있어 커밋되지 않음.
EC2 서버에서 직접 수정해야 하며, 변경 내용은 반드시 `backend.prod.env.example`에도 반영할 것.

### service-frontend 재시작
`service-backend`가 `healthy` 상태가 된 후 `service-frontend`를 별도로 올려야 함:
```bash
docker compose -f docker-compose-prod-app.yml up -d service-frontend
```
