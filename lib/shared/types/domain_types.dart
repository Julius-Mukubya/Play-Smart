// Shared domain types used across all system boundaries.
//
// Each persisted model has a `fromJson` factory that maps a Supabase/Postgrest
// row (snake_case columns) onto this Dart model. There is no generic `toJson`
// — insert/update payloads are built inline in each repository because the
// writable subset of columns differs per operation (e.g. `profile_badge_level`
// is never client-writable). See `context/supabase-backend.md` and
// `lib/supabase-integration.md` for the schema these map onto.

/// Account roles in the platform.
/// `guest` is client-only (unauthenticated) and never appears in the database.
/// `admin` has no self-service sign-up path but can appear when parsing rows.
enum AccountRole {
  athlete,
  recruiter,
  club,
  admin,
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

extension TrustBadgeLevelDb on TrustBadgeLevel {
  String toDb() => switch (this) {
        TrustBadgeLevel.selfReported => 'self_reported',
        TrustBadgeLevel.coachEndorsed => 'coach_endorsed',
        TrustBadgeLevel.clubVerified => 'club_verified',
      };

  static TrustBadgeLevel fromDb(String value) => switch (value) {
        'self_reported' => TrustBadgeLevel.selfReported,
        'coach_endorsed' => TrustBadgeLevel.coachEndorsed,
        'club_verified' => TrustBadgeLevel.clubVerified,
        _ => throw ArgumentError('Unknown trust_badge_level: $value'),
      };
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

extension SubscriptionTierDb on SubscriptionTier {
  String toDb() => switch (this) {
        SubscriptionTier.free => 'free',
        SubscriptionTier.premiumMonthly => 'premium_monthly',
        SubscriptionTier.premiumAnnual => 'premium_annual',
        SubscriptionTier.recruiterBasic => 'recruiter_basic',
        SubscriptionTier.recruiterPro => 'recruiter_pro',
        SubscriptionTier.clubGrassroots => 'club_grassroots',
        SubscriptionTier.clubProfessional => 'club_professional',
        SubscriptionTier.clubEnterprise => 'club_enterprise',
      };

  static SubscriptionTier fromDb(String value) => switch (value) {
        'free' => SubscriptionTier.free,
        'premium_monthly' => SubscriptionTier.premiumMonthly,
        'premium_annual' => SubscriptionTier.premiumAnnual,
        'recruiter_basic' => SubscriptionTier.recruiterBasic,
        'recruiter_pro' => SubscriptionTier.recruiterPro,
        'club_grassroots' => SubscriptionTier.clubGrassroots,
        'club_professional' => SubscriptionTier.clubProfessional,
        'club_enterprise' => SubscriptionTier.clubEnterprise,
        _ => throw ArgumentError('Unknown subscription_tier: $value'),
      };
}

/// Availability status for athletes.
enum AvailabilityStatus {
  openToTrials,
  currentlyContracted,
  notAvailable,
}

extension AvailabilityStatusDb on AvailabilityStatus {
  String toDb() => switch (this) {
        AvailabilityStatus.openToTrials => 'open_to_trials',
        AvailabilityStatus.currentlyContracted => 'currently_contracted',
        AvailabilityStatus.notAvailable => 'not_available',
      };

  static AvailabilityStatus fromDb(String value) => switch (value) {
        'open_to_trials' => AvailabilityStatus.openToTrials,
        'currently_contracted' => AvailabilityStatus.currentlyContracted,
        'not_available' => AvailabilityStatus.notAvailable,
        _ => throw ArgumentError('Unknown availability_status: $value'),
      };
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

extension NotificationTypeDb on NotificationType {
  String toDb() => switch (this) {
        NotificationType.profileView => 'profile_view',
        NotificationType.shortlisted => 'shortlisted',
        NotificationType.trialMatch => 'trial_match',
        NotificationType.endorsementRequest => 'endorsement_request',
        NotificationType.messageRequest => 'message_request',
      };

  static NotificationType fromDb(String value) => switch (value) {
        'profile_view' => NotificationType.profileView,
        'shortlisted' => NotificationType.shortlisted,
        'trial_match' => NotificationType.trialMatch,
        'endorsement_request' => NotificationType.endorsementRequest,
        'message_request' => NotificationType.messageRequest,
        _ => throw ArgumentError('Unknown notification_type: $value'),
      };
}

/// Payment provider options.
enum PaymentProvider {
  mtnMobileMoney,
  airtelMoney,
  visaMastercard,
  stripe,
}

extension PaymentProviderDb on PaymentProvider {
  String toDb() => switch (this) {
        PaymentProvider.mtnMobileMoney => 'mtn_mobile_money',
        PaymentProvider.airtelMoney => 'airtel_money',
        PaymentProvider.visaMastercard => 'visa_mastercard',
        PaymentProvider.stripe => 'stripe',
      };

  static PaymentProvider fromDb(String value) => switch (value) {
        'mtn_mobile_money' => PaymentProvider.mtnMobileMoney,
        'airtel_money' => PaymentProvider.airtelMoney,
        'visa_mastercard' => PaymentProvider.visaMastercard,
        'stripe' => PaymentProvider.stripe,
        _ => throw ArgumentError('Unknown payment_provider: $value'),
      };
}

/// Core User model — mirrors `public.users` (1:1 with `auth.users`).
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

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: AccountRole.values.byName(json['role'] as String),
        verificationStatus:
            VerificationStatus.values.byName(json['verification_status'] as String),
        subscriptionTier: SubscriptionTierDb.fromDb(json['subscription_tier'] as String),
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'] as String)
            : null,
        isUnder18: json['is_under_18'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'verification_status': verificationStatus.name,
        'subscription_tier': subscriptionTier.toDb(),
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'is_under_18': isUnder18,
        'created_at': createdAt.toIso8601String(),
      };
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

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        badgeLevel: TrustBadgeLevelDb.fromDb(json['badge_level'] as String),
        endorsedById: json['endorsed_by_id'] as String?,
        endorsedByName: json['endorsed_by_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
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
  final int likeCount;
  final int commentCount;
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
    this.likeCount = 0,
    this.commentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AthleteContent.fromJson(Map<String, dynamic> json) => AthleteContent(
        id: json['id'] as String,
        athleteId: json['athlete_id'] as String,
        type: ContentType.values.byName(json['type'] as String),
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        fileUrl: json['file_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        momentTag: json['moment_tag'] != null
            ? MomentType.values.byName(json['moment_tag'] as String)
            : null,
        likeCount: json['like_count'] as int? ?? 0,
        commentCount: json['comment_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
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
  // Geocoded server-side from city/country (Database Webhook -> Edge Function).
  // Never write these from the client — they're read-only display fields.
  final double? lat;
  final double? lng;
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
    this.lat,
    this.lng,
    this.availabilityStatus = AvailabilityStatus.openToTrials,
    this.achievements = const [],
    this.content = const [],
    this.profileBadgeLevel = TrustBadgeLevel.selfReported,
    this.profileCompleteness = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Parses an `athletes` row. `achievements` / `athlete_content` are only
  /// populated if the query embedded those relations
  /// (e.g. `.select('*, achievements(*), athlete_content(*)')`).
  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        photoUrl: json['photo_url'] as String?,
        sports: List<String>.from(json['sports'] as List? ?? const []),
        positions: List<String>.from(json['positions'] as List? ?? const []),
        age: json['age'] as int?,
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        dominantFootHand: json['dominant_foot_hand'] as String?,
        currentTeam: json['current_team'] as String?,
        country: json['country'] as String?,
        city: json['city'] as String?,
        bio: json['bio'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        availabilityStatus: AvailabilityStatusDb.fromDb(json['availability_status'] as String),
        achievements: (json['achievements'] as List?)
                ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        content: (json['athlete_content'] as List?)
                ?.map((e) => AthleteContent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        profileBadgeLevel: TrustBadgeLevelDb.fromDb(json['profile_badge_level'] as String),
        profileCompleteness: (json['profile_completeness'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Athlete copyWith({String? photoUrl}) => Athlete(
        id: id,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        sports: sports,
        positions: positions,
        age: age,
        height: height,
        weight: weight,
        dominantFootHand: dominantFootHand,
        currentTeam: currentTeam,
        country: country,
        city: city,
        bio: bio,
        lat: lat,
        lng: lng,
        availabilityStatus: availabilityStatus,
        achievements: achievements,
        content: content,
        profileBadgeLevel: profileBadgeLevel,
        profileCompleteness: profileCompleteness,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
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

  /// Parses a `shortlists` row. `athleteIds`/`privateNotes` are read from the
  /// embedded `shortlist_athletes` join
  /// (`.select('*, shortlist_athletes(athlete_id, private_note)')`).
  factory Shortlist.fromJson(Map<String, dynamic> json) {
    final rows = (json['shortlist_athletes'] as List?) ?? const [];
    final athleteIds = <String>[];
    final notes = <String, String>{};
    for (final row in rows) {
      final r = row as Map<String, dynamic>;
      final athleteId = r['athlete_id'] as String;
      athleteIds.add(athleteId);
      final note = r['private_note'] as String?;
      if (note != null && note.isNotEmpty) notes[athleteId] = note;
    }
    return Shortlist(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      athleteIds: athleteIds,
      privateNotes: notes,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
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

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
        id: json['id'] as String,
        creatorId: json['creator_id'] as String,
        creatorRole: AccountRole.values.byName(json['creator_role'] as String),
        title: json['title'] as String,
        sport: json['sport'] as String,
        position: json['position'] as String?,
        location: json['location'] as String?,
        date: json['event_date'] != null ? DateTime.parse(json['event_date'] as String) : null,
        minAge: json['min_age'] as int?,
        maxAge: json['max_age'] as int?,
        description: json['description'] as String? ?? '',
        capacity: json['capacity'] as int? ?? 0,
        applicationCount: json['application_count'] as int? ?? 0,
        isClosed: json['is_closed'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Application to an opportunity.
class Application {
  final String id;
  final String opportunityId;
  final String athleteId;
  final String athleteName;
  final String message;
  /// `'pending' | 'accepted' | 'rejected'` — `public.applications.status`.
  final String status;
  final DateTime createdAt;

  Application({
    required this.id,
    required this.opportunityId,
    required this.athleteId,
    required this.athleteName,
    this.message = '',
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convenience accessor — mirrors the database's generated `accepted` column.
  bool get accepted => status == 'accepted';
  bool get rejected => status == 'rejected';

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json['id'] as String,
        opportunityId: json['opportunity_id'] as String,
        athleteId: json['athlete_id'] as String,
        athleteName: json['athlete_name'] as String,
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Message request (before conversation opens).
class MessageRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String message;
  final bool accepted;
  final bool requiresMonitoring;
  final DateTime createdAt;

  MessageRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    this.message = '',
    this.accepted = false,
    this.requiresMonitoring = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MessageRequest.fromJson(Map<String, dynamic> json) => MessageRequest(
        id: json['id'] as String,
        fromUserId: json['from_user_id'] as String,
        fromUserName: json['from_user_name'] as String,
        toUserId: json['to_user_id'] as String,
        message: json['message'] as String? ?? '',
        accepted: json['accepted'] as bool? ?? false,
        requiresMonitoring: json['requires_monitoring'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
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

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        text: json['text'] as String,
        read: json['read'] as bool? ?? false,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
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

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: NotificationTypeDb.fromDb(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        relatedId: json['related_id'] as String?,
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
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

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
        id: json['id'] as String,
        athleteId: json['athlete_id'] as String,
        viewerId: json['viewer_id'] as String?,
        viewerName: json['viewer_name'] as String?,
        eventType: json['event_type'] as String,
        timestamp: DateTime.parse(json['occurred_at'] as String),
      );
}

/// Subscription plan details (reference/catalog — `public.subscription_plans`).
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

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        tier: SubscriptionTierDb.fromDb(json['tier'] as String),
        name: json['name'] as String,
        priceUgx: (json['price_ugx'] as num).toDouble(),
        features: List<String>.from(json['features'] as List? ?? const []),
        isPopular: json['is_popular'] as bool? ?? false,
      );
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

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => PaymentTransaction(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amountUgx: (json['amount_ugx'] as num).toDouble(),
        provider: PaymentProviderDb.fromDb(json['provider'] as String),
        description: json['description'] as String,
        success: (json['status'] as String?) == 'success',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
