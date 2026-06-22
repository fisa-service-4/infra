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
 * BANK_TO_STOCK Saga 이체 테스트
 * - 3-Step Saga: BANK_TRANSFER_REQUEST_CREATED → STOCK_CASH_DEPOSIT → BANK_TRANSFER_COMMIT
 * - 경로: transaction-server → bank-server + stock-server (Oracle)
 * - toBankCode=243 (한국투자증권)으로 Saga 경로 판별
 */
@DisplayName("은행→증권 Saga 이체 (transaction-server → bank-server + stock-server)")
class BankToStockTransferTest {

    @Test
    @DisplayName("BANK_TO_STOCK Saga 정상 플로우 → bank 잔액 감소, stock 예수금 증가")
    void bankToStockSagaSuccess() {
        // 1. 이체 전 잔액 조회
        double bankBalanceBefore  = getBankBalance(TestFixtures.USER1_INCOME_ACCOUNT_ID);
        double stockCashBefore    = getStockCash(TestFixtures.USER1_STOCK_ACCOUNT_ID);

        // 2. BANK_TO_STOCK 이체 요청 (toBankCode=243 → Saga 경로)
        String idempotencyKey = UUID.randomUUID().toString();
        var createResp = RestAssured
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
                        TestFixtures.USER1_STOCK_BROKER_CODE,
                        TestFixtures.USER1_STOCK_ACCOUNT_NUMBER,
                        TestFixtures.SMALL_TRANSFER_AMOUNT).strip())
            .when()
                .post("/baas/v1/bank/transfers")
            .then()
                .statusCode(201)
                .extract().response();

        assertThat(createResp.jsonPath().getBoolean("success")).isTrue();
        long transferId = createResp.jsonPath().getLong("data.transferId");

        // 3. Saga 실행 (approve → STEP1 bank debit → STEP2 stock cash deposit → STEP3 bank commit)
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

        // 4. bank 잔액 감소 확인
        double bankBalanceAfter = getBankBalance(TestFixtures.USER1_INCOME_ACCOUNT_ID);
        assertThat(bankBalanceAfter).isCloseTo(bankBalanceBefore - TestFixtures.SMALL_TRANSFER_AMOUNT, offset(0.01));

        // 5. stock 예수금 증가 확인
        double stockCashAfter = getStockCash(TestFixtures.USER1_STOCK_ACCOUNT_ID);
        assertThat(stockCashAfter).isCloseTo(stockCashBefore + TestFixtures.SMALL_TRANSFER_AMOUNT, offset(0.01));
    }

    @Test
    @DisplayName("stock 계좌 목록 조회 (BaaS) → X-Firebase-Uid 기반 반환")
    void getStockAccounts() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
            .when()
                .get("/baas/v1/stock/accounts")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getList("data.content")).isNotEmpty();
    }

    @Test
    @DisplayName("stock 예수금 조회 (BaaS) → cashBalance 0 이상")
    void getStockCashBalance() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/stock/accounts/" + TestFixtures.USER1_STOCK_ACCOUNT_ID + "/cash-balance")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getDouble("data.cashBalance")).isGreaterThanOrEqualTo(0.0);
    }

    private double getBankBalance(long accountId) {
        return RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts/" + accountId + "/balance")
            .then()
                .statusCode(200)
                .extract().jsonPath().getDouble("data.balance");
    }

    private double getStockCash(long accountId) {
        return RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/stock/accounts/" + accountId + "/cash-balance")
            .then()
                .statusCode(200)
                .extract().jsonPath().getDouble("data.cashBalance");
    }
}
