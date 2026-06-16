package com.integration.auth;

import com.integration.config.ServerConfig;
import com.integration.support.TestFixtures;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("인증 플로우 (service-backend)")
class AuthFlowTest {

    @Test
    @DisplayName("로그인 성공 → accessToken, refreshToken 반환")
    void loginSuccess() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .contentType(ContentType.JSON)
                .body(loginBody(TestFixtures.USER1_EMAIL, TestFixtures.USER1_PASSWORD))
            .when()
                .post("/api/v1/auth/login")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getString("data.accessToken")).isNotBlank();
        assertThat(resp.jsonPath().getString("data.refreshToken")).isNotBlank();
        assertThat(resp.jsonPath().getString("data.user.email")).isEqualTo(TestFixtures.USER1_EMAIL);
    }

    @Test
    @DisplayName("잘못된 비밀번호로 로그인 → AUTH_003 에러 코드 반환")
    void loginFailWithWrongPassword() {
        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .contentType(ContentType.JSON)
                .body(loginBody(TestFixtures.USER1_EMAIL, "WrongPassword123!"))
            .when()
                .post("/api/v1/auth/login")
            .then()
                .extract().response();

        assertThat(resp.statusCode()).isBetween(400, 401);
        assertThat(resp.jsonPath().getBoolean("success")).isFalse();
        assertThat(resp.jsonPath().getString("error.code")).isEqualTo("AUTH_003");
    }

    @Test
    @DisplayName("로그인 후 GET /users/me → 이메일 일치")
    void getMyInfoWithValidToken() {
        String token = loginAndGetToken(TestFixtures.USER1_EMAIL, TestFixtures.USER1_PASSWORD);

        var resp = RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .header("Authorization", "Bearer " + token)
            .when()
                .get("/api/v1/users/me")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(resp.jsonPath().getBoolean("success")).isTrue();
        assertThat(resp.jsonPath().getString("data.email")).isEqualTo(TestFixtures.USER1_EMAIL);
    }

    @Test
    @DisplayName("토큰 없이 /users/me 호출 → 401")
    void getMyInfoWithoutToken() {
        RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
            .when()
                .get("/api/v1/users/me")
            .then()
                .statusCode(401);
    }

    @Test
    @DisplayName("refreshToken으로 새 accessToken 발급")
    void tokenReissue() {
        var loginResp = RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .contentType(ContentType.JSON)
                .body(loginBody(TestFixtures.USER1_EMAIL, TestFixtures.USER1_PASSWORD))
            .when()
                .post("/api/v1/auth/login")
            .then()
                .statusCode(200)
                .extract().response();

        String refreshToken = loginResp.jsonPath().getString("data.refreshToken");

        var reissueResp = RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .contentType(ContentType.JSON)
                .body("""
                    {"refreshToken":"%s"}
                    """.formatted(refreshToken).strip())
            .when()
                .post("/api/v1/auth/reissue")
            .then()
                .statusCode(200)
                .extract().response();

        assertThat(reissueResp.jsonPath().getBoolean("success")).isTrue();
        assertThat(reissueResp.jsonPath().getString("data.accessToken")).isNotBlank();
    }

    @Test
    @DisplayName("로그아웃 성공")
    void logoutSuccess() {
        String token = loginAndGetToken(TestFixtures.USER1_EMAIL, TestFixtures.USER1_PASSWORD);

        RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .header("Authorization", "Bearer " + token)
            .when()
                .post("/api/v1/auth/logout")
            .then()
                .statusCode(200);
    }

    private String loginAndGetToken(String email, String password) {
        return RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .contentType(ContentType.JSON)
                .body(loginBody(email, password))
            .when()
                .post("/api/v1/auth/login")
            .then()
                .statusCode(200)
                .extract().jsonPath().getString("data.accessToken");
    }

    private String loginBody(String email, String password) {
        return """
            {"email":"%s","password":"%s"}
            """.formatted(email, password).strip();
    }
}
