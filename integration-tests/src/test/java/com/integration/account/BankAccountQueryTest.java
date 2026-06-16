package com.integration.account;

import com.integration.config.ServerConfig;
import com.integration.support.TestFixtures;
import io.restassured.RestAssured;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 크로스 서버 계좌 조회 테스트
 * - BaaS 경로: transaction-server → bank-server (Oracle)
 * - X-Firebase-Uid 헤더로 사용자 식별 (transaction-server의 user_master 테이블 기반)
 */
@DisplayName("은행 계좌 조회 (transaction-server → bank-server)")
class BankAccountQueryTest {

    @Test
    @DisplayName("BaaS 계좌 목록 조회 → X-Firebase-Uid 헤더로 사용자 계좌 반환")
    void getBaasAccountList() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
                .header("X-Firebase-Uid", TestFixtures.USER1_FIREBASE_UID)
            .when()
                .get("/baas/v1/bank/accounts")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getList("data.content")).isNotEmpty();
    }

    @Test
    @DisplayName("BaaS 계좌 상세 조회 → accountId로 상세 정보 반환")
    void getBaasAccountDetail() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts/" + TestFixtures.USER1_INCOME_ACCOUNT_ID)
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getLong("data.accountId")).isEqualTo(TestFixtures.USER1_INCOME_ACCOUNT_ID);
        assertThat(resp.jsonPath().getString("data.bankCode")).isEqualTo("088");
    }

    @Test
    @DisplayName("BaaS 계좌 잔액 조회 → balance 0 이상")
    void getBaasAccountBalance() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts/" + TestFixtures.USER1_INCOME_ACCOUNT_ID + "/balance")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getDouble("data.balance")).isGreaterThanOrEqualTo(0.0);
    }

    @Test
    @DisplayName("BaaS 거래 내역 조회 → 페이지네이션 응답 반환")
    void getBaasAccountTransactions() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts/" + TestFixtures.USER1_INCOME_ACCOUNT_ID + "/transactions")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getList("data.content")).isNotNull();
    }

    @Test
    @DisplayName("X-Firebase-Uid 헤더 없이 계좌 목록 조회 → 400 또는 인증 오류")
    void getBaasAccountListWithoutFirebaseUid() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts")
            .then()
                .extract().statusCode();

        assertThat(status).isBetween(400, 499);
    }

    @Test
    @DisplayName("존재하지 않는 계좌 조회 → 404")
    void getNonExistentAccount() {
        int status = RestAssured
            .given()
                .baseUri(ServerConfig.TRANSACTION_SERVER)
            .when()
                .get("/baas/v1/bank/accounts/99999999")
            .then()
                .extract().statusCode();

        assertThat(status).isEqualTo(404);
    }

    @Test
    @DisplayName("bank-server 직접 계좌 잔액 조회 → X-User-Id + X-Trace-Id 필수")
    void getBankServerAccountBalance() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.BANK_SERVER)
                .header("X-User-Id", TestFixtures.USER1_ORACLE_USER_ID)
                .header("X-Trace-Id", "test-trace-001")
            .when()
                .get("/internal/v1/bank/accounts/" + TestFixtures.USER1_INCOME_ACCOUNT_ID + "/balance")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getLong("data.accountId")).isEqualTo(TestFixtures.USER1_INCOME_ACCOUNT_ID);
        assertThat(resp.jsonPath().getDouble("data.balance")).isGreaterThan(0.0);
    }
}
