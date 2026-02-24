export interface AdminUser {
  uid: string;
  email: string;
  role: "super_admin" | "admin" | "viewer";
}

export interface AppUser {
  id: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  provider: "apple" | "google" | "email";
  createdAt: string;
  lastLogin: string;
  platform: "ios" | "android" | "unknown";
  disabled: boolean;
  defaultCoverDesignId: string | null;
}

export interface Purchase {
  id: string;
  sku: string;
  platform: "google_play" | "app_store";
  transactionId: string;
  purchaseDate: string;
  status: "active" | "refunded" | "expired";
}

export interface Entitlements {
  proLifetime: boolean;
  purchasedPacks: string[];
  photoOverlayCount: number;
}

export interface DesignUsage {
  designId: string;
  count: number;
  lastUsed: string;
}
