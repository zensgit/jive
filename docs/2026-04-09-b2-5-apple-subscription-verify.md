# B2.5 Apple Subscription Verify

## Summary
- extend `verify-subscription` to accept `platform=apple_app_store`
- verify App Store receipts server-side through Apple's `verifyReceipt` endpoint
- let `AppStorePaymentService` push receipts into the trusted-subscription path instead of only fetching the latest snapshot

## Flow
1. Client purchase/restore succeeds in `AppStorePaymentService`.
2. Client sends `product_id + receipt_data + order_id` to `verify-subscription`.
3. Edge Function verifies against Apple's production endpoint and falls back to sandbox on `21007`.
4. Verified state is normalized into `user_subscriptions`.
5. Client applies the authoritative snapshot when the returned platform/product matches.

## Required Env
- `APPLE_APP_STORE_SHARED_SECRET`
- `APPLE_APP_STORE_BUNDLE_ID` (recommended for bundle-id mismatch protection)

## Notes
- This branch keeps the current self-hosted billing model: client -> Supabase Edge Function -> `user_subscriptions`.
- It intentionally does not add a second entitlement source.
- This uses Apple's receipt verification flow for the immediate trusted path.
- Stronger App Store Server API / certificate-chain verification can still build later on top of the webhook work in `B2.2`.
