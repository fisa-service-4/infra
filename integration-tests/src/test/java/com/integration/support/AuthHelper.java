package com.integration.support;

import com.integration.config.ServerConfig;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;

public class AuthHelper {

    public static String login(String email, String password) {
        return RestAssured
            .given()
                .baseUri(ServerConfig.SERVICE_BACKEND)
                .contentType(ContentType.JSON)
                .body("""
                    {"email":"%s","password":"%s"}
                    """.formatted(email, password).strip())
            .when()
                .post("/api/v1/auth/login")
            .then()
                .statusCode(200)
                .extract().response()
                .jsonPath().getString("data.accessToken");
    }

    public static String loginAsUser1() {
        return login(TestFixtures.USER1_EMAIL, TestFixtures.USER1_PASSWORD);
    }

    public static String loginAsUser2() {
        return login(TestFixtures.USER2_EMAIL, TestFixtures.USER2_PASSWORD);
    }
}
