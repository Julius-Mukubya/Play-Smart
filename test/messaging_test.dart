import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/messaging/repositories/messaging_repository.dart';
import 'package:play_smart/messaging/services/messaging_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  group('MessagingRepository', () {
    late MessagingRepository repository;

    setUp(() {
      repository = MessagingRepository();
    });

    test('getRequestsForUser returns requests for user', () {
      final requests = repository.getRequestsForUser('athlete-1');
      expect(requests.isNotEmpty, true);
      expect(requests.every((r) => r.toUserId == 'athlete-1'), true);
    });

    test('getPendingRequests returns unaccepted requests', () {
      final pending = repository.getPendingRequests('athlete-1');
      expect(pending.every((r) => !r.accepted), true);
    });

    test('getConversations returns accepted requests', () {
      final conversations = repository.getConversations('athlete-1');
      expect(conversations.every((r) => r.accepted), true);
    });

    test('sendRequest adds a new message request', () async {
      final request = MessageRequest(
        id: 'new-mr',
        fromUserId: 'recruiter-1',
        fromUserName: 'James Kintu',
        toUserId: 'athlete-3',
        message: 'Interested in your profile.',
      );

      final created = await repository.sendRequest(request);
      expect(created.id, 'new-mr');
      expect(created.accepted, false);

      final requests = repository.getRequestsForUser('athlete-3');
      expect(requests.any((r) => r.id == 'new-mr'), true);
    });

    test('acceptRequest opens a conversation', () async {
      final accepted = await repository.acceptRequest('mr-2');
      expect(accepted.accepted, true);
    });

    test('acceptRequest throws for unknown request', () async {
      expect(
        () => repository.acceptRequest('unknown'),
        throwsA(isA<MessagingException>()),
      );
    });

    test('declineRequest removes the request', () async {
      await repository.declineRequest('mr-2');
      final requests = repository.getRequestsForUser('athlete-2');
      expect(requests.any((r) => r.id == 'mr-2'), false);
    });

    test('getConversationMessages returns messages for conversation', () {
      final messages = repository.getConversationMessages('mr-1');
      expect(messages.isNotEmpty, true);
      expect(messages.every((m) => m.conversationId == 'mr-1'), true);
    });

    test('sendMessage adds a message to conversation', () async {
      final message = Message(
        id: 'new-msg',
        conversationId: 'mr-1',
        senderId: 'athlete-1',
        text: 'Hello again!',
      );

      final created = await repository.sendMessage(message);
      expect(created.id, 'new-msg');

      final messages = repository.getConversationMessages('mr-1');
      expect(messages.any((m) => m.id == 'new-msg'), true);
    });

    test('markAsRead updates read status for messages from other users', () async {
      await repository.markAsRead('mr-1', 'athlete-1');
      final messages = repository.getConversationMessages('mr-1');
      // Messages from recruiter-1 should be marked read
      // Messages from athlete-1 (the reader) remain unchanged
      for (final msg in messages) {
        if (msg.senderId != 'athlete-1') {
          expect(msg.read, true, reason: 'Message from ${msg.senderId} should be read');
        }
      }
    });
  });

  group('MessagingService', () {
    late MessagingService service;

    setUp(() {
      service = MessagingService();
    });

    test('canSendRequest returns true for verified recruiter', () {
      final sender = User(
        id: 'recruiter-1',
        name: 'James Kintu',
        email: 'james@scout.com',
        role: AccountRole.recruiter,
        verificationStatus: VerificationStatus.approved,
      );
      final recipient = User(
        id: 'athlete-1',
        name: 'John Muwonge',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );

      expect(service.canSendRequest(sender: sender, recipient: recipient), true);
    });

    test('canSendRequest returns false for athlete sender', () {
      final sender = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );
      final recipient = User(
        id: 'athlete-2',
        name: 'Sarah',
        email: 'sarah@example.com',
        role: AccountRole.athlete,
      );

      expect(service.canSendRequest(sender: sender, recipient: recipient), false);
    });

    test('canSendRequest returns false for unverified recruiter', () {
      final sender = User(
        id: 'recruiter-2',
        name: 'Grace',
        email: 'grace@scout.com',
        role: AccountRole.recruiter,
        verificationStatus: VerificationStatus.pending,
      );
      final recipient = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );

      expect(service.canSendRequest(sender: sender, recipient: recipient), false);
    });

    test('canReceiveRequest allows verified recruiter for under-18 athlete', () {
      final recipient = User(
        id: 'athlete-3',
        name: 'David Okello',
        email: 'david@example.com',
        role: AccountRole.athlete,
        isUnder18: true,
      );
      final sender = User(
        id: 'recruiter-1',
        name: 'James',
        email: 'james@scout.com',
        role: AccountRole.recruiter,
        verificationStatus: VerificationStatus.approved,
      );

      expect(service.canReceiveRequest(recipient: recipient, sender: sender), true);
    });

    test('canReceiveRequest blocks non-recruiter for under-18 athlete', () {
      final recipient = User(
        id: 'athlete-3',
        name: 'David',
        email: 'david@example.com',
        role: AccountRole.athlete,
        isUnder18: true,
      );
      final sender = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );

      expect(service.canReceiveRequest(recipient: recipient, sender: sender), false);
    });

    test('getSendRequestError returns null for valid request', () {
      final sender = User(
        id: 'recruiter-1',
        name: 'James',
        email: 'james@scout.com',
        role: AccountRole.recruiter,
        verificationStatus: VerificationStatus.approved,
      );
      final recipient = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );

      expect(service.getSendRequestError(sender, recipient), isNull);
    });

    test('getSendRequestError returns error for guest', () {
      final sender = User(
        id: 'guest',
        name: 'Guest',
        email: 'guest@example.com',
        role: AccountRole.guest,
      );
      final recipient = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );

      expect(service.getSendRequestError(sender, recipient), isNotNull);
    });

    test('canAcceptRequest returns true for athlete', () {
      final athlete = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
      );
      expect(service.canAcceptRequest(athlete), true);
    });

    test('requiresMonitoring returns true for under-18 athlete', () {
      final athlete = User(
        id: 'athlete-3',
        name: 'David',
        email: 'david@example.com',
        role: AccountRole.athlete,
        isUnder18: true,
      );
      expect(service.requiresMonitoring(athlete), true);
    });

    test('requiresMonitoring returns false for 18+ athlete', () {
      final athlete = User(
        id: 'athlete-1',
        name: 'John',
        email: 'john@example.com',
        role: AccountRole.athlete,
        isUnder18: false,
      );
      expect(service.requiresMonitoring(athlete), false);
    });
  });
}