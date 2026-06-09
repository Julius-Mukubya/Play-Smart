// Shared domain types used across all system boundaries.

/// Account roles in the platform.
enum AccountRole {
  athlete,
  recruiter,
  club,
  guest,
}

/// Verification status for recruiter and club accounts.
enum VerificationStatus {
  pending,
  approved,
  rejected,
}

/// Trust badge levels for athlete achievements and profile.
enum TrustBadgeLevel {
  selfReported,
  coachEndorsed,
  clubVerified,
}

/// Subscription tiers for feature gating.
enum SubscriptionTier {
  free,
  premiumMonthly,
  premiumAnnual,
  recruiterBasic,
  recruiterPro,
  clubGrassroots,
  clubProfessional,
  clubEnterprise,
}

/// Availability status for athletes.
enum AvailabilityStatus {
  openToTrials,
  currentlyContracted,
  notAvailable,
}

/// Moment types for content tagging.
enum MomentType {
  goal,
  assist,
  sprint,
  tackle,
  save,
}

/// Content type for uploads.
enum ContentType {
  video,
  photo,
  post,
}

/// Notification event types.
enum NotificationType {
  profileView,
  shortlisted,
  trialMatch,
  endorsementRequest,
  messageRequest,
}

/// Payment provider options.
enum PaymentProvider {
  mtnMobileMoney,
  airtelMoney,
  visaMastercard,
  stripe,
}

/// Core User model.
class User {
  final String id;
  final String name;
  final String email;
  final AccountRole role;
  final VerificationStatus verificationStatus;
  final SubscriptionTier subscriptionTier;
  final DateTime? dateOfBirth;
  final bool isUnder18;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.verificationStatus = VerificationStatus.pending,
    this.subscriptionTier = SubscriptionTier.free,
    this.dateOfBirth,
    this.isUnder18 = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Athlete achievement with trust badge level.
class Achievement {
  final String id;
  final String title;
  final String description;
  final TrustBadgeLevel badgeLevel;
  final String? endorsedById;
  final String? endorsedByName;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.title,
    this.description = '',
    this.badgeLevel = TrustBadgeLevel.selfReported,
    this.endorsedById,
    this.endorsedByName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Content uploaded by an athlete.
class AthleteContent {
  final String id;
  final String athleteId;
  final ContentType type;
  final String title;
  final String description;
  final String? fileUrl;
  final String? thumbnailUrl;
  final MomentType? momentTag;
  final DateTime createdAt;

  AthleteContent({
    required this.id,
    required this.athleteId,
    required this.type,
    required this.title,
    this.description = '',
    this.fileUrl,
    this.thumbnailUrl,
    this.momentTag,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Athlete profile — single source of truth.
class Athlete {
  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<String> sports;
  final List<String> positions;
  final int? age;
  final double? height;
  final double? weight;
  final String? dominantFootHand;
  final String? currentTeam;
  final String? country;
  final String? city;
  final String? bio;
  final AvailabilityStatus availabilityStatus;
  final List<Achievement> achievements;
  final List<AthleteContent> content;
  final TrustBadgeLevel profileBadgeLevel;
  final double profileCompleteness;
  final DateTime createdAt;
  final DateTime updatedAt;

  Athlete({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.sports = const [],
    this.positions = const [],
    this.age,
    this.height,
    this.weight,
    this.dominantFootHand,
    this.currentTeam,
    this.country,
    this.city,
    this.bio,
    this.availabilityStatus = AvailabilityStatus.openToTrials,
    this.achievements = const [],
    this.content = const [],
    this.profileBadgeLevel = TrustBadgeLevel.selfReported,
    this.profileCompleteness = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

/// Shortlist for recruiters and clubs.
class Shortlist {
  final String id;
  final String ownerId;
  final String name;
  final List<String> athleteIds;
  final Map<String, String> privateNotes; // athleteId -> note
  final DateTime createdAt;
  final DateTime updatedAt;

  Shortlist({
    required this.id,
    required this.ownerId,
    required this.name,
    this.athleteIds = const [],
    this.privateNotes = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

/// Trial or open day opportunity.
class Opportunity {
  final String id;
  final String creatorId;
  final AccountRole creatorRole;
  final String title;
  final String sport;
  final String? position;
  final String? location;
  final DateTime? date;
  final int? minAge;
  final int? maxAge;
  final String description;
  final int capacity;
  final int applicationCount;
  final bool isClosed;
  final DateTime createdAt;

  Opportunity({
    required this.id,
    required this.creatorId,
    required this.creatorRole,
    required this.title,
    required this.sport,
    this.position,
    this.location,
    this.date,
    this.minAge,
    this.maxAge,
    this.description = '',
    this.capacity = 0,
    this.applicationCount = 0,
    this.isClosed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Application to an opportunity.
class Application {
  final String id;
  final String opportunityId;
  final String athleteId;
  final String athleteName;
  final String message;
  final bool accepted;
  final DateTime createdAt;

  Application({
    required this.id,
    required this.opportunityId,
    required this.athleteId,
    required this.athleteName,
    this.message = '',
    this.accepted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Message request (before conversation opens).
class MessageRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String message;
  final bool accepted;
  final DateTime createdAt;

  MessageRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    this.message = '',
    this.accepted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Conversation message.
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool read;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.read = false,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();
}

/// Notification event.
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? relatedId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Analytics event for profile views and shortlist events.
class AnalyticsEvent {
  final String id;
  final String athleteId;
  final String? viewerId;
  final String? viewerName;
  final String eventType; // 'view', 'shortlist'
  final DateTime timestamp;

  AnalyticsEvent({
    required this.id,
    required this.athleteId,
    this.viewerId,
    this.viewerName,
    required this.eventType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Subscription plan details.
class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final double priceUgx;
  final List<String> features;
  final bool isPopular;

  SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.priceUgx,
    required this.features,
    this.isPopular = false,
  });
}

/// Payment transaction record.
class PaymentTransaction {
  final String id;
  final String userId;
  final double amountUgx;
  final PaymentProvider provider;
  final String description;
  final bool success;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amountUgx,
    required this.provider,
    required this.description,
    this.success = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}