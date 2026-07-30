// Mirrors the subset of context/supabase-backend.md's schema this dashboard
// reads/writes. Keep in sync with the Flutter app's lib/shared/types/domain_types.dart.

export type AccountRole = 'athlete' | 'recruiter' | 'club' | 'coach' | 'admin';
export type VerificationStatus = 'pending' | 'approved' | 'rejected';
export type SubscriptionTier =
  | 'free'
  | 'premium_monthly'
  | 'premium_annual'
  | 'recruiter_basic'
  | 'recruiter_pro'
  | 'club_grassroots'
  | 'club_professional'
  | 'club_enterprise';
export type ContentType = 'video' | 'photo' | 'post';
export type PaymentStatus = 'pending' | 'success' | 'failed' | 'refunded';
export type SubscriptionStatus = 'active' | 'grace_period' | 'expired' | 'cancelled';

export type UserRow = {
  id: string;
  name: string;
  email: string;
  role: AccountRole;
  verification_status: VerificationStatus;
  subscription_tier: SubscriptionTier;
  is_banned: boolean;
  created_at: string;
};

export type AthleteContentRow = {
  id: string;
  athlete_id: string;
  type: ContentType;
  title: string;
  description: string;
  file_url: string | null;
  thumbnail_url: string | null;
  flagged: boolean;
  like_count: number;
  comment_count: number;
  created_at: string;
  athletes?: { display_name: string; user_id: string } | null;
};

export type VerificationDocumentRow = {
  id: string;
  user_id: string;
  document_url: string;
  document_type: string;
  status: VerificationStatus;
  reviewed_by: string | null;
  reviewed_at: string | null;
  created_at: string;
  users?: { name: string; email: string; role: AccountRole } | null;
};

export type SubscriptionRow = {
  id: string;
  user_id: string;
  tier: SubscriptionTier;
  status: SubscriptionStatus;
  current_period_start: string;
  current_period_end: string | null;
  provider: string | null;
  created_at: string;
  users?: { name: string; email: string } | null;
};

export type PaymentTransactionRow = {
  id: string;
  user_id: string;
  amount_ugx: number;
  provider: string;
  description: string;
  status: PaymentStatus;
  created_at: string;
  users?: { name: string; email: string } | null;
};

export type SubscriptionPlanRow = {
  tier: SubscriptionTier;
  name: string;
  price_ugx: number;
  features: string[];
  is_popular: boolean;
};
