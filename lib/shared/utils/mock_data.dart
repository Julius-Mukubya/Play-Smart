import 'package:play_smart/shared/types/domain_types.dart';

/// Mock data repository for local development.
/// Provides seed data for all system boundaries.
/// Replace with real API repositories when backend is connected.
class MockData {
  static final List<User> users = [
    User(
      id: 'athlete-1',
      name: 'John Muwonge',
      email: 'john@example.com',
      role: AccountRole.athlete,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.free,
      dateOfBirth: DateTime(2000, 5, 15),
    ),
    User(
      id: 'athlete-2',
      name: 'Sarah Nakato',
      email: 'sarah@example.com',
      role: AccountRole.athlete,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.premiumMonthly,
      dateOfBirth: DateTime(2002, 8, 22),
    ),
    User(
      id: 'athlete-3',
      name: 'David Okello',
      email: 'david@example.com',
      role: AccountRole.athlete,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.free,
      dateOfBirth: DateTime(2004, 3, 10),
      isUnder18: true,
    ),
    User(
      id: 'recruiter-1',
      name: 'James Kintu',
      email: 'james@scout.com',
      role: AccountRole.recruiter,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.recruiterPro,
    ),
    User(
      id: 'recruiter-2',
      name: 'Grace Achieng',
      email: 'grace@scout.com',
      role: AccountRole.recruiter,
      verificationStatus: VerificationStatus.pending,
      subscriptionTier: SubscriptionTier.free,
    ),
    User(
      id: 'club-1',
      name: 'Express FC',
      email: 'info@expressfc.ug',
      role: AccountRole.club,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.clubProfessional,
    ),
  ];

  static final List<Athlete> athletes = [
    Athlete(
      id: 'athlete-1-profile',
      userId: 'athlete-1',
      displayName: 'John Muwonge',
      photoUrl: null,
      sports: ['Football', 'Athletics'],
      positions: ['Striker', 'Left Winger'],
      age: 24,
      height: 182,
      weight: 76,
      dominantFootHand: 'Right',
      currentTeam: 'Kampala City FC',
      country: 'Uganda',
      city: 'Kampala',
      bio: 'Professional footballer with 5 years experience in the Uganda Premier League. Looking for opportunities overseas.',
      availabilityStatus: AvailabilityStatus.openToTrials,
      achievements: [
        Achievement(
          id: 'ach-1',
          title: 'Top Scorer 2025',
          description: 'Scored 15 goals in the 2025 season',
          badgeLevel: TrustBadgeLevel.selfReported,
        ),
        Achievement(
          id: 'ach-2',
          title: 'Best Young Player 2024',
          description: 'Awarded Best Young Player at Kampala City FC',
          badgeLevel: TrustBadgeLevel.coachEndorsed,
          endorsedById: 'coach-1',
          endorsedByName: 'Coach Wasswa',
        ),
      ],
      content: [
        AthleteContent(
          id: 'content-1',
          athleteId: 'athlete-1',
          type: ContentType.video,
          title: 'Match Highlights - March 2026',
          description: 'Goals and assists from the last 3 matches',
          fileUrl: null,
          thumbnailUrl: null,
          momentTag: MomentType.goal,
        ),
        AthleteContent(
          id: 'content-2',
          athleteId: 'athlete-1',
          type: ContentType.photo,
          title: 'Training Session',
          description: 'Mid-week training',
          momentTag: null,
        ),
      ],
      profileBadgeLevel: TrustBadgeLevel.coachEndorsed,
      profileCompleteness: 0.85,
    ),
    Athlete(
      id: 'athlete-2-profile',
      userId: 'athlete-2',
      displayName: 'Sarah Nakato',
      photoUrl: null,
      sports: ['Netball', 'Basketball'],
      positions: ['Goal Shooter', 'Center'],
      age: 22,
      height: 175,
      weight: 65,
      dominantFootHand: 'Left',
      currentTeam: 'NCS Netball Club',
      country: 'Uganda',
      city: 'Jinja',
      bio: 'Netball player with 4 years of competitive experience. Seeking professional opportunities.',
      availabilityStatus: AvailabilityStatus.openToTrials,
      achievements: [
        Achievement(
          id: 'ach-3',
          title: 'National League Champion 2025',
          description: 'Won the National Netball League with NCS Club',
          badgeLevel: TrustBadgeLevel.clubVerified,
          endorsedById: 'club-1',
          endorsedByName: 'Express FC',
        ),
      ],
      content: [],
      profileBadgeLevel: TrustBadgeLevel.clubVerified,
      profileCompleteness: 0.6,
    ),
    Athlete(
      id: 'athlete-3-profile',
      userId: 'athlete-3',
      displayName: 'David Okello',
      photoUrl: null,
      sports: ['Football'],
      positions: ['Goalkeeper'],
      age: 16,
      height: 185,
      weight: 72,
      dominantFootHand: 'Right',
      currentTeam: 'St. Mary\'s SS Kitende',
      country: 'Uganda',
      city: 'Entebbe',
      bio: 'School team goalkeeper, looking for academy placement.',
      availabilityStatus: AvailabilityStatus.openToTrials,
      achievements: [],
      content: [],
      profileBadgeLevel: TrustBadgeLevel.selfReported,
      profileCompleteness: 0.4,
    ),
  ];

  static final List<Shortlist> shortlists = [
    Shortlist(
      id: 'shortlist-1',
      ownerId: 'recruiter-1',
      name: 'Strikers Watchlist',
      athleteIds: ['athlete-1', 'athlete-2'],
      privateNotes: {
        'athlete-1': 'Strong finisher, contact for trial',
        'athlete-2': 'Good height, check availability',
      },
    ),
    Shortlist(
      id: 'shortlist-2',
      ownerId: 'recruiter-1',
      name: 'Goalkeepers',
      athleteIds: ['athlete-3'],
      privateNotes: {
        'athlete-3': 'Young talent, too early for pro but watch',
      },
    ),
  ];

  static final List<Opportunity> opportunities = [
    Opportunity(
      id: 'opp-1',
      creatorId: 'club-1',
      creatorRole: AccountRole.club,
      title: 'Open Trials - Express FC',
      sport: 'Football',
      position: 'All positions',
      location: 'Kampala, Uganda',
      date: DateTime.now().add(const Duration(days: 30)),
      minAge: 18,
      maxAge: 30,
      description: 'Express FC is holding open trials for the upcoming season. Bring your boots and kit.',
      capacity: 50,
      applicationCount: 12,
    ),
    Opportunity(
      id: 'opp-2',
      creatorId: 'recruiter-1',
      creatorRole: AccountRole.recruiter,
      title: 'U19 Academy Scout Day',
      sport: 'Football',
      position: 'Striker, Winger',
      location: 'Jinja, Uganda',
      date: DateTime.now().add(const Duration(days: 14)),
      minAge: 16,
      maxAge: 19,
      description: 'Looking for young attacking talent for academy placement.',
      capacity: 20,
      applicationCount: 20,
      isClosed: true,
    ),
  ];

  static final List<Application> applications = [
    Application(
      id: 'app-1',
      opportunityId: 'opp-1',
      athleteId: 'athlete-1',
      athleteName: 'John Muwonge',
      message: 'I am interested in trying out for Express FC.',
      accepted: true,
    ),
    Application(
      id: 'app-2',
      opportunityId: 'opp-1',
      athleteId: 'athlete-2',
      athleteName: 'Sarah Nakato',
      message: 'Would love to showcase my skills.',
      accepted: false,
    ),
  ];

  static final List<MessageRequest> messageRequests = [
    MessageRequest(
      id: 'mr-1',
      fromUserId: 'recruiter-1',
      fromUserName: 'James Kintu',
      toUserId: 'athlete-1',
      message: 'Hi John, I saw your profile and I\'m interested in scouting you. Would you like to connect?',
      accepted: true,
    ),
    MessageRequest(
      id: 'mr-2',
      fromUserId: 'recruiter-1',
      fromUserName: 'James Kintu',
      toUserId: 'athlete-2',
      message: 'Hello Sarah, great profile! Would you be open to discussing a trial opportunity?',
      accepted: false,
    ),
  ];

  static final List<Message> messages = [
    Message(
      id: 'msg-1',
      conversationId: 'mr-1',
      senderId: 'recruiter-1',
      text: 'Hi John, I saw your profile and I\'m interested in scouting you.',
      sentAt: DateTime.now().subtract(const Duration(hours: 24)),
    ),
    Message(
      id: 'msg-2',
      conversationId: 'mr-1',
      senderId: 'athlete-1',
      text: 'Thanks James! I\'d be happy to connect. What do you need from me?',
      sentAt: DateTime.now().subtract(const Duration(hours: 23)),
    ),
    Message(
      id: 'msg-3',
      conversationId: 'mr-1',
      senderId: 'recruiter-1',
      text: 'Can you send me your latest match footage? I\'d like to see your recent form.',
      sentAt: DateTime.now().subtract(const Duration(hours: 22)),
    ),
  ];

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'notif-1',
      userId: 'athlete-1',
      type: NotificationType.profileView,
      title: 'Profile Viewed',
      body: 'A recruiter from Express FC viewed your profile.',
      read: false,
    ),
    AppNotification(
      id: 'notif-2',
      userId: 'athlete-1',
      type: NotificationType.shortlisted,
      title: 'Shortlisted',
      body: 'You have been added to James Kintu\'s shortlist.',
      read: false,
    ),
    AppNotification(
      id: 'notif-3',
      userId: 'athlete-2',
      type: NotificationType.messageRequest,
      title: 'New Message Request',
      body: 'James Kintu wants to connect with you.',
      read: true,
    ),
  ];

  static final List<AnalyticsEvent> analyticsEvents = [
    AnalyticsEvent(
      id: 'ae-1',
      athleteId: 'athlete-1',
      viewerId: 'recruiter-1',
      viewerName: 'James Kintu',
      eventType: 'view',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AnalyticsEvent(
      id: 'ae-2',
      athleteId: 'athlete-1',
      viewerId: null,
      viewerName: null,
      eventType: 'view',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AnalyticsEvent(
      id: 'ae-3',
      athleteId: 'athlete-1',
      viewerId: 'recruiter-1',
      viewerName: 'James Kintu',
      eventType: 'shortlist',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  static final List<PaymentTransaction> transactions = [
    PaymentTransaction(
      id: 'tx-1',
      userId: 'athlete-2',
      amountUgx: 20000,
      provider: PaymentProvider.mtnMobileMoney,
      description: 'Premium Monthly Subscription',
      success: true,
    ),
    PaymentTransaction(
      id: 'tx-2',
      userId: 'recruiter-1',
      amountUgx: 75000,
      provider: PaymentProvider.visaMastercard,
      description: 'Pro Plan Monthly Subscription',
      success: true,
    ),
  ];

  /// Subscription plans with pricing.
  static final List<SubscriptionPlan> subscriptionPlans = [
    SubscriptionPlan(
      tier: SubscriptionTier.free,
      name: 'Free',
      priceUgx: 0,
      features: [
        'Basic profile',
        'Browse public profiles',
        'Limited search',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.premiumMonthly,
      name: 'Premium Monthly',
      priceUgx: 20000,
      features: [
        'Full analytics with viewer identity',
        'Priority in search results',
        'Post Boost access',
        'See who viewed your profile',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.recruiterPro,
      name: 'Recruiter Pro',
      priceUgx: 75000,
      features: [
        'Unlimited shortlists',
        'Export profiles to PDF',
        'Full analytics',
        'Send unlimited expressions of interest',
        'Post trial opportunities',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.clubProfessional,
      name: 'Club Professional',
      priceUgx: 150000,
      features: [
        'All Recruiter Pro features',
        'Roster confirmation',
        'Assign scouts',
        'Broadcast announcements',
        'Manage incoming applications',
      ],
    ),
  ];

  /// Find user by ID.
  static User? getUserById(String id) {
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find athlete profile by user ID.
  static Athlete? getAthleteByUserId(String userId) {
    try {
      return athletes.firstWhere((a) => a.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Find athlete by profile ID.
  static Athlete? getAthleteById(String id) {
    try {
      return athletes.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filter athletes by criteria.
  static List<Athlete> searchAthletes({
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
  }) {
    var results = athletes.toList();

    if (sport != null && sport.isNotEmpty) {
      results = results.where((a) =>
          a.sports.any((s) => s.toLowerCase().contains(sport.toLowerCase()))).toList();
    }
    if (position != null && position.isNotEmpty) {
      results = results.where((a) =>
          a.positions.any((p) => p.toLowerCase().contains(position.toLowerCase()))).toList();
    }
    if (minAge != null) {
      results = results.where((a) => (a.age ?? 0) >= minAge).toList();
    }
    if (maxAge != null) {
      results = results.where((a) => (a.age ?? 999) <= maxAge).toList();
    }
    if (location != null && location.isNotEmpty) {
      results = results.where((a) =>
          (a.city?.toLowerCase().contains(location.toLowerCase()) ?? false) ||
          (a.country?.toLowerCase().contains(location.toLowerCase()) ?? false)).toList();
    }
    if (availability != null) {
      results = results.where((a) => a.availabilityStatus == availability).toList();
    }
    if (minBadge != null) {
      results = results.where((a) =>
          a.profileBadgeLevel.index >= minBadge.index).toList();
    }

    return results;
  }
}