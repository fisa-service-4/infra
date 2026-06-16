package com.integration.health;

import com.integration.config.ServerConfig;
import com.integration.support.TestFixtures;
import io.restassured.RestAssured;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("서버 헬스 체크")
class HealthCheckTest {

    @Test
    @DisplayName("bank-server 헬스 체크 → database UP, server UP")
    void bankServerHealth() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.BANK_SERVER)
                .header("X-User-Id", TestFixtures.USER1_ORACLE_USER_ID)
                .header("X-Trace-Id", "health-check-test")
            .when()
                .get("/internal/v1/bank/health")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getString("data.server")).isEqualTo("UP");
        assertThat(resp.jsonPath().getString("data.database")).isEqualTo("UP");
    }

    @Test
    @DisplayName("stock-server 헬스 체크 → database UP, server UP")
    void stockServerHealth() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.STOCK_SERVER)
                .header("X-User-Id", TestFixtures.USER1_ORACLE_USER_ID)
                .header("X-Trace-Id", "health-check-test")
            .when()
                .get("/internal/v1/stock/health")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getString("data.server")).isEqualTo("UP");
        assertThat(resp.jsonPath().getString("data.database")).isEqualTo("UP");
    }

    @Test
    @DisplayName("service-backend Spring Actuator 헬스 체크 → 200 또는 503(일부 컴포넌트 DOWN)")
    void serviceBackendActuator() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
            .when()
                .get("/actuator/health")
            .then()
                .extract().statusCode();

        // 200=전체 UP, 503=일부 DOWN — 서버 자체는 응답 중
        assertThat(status).isIn(200, 503);
    }

    @Test
    @DisplayName("transaction-server BaaS 엔드포인트 응답 확인 → 2xx 또는 4xx")
    void transactionServerReachability() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts")
            .then()
                .extract().statusCode();

        assertThat(status).isBetween(200, 499);
    }

    @Test
    @DisplayName("mydata-server 엔드포인트 응답 확인 → 2xx 또는 4xx")
    void mydataServerReachability() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
            .when()
                .get("/mydata/v1/connections")
            .then()
                .extract().statusCode();

        assertThat(status).isBetween(200, 499);
    }
}
