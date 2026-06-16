package com.integration.support;

public class TestFixtures {

    // ── Integration Test User 1 (Oracle user_id=9001) ─────────────────────────
    // NOT a persona account — dedicated for integration tests only
    public static final String USER1_EMAIL        = "integration.user1@test.com";
    public static final String USER1_PASSWORD     = "Test1234!";
    public static final String USER1_FIREBASE_UID = "integration_test_user1";
    public static final String USER1_ORACLE_USER_ID = "9001"; // Oracle USER_MASTER.user_id (for X-User-Id header)

    // Bank accounts (Oracle BANK_ACCOUNT, user_id=9001)
    public static final long USER1_INCOME_ACCOUNT_ID  = 9001L; // 신한 088, 110-9001-000001, 잔액 50,000,000
    public static final long USER1_SAVINGS_ACCOUNT_ID = 9002L; // 우리 020, 1002-9001-000001, 잔액 30,000,000

    // Securities accounts (Oracle SECURITIES_ACCOUNT, user_id=9001)
    public static final long USER1_STOCK_ACCOUNT_ID = 9901L; // 한국투자 243, 90000001-01, 예수금 20,000,000

    // ── Integration Test User 2 (Oracle user_id=9002) ─────────────────────────
    public static final String USER2_EMAIL        = "integration.user2@test.com";
    public static final String USER2_PASSWORD     = "Test1234!";
    public static final String USER2_FIREBASE_UID = "integration_test_user2";

    // Bank accounts (Oracle BANK_ACCOUNT, user_id=9002)
    public static final long USER2_INCOME_ACCOUNT_ID = 9003L; // 신한 088, 110-9002-000001, 잔액 50,000,000

    // ── Transfer targets ────────────────────────────────────────────────────────
    // User1 bank → User2 bank (BANK_TO_BANK)
    public static final String USER2_BANK_CODE      = "088";
    public static final String USER2_ACCOUNT_NUMBER = "110-9002-000001";

    // User1 bank → User1 stock (BANK_TO_STOCK via Saga)
    public static final String USER1_STOCK_BROKER_CODE    = "243"; // 한국투자증권
    public static final String USER1_STOCK_ACCOUNT_NUMBER = "90000001-01";

    // ── Transfer amounts ────────────────────────────────────────────────────────
    public static final long SMALL_TRANSFER_AMOUNT = 1_000L;          // 잔액에 영향 최소화
    public static final long OVERDRAWN_AMOUNT      = 999_999_999L;    // 잔액 초과
}
