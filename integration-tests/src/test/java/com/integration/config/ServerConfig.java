package com.integration.config;

public class ServerConfig {

    public static final String SERVICE_BACKEND    = prop("SERVICE_BACKEND_URL",    "http://localhost:8080");
    public static final String BANK_SERVER        = prop("BANK_SERVER_URL",        "http://localhost:8081");
    public static final String STOCK_SERVER       = prop("STOCK_SERVER_URL",       "http://localhost:8082");
    public static final String TRANSACTION_SERVER = prop("TRANSACTION_SERVER_URL", "http://localhost:8083");
    public static final String MYDATA_SERVER      = prop("MYDATA_SERVER_URL",      "http://localhost:8084");
    public static final String AI_SERVER          = prop("AI_SERVER_URL",          "http://localhost:8000");

    private static String prop(String key, String defaultValue) {
        String v = System.getProperty(key);
        return (v != null && !v.isBlank()) ? v : defaultValue;
    }
}
