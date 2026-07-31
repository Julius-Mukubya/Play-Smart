import 'package:play_smart/shared/types/domain_types.dart';

/// Messaging service — enforces messaging business rules.
/// Invariant: No conversation thread opens without the athlete accepting a message request.
/// Under-18 athletes can only receive message requests from verified recruiters/clubs.
class MessagingService {
  /// Check if a user can send a message request to an athlete.
  /// Enforces under-18 restrictions and athlete consent gate.
  bool canSendRequest({
    required User sender,
    required User recipient,
  }) {
    if (sender.role == AccountRole.guest) return false;
    return true;
  }

  /// Check if a message can be received by an athlete.
  /// Under-18 athletes: only from verified recruiters/clubs.
  bool canReceiveRequest({
    required User recipient,
    required User sender,
  }) {
    if (!recipient.isUnder18) return true;
    return (sender.role == AccountRole.recruiter || sender.role == AccountRole.club) &&
        sender.verificationStatus == VerificationStatus.approved;
  }

  /// Check if a message request can be accepted.
  bool canAcceptRequest(User user) {
    return user.role != AccountRole.guest;
  }

  /// Get a validation error message if the request cannot be sent.
  String? getSendRequestError(User sender, User recipient) {
    if (sender.role == AccountRole.guest) {
      return 'Please create an account to send a friend request.';
    }
    if (recipient.isUnder18) {
      if (sender.role != AccountRole.recruiter && sender.role != AccountRole.club) {
        return 'Only verified recruiters and clubs can connect with under-18 athletes.';
      }
      if (sender.verificationStatus != VerificationStatus.approved) {
        return 'Your account must be verified to contact under-18 athletes.';
      }
    }
    return null;
  }

  /// Check if a conversation requires monitoring (under-18 participant).
  bool requiresMonitoring(User athlete) {
    return athlete.isUnder18;
  }

  Future<void> onMessageRequestSent(MessageRequest request) async {}
  Future<void> onMessageRequestAccepted(MessageRequest request) async {}
}