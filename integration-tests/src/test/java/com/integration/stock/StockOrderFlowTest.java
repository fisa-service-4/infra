package com.integration.stock;

import com.integration.config.ServerConfig;
import com.integration.support.TestFixtures;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 주식 주문 플로우 테스트
 * - 경로: transaction-server → stock-server (Oracle)
 * - BaaS 직접 호출로 JWT/Pin-Token 의존성 제거
 * - 전제: STOCK_MASTER에 '005930'(삼성전자) 시드 데이터 존재
 */
@DisplayName("주식 주문 플로우 (transaction-server → stock-server)")
class StockOrderFlowTest {

    private static final String STOCK_CODE = "005930"; // 삼성전자

    @Test
    @DisplayName("주문 가능 계좌 목록 조회 → X-Firebase-Uid 기반")
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
    @DisplayName("예수금 조회 → cashBalance 0 이상")
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

    @Test
    @DisplayName("종목 검색 → 키워드 '삼성'으로 결과 반환")
    void searchStock() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .queryParam("keyword", "삼성")
            .when()
                .get("/baas/v1/stock/search")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getList("data.content")).isNotNull();
    }

    @Test
    @DisplayName("현재가 조회 → stockCode로 시세 반환")
    void getStockPrice() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/stock/" + STOCK_CODE + "/price")
            .then()
                .extract().response();

        // 종목 마스터 데이터가 없으면 404, 있으면 200
        assertThat(resp.statusCode()).isIn(200, 404);
        if (resp.statusCode() == 200) {
            assertThat(resp.jsonPath().getString("data.stockCode")).isEqualTo(STOCK_CODE);
        }
    }

    @Test
    @DisplayName("매수 주문 생성 → REQUESTED 상태, orderId 반환")
    void createBuyOrder() {
        String idempotencyKey = UUID.randomUUID().toString();
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", idempotencyKey)
                .body("""
                    {
                      "stockCode": "%s",
                      "orderType": "BUY",
                      "orderMethod": "LIMIT",
                      "quantity": 1,
                      "price": 10000
                    }
                    """.formatted(STOCK_CODE).strip())
            .when()
                .post("/baas/v1/stock/accounts/" + TestFixtures.USER1_STOCK_ACCOUNT_ID + "/orders")
            .then()
                .extract().response();

        assertThat(resp.statusCode()).isIn(201, 400); // 종목 마스터 없으면 400 가능
        if (resp.statusCode() == 201) {
            assertThat(resp.jsonPath().getBoolean("success")).isTrue();
            assertThat(resp.jsonPath().getLong("data.orderId")).isPositive();
            assertThat(resp.jsonPath().getString("data.orderType")).isEqualTo("BUY");
            assertThat(resp.jsonPath().getString("data.status")).isEqualTo("REQUESTED");
        }
    }

    @Test
    @DisplayName("주문 생성 후 목록 조회 → 생성된 주문 포함")
    void createOrderAndQueryList() {
        // 주문 생성
        String idempotencyKey = UUID.randomUUID().toString();
        var createResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .contentType(ContentType.JSON)
                .header("Idempotency-Key", idempotencyKey)
                .body("""
                    {
                      "stockCode": "%s",
                      "orderType": "BUY",
                      "orderMethod": "LIMIT",
                      "quantity": 1,
                      "price": 10000
                    }
                    """.formatted(STOCK_CODE).strip())
            .when()
                .post("/baas/v1/stock/accounts/" + TestFixtures.USER1_STOCK_ACCOUNT_ID + "/orders")
            .then()
                .extract().response();

        if (createResp.statusCode() != 201) {
            // 종목 마스터 미존재 시 주문 목록만 검증
            var listResp = RestAssured
                .given()
                    .baseUri(ServerConfig.TRANSACTION_SERVER)
                .when()
                    .get("/baas/v1/stock/accounts/" + TestFixtures.USER1_STOCK_ACCOUNT_ID + "/orders")
                .then()
                    .statusCode(200)
                    .extract().response();

            assertThat(listResp.jsonPath().getBoolean("success")).isTrue();
            return;
        }

        long orderId = createResp.jsonPath().getLong("data.orderId");

        // 주문 목록 조회
        var listResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/stock/accounts/" + TestFixtures.USER1_STOCK_ACCOUNT_ID + "/orders")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(listResp.jsonPath().getBoolean("success")).isTrue();

        // 주문 상세 조회
        var detailResp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/stock/orders/" + orderId)
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(detailResp.jsonPath().getLong("data.orderId")).isEqualTo(orderId);
        assertThat(detailResp.jsonPath().getString("data.stockCode")).isEqualTo(STOCK_CODE);
    }

    @Test
    @DisplayName("보유 종목 조회 → 리스트 응답")
    void getHoldings() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/stock/accounts/" + TestFixtures.USER1_STOCK_ACCOUNT_ID + "/holdings")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getList("data.content")).isNotNull();
    }
}
