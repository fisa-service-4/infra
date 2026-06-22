package com.integration.transfer;

import com.integration.config.ServerConfig;
import com.integration.support.TestFixtures;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.data.Offset.offset;

/**
 * BANK_TO_BANK 이체 전체 플로우 테스트
 * - 경로: transaction-server → bank-server (Oracle)
 * - BaaS 직접 호출: JWT 없이 fromAccountId 기반으로 사용자 식별
 * - 시드 데이터: User1 account 2001 (신한, 1,000,000원) → User2 account 110-23-000001
 */
@DisplayName("은행 간 이체 플로우 (transaction-server → bank-server)")
class BankToBankTransferTest {

    @Test
    @DisplayName("이체 요청 → 승인 → 결과 조회 → 잔액 감소 확인")
    void bankToBankTransferFullFlow() {
        // 1. 이체 전 잔액 조회
        double balanceBefore = getBalance(TestFixtures.USER1_INCOME_ACCOUNT_ID);

        // 2. 이체 요청
        String idempotencyKey = UUID.randomUUID().toString();
        var createResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", idempotencyKey)
                .body(transferBody(
                    TestFixtures.USER1_INCOME_ACCOUNT_ID,
                    TestFixtures.USER2_BANK_CODE,
                    TestFixtures.USER2_ACCOUNT_NUMBER,
                    TestFixtures.SMALL_TRANSFER_AMOUNT))
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .statusCode(201)
                .extract().response();

        assertThat(createResp.jsonPath().getBoolean("success")).isTrue();
        long transferId = createResp.jsonPath().getLong("data.transferId");
        assertThat(createResp.jsonPath().getString("data.transferStatus")).isEqualTo("REQUESTED");

        // 3. 이체 승인 (bank-server에 출금/입금 반영)
        var approveResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .post("/baas/v1/bank/transfers/" + transferId + "/approve")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(approveResp.jsonPath().getBoolean("success")).isTrue();
        assertThat(approveResp.jsonPath().getString("data.transferStatus")).isEqualTo("SUCCESS");

        // 4. 이체 결과 조회
        var resultResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/transfers/" + transferId)
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resultResp.jsonPath().getString("data.transferStatus")).isEqualTo("SUCCESS");
        assertThat(resultResp.jsonPath().getLong("data.transferAmount")).isEqualTo(TestFixtures.SMALL_TRANSFER_AMOUNT);

        // 5. 이체 후 잔액 감소 확인
        double balanceAfter = getBalance(TestFixtures.USER1_INCOME_ACCOUNT_ID);
        assertThat(balanceAfter).isCloseTo(balanceBefore - TestFixtures.SMALL_TRANSFER_AMOUNT, offset(0.01));
    }

    @Test
    @DisplayName("동일한 Idempotency-Key로 중복 요청 → 멱등 응답 반환")
    void duplicateTransferIdempotency() {
        String idempotencyKey = UUID.randomUUID().toString();
        String body = transferBody(
            TestFixtures.USER1_INCOME_ACCOUNT_ID,
            TestFixtures.USER2_BANK_CODE,
            TestFixtures.USER2_ACCOUNT_NUMBER,
            TestFixtures.SMALL_TRANSFER_AMOUNT);

        var firstResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", idempotencyKey)
                .body(body)
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .extract().response();

        assertThat(firstResp.statusCode()).isEqualTo(201);
        long firstTransferId = firstResp.jsonPath().getLong("data.transferId");

        // 같은 키로 재요청
        var secondResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", idempotencyKey)
                .body(body)
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .extract().response();

        // 멱등: 동일한 transferId 반환 또는 200 응답
        assertThat(secondResp.statusCode()).isIn(200, 201);
        long secondTransferId = secondResp.jsonPath().getLong("data.transferId");
        assertThat(secondTransferId).isEqualTo(firstTransferId);
    }

    @Test
    @DisplayName("Idempotency-Key 헤더 누락 → 400")
    void transferWithoutIdempotencyKey() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .body(transferBody(
                    TestFixtures.USER1_INCOME_ACCOUNT_ID,
                    TestFixtures.USER2_BANK_CODE,
                    TestFixtures.USER2_ACCOUNT_NUMBER,
                    TestFixtures.SMALL_TRANSFER_AMOUNT))
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .extract().statusCode();

        assertThat(status).isBetween(400, 499);
    }

    private double getBalance(long accountId) {
        return RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts/" + accountId + "/balance")
            .then()
                .statusCode(200)
                .extract().jsonPath().getDouble("data.balance");
    }

    private String transferBody(long fromAccountId, String toBankCode, String toAccountNumber, long amount) {
        return """
            {
              "fromAccountId": %d,
              "toBankCode": "%s",
              "toAccountNumber": "%s",
              "transferAmount": %d,
              "requestedBy": "USER"
            }
            """.formatted(fromAccountId, toBankCode, toAccountNumber, amount).strip();
    }
}
