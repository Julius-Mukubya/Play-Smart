import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Notification repository — read-only access to `public.notifications` plus
/// marking rows read. There is NO insert path here: notification rows are
/// created exclusively by database triggers on the events they represent
/// (shortlisted, message request, etc.) — the client can never create one
/// directly (RLS has no insert grant for this table). See
/// `lib/supabase-integration.md` section 5.
class NotificationRepository {
  static const _table = 'notifications';

  Future<List<AppNotification>> getNotifications(String userId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AppNotification.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final rows =
        await supabase.from(_table).select('id').eq('user_id', userId).eq('read', false);
    return (rows as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await supabase.from(_table).update({'read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await supabase.from(_table).update({'read': true}).eq('user_id', userId).eq('read', false);
  }
}
