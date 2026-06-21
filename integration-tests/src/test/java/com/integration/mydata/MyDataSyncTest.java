package com.integration.mydata;

import com.integration.config.ServerConfig;
import com.integration.support.TestFixtures;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * MyData 서버 통합 테스트
 * - mydata-server는 bank-server + stock-server에서 데이터를 집계
 * - JWT 없이 X-Firebase-Uid + X-Trace-Id 헤더로 사용자 식별
 */
@DisplayName("MyData 집계 (mydata-server → bank-server + stock-server)")
class MyDataSyncTest {

    @Test
    @DisplayName("연동 목록 조회 → X-Firebase-Uid 기반")
    void getConnections() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
                .header("X-Trace-Id", UUID.randomUUID().toString())
            .when()
                .get("/mydata/v1/connections")
            .then()
                .extract().response();

        assertThat(resp.statusCode()).isIn(200, 404);
        if (resp.statusCode() == 200) {
            assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        }
    }

    @Test
    @DisplayName("마이데이터 연동 요청 → 성공 또는 이미 연동된 기관")
    void connectInstitution() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
                .contentType(ContentType.JSON)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
                .header("X-Trace-Id", UUID.randomUUID().toString())
                .body("""
                    {"provider":"SHINHAN_BANK"}
                    """.strip())
            .when()
                .post("/mydata/v1/connect")
            .then()
                .extract().response();

        // 200 성공 또는 이미 연동된 기관(MYDATA_001)
        assertThat(resp.statusCode()).isIn(200, 400, 409);
    }

    @Test
    @DisplayName("은행 계좌 집계 조회 → bank-server에서 데이터 집계")
    void getBankAccounts() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
                .header("X-Trace-Id", UUID.randomUUID().toString())
            .when()
                .get("/mydata/v1/bank/accounts")
            .then()
                .extract().response();

        // 연동 안 되어 있으면 빈 목록 또는 404
        assertThat(resp.statusCode()).isIn(200, 404);
        if (resp.statusCode() == 200) {
            assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        }
    }

    @Test
    @DisplayName("증권 계좌 집계 조회 → stock-server에서 데이터 집계")
    void getStockAccounts() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
                .header("X-Trace-Id", UUID.randomUUID().toString())
            .when()
                .get("/mydata/v1/stock/accounts")
            .then()
                .extract().response();

        assertThat(resp.statusCode()).isIn(200, 404);
        if (resp.statusCode() == 200) {
            assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        }
    }

    @Test
    @DisplayName("전체 자산 집계 조회")
    void getTotalAssets() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
                .header("X-Trace-Id", UUID.randomUUID().toString())
            .when()
                .get("/mydata/v1/assets")
            .then()
                .extract().response();

        assertThat(resp.statusCode()).isIn(200, 404);
        if (resp.statusCode() == 200) {
            assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        }
    }

    @Test
    @DisplayName("X-Firebase-Uid 없이 연동 목록 조회 → 400")
    void getConnectionsWithoutFirebaseUid() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.MYDATA_SERVER)
                .header("X-Trace-Id", UUID.randomUUID().toString())
            .when()
                .get("/mydata/v1/connections")
            .then()
                .extract().statusCode();

        assertThat(status).isBetween(400, 499);
    }
}
