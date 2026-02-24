/**
 * Firebase Cloud Functions entry point.
 * All functions are exported from here.
 */

// Auth triggers
export { onUserCreated, onUserDeleted } from "./auth/triggers";

// Admin API
export { adminApi } from "./admin/routes";

// IAP verification
export { iapApi } from "./iap/verify";

// Sync endpoints
export { syncApi } from "./sync/routes";
