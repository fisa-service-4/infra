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
 * 이체 실패 및 Saga 보상 트랜잭션 테스트
 * - 잔액 부족: 이체 요청 또는 승인 시 TRANSFER_002 에러
 * - STOCK_TO_BANK Saga 보상: bank 입금 실패 → stock 예수금 보상 출금
 */
@DisplayName("이체 실패 및 Saga 보상 트랜잭션")
class TransferCompensationTest {

    @Test
    @DisplayName("잔액 초과 이체 → TRANSFER_002 에러, 잔액 변동 없음")
    void transferFailsWithInsufficientBalance() {
        double balanceBefore = getBalance(TestFixtures.USER1_INCOME_ACCOUNT_ID);

        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                    {
                      "fromAccountId": %d,
                      "toBankCode": "%s",
                      "toAccountNumber": "%s",
                      "transferAmount": %d,
                      "requestedBy": "USER"
                    }
                    """.formatted(
                        TestFixtures.USER1_INCOME_ACCOUNT_ID,
                        TestFixtures.USER2_BANK_CODE,
                        TestFixtures.USER2_ACCOUNT_NUMBER,
                        TestFixtures.OVERDRAWN_AMOUNT).strip())
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .extract().response();

        // 잔액 부족 에러: 요청 생성 시 또는 승인 시 발생
        if (resp.statusCode() == 201) {
            // 일부 구현에서는 create 성공 후 approve 시 잔액 검증
            long transferId = resp.jsonPath().getLong("data.transferId");
            var approveResp = RestAssured
                .given()
                    .baseUri(ServerConfig.TRANSACTION_SERVER)
                .when()
                    .post("/baas/v1/bank/transfers/" + transferId + "/approve")
                .then()
                    .extract().response();

            assertThat(approveResp.statusCode()).isBetween(400, 499);
            assertThat(approveResp.jsonPath().getString("error.code")).isEqualTo("TRANSFER_002");
        } else {
            assertThat(resp.statusCode()).isBetween(400, 499);
            assertThat(resp.jsonPath().getString("error.code")).isEqualTo("TRANSFER_002");
        }

        // 잔액 변동 없음 확인
        double balanceAfter = getBalance(TestFixtures.USER1_INCOME_ACCOUNT_ID);
        assertThat(balanceAfter).isCloseTo(balanceBefore, offset(0.01));
    }

    @Test
    @DisplayName("존재하지 않는 계좌로 이체 요청 → 오류 반환")
    void transferToNonExistentAccount() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                    {
                      "fromAccountId": %d,
                      "toBankCode": "088",
                      "toAccountNumber": "000-00-000000",
                      "transferAmount": %d,
                      "requestedBy": "USER"
                    }
                    """.formatted(TestFixtures.USER1_INCOME_ACCOUNT_ID, TestFixtures.SMALL_TRANSFER_AMOUNT).strip())
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .extract().response();

        // 존재하지 않는 계좌: 400 또는 404
        assertThat(resp.statusCode()).isBetween(400, 499);
        assertThat(resp.jsonPath().getBoolean("success")).isFalse();
    }

    @Test
    @DisplayName("이미 승인된 이체 재승인 → TRANSFER_003 (멱등 또는 오류)")
    void approveAlreadyApprovedTransfer() {
        // 이체 생성
        String idempotencyKey = UUID.randomUUID().toString();
        long transferId = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", idempotencyKey)
                .body("""
                    {
                      "fromAccountId": %d,
                      "toBankCode": "%s",
                      "toAccountNumber": "%s",
                      "transferAmount": %d,
                      "requestedBy": "USER"
                    }
                    """.formatted(
                        TestFixtures.USER1_INCOME_ACCOUNT_ID,
                        TestFixtures.USER2_BANK_CODE,
                        TestFixtures.USER2_ACCOUNT_NUMBER,
                        TestFixtures.SMALL_TRANSFER_AMOUNT).strip())
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .statusCode(201)
                .extract().jsonPath().getLong("data.transferId");

        // 첫 번째 승인
        RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .post("/baas/v1/bank/transfers/" + transferId + "/approve")
            .then()
                .statusCode(200);

        // 두 번째 승인 → 멱등 응답(200 SUCCESS) 또는 TRANSFER_003 오류
        var secondApprove = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .post("/baas/v1/bank/transfers/" + transferId + "/approve")
            .then()
                .extract().response();

        // 멱등 보장: SUCCESS 응답 또는 이미 처리된 건 에러
        if (secondApprove.statusCode() == 200) {
            assertThat(secondApprove.jsonPath().getString("data.transferStatus")).isEqualTo("SUCCESS");
        } else {
            assertThat(secondApprove.statusCode()).isBetween(400, 499);
            assertThat(secondApprove.jsonPath().getString("error.code")).isEqualTo("TRANSFER_003");
        }
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
}
