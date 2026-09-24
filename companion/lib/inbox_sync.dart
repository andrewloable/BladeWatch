// Store and forward, the companion's half (BladeWatch-rdtj.14). The car keeps the
// alerts it raised; on every connection -- LAN or Pear -- the companion collects
// the ones after the last id it saw. There is no push service: an alert reaches
// the owner when the companion next connects, which is the trade the owner chose.
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';
import 'package:fixnum/fixnum.dart';

class InboxBatch {
  /// Oldest first, all newer than the cursor passed in.
  final List<InboxEntry> entries;

  /// Pass this back on the next connection. Persist it per car.
  final Int64 cursor;

  const InboxBatch(this.entries, this.cursor);
}

/// Everything after [after], paged until caught up.
///
/// Ids on the car only ever increase, so a latest id BELOW [after] means the
/// car's inbox was wiped (its file lost, the head unit reset): the cursor then
/// points at ids that will not exist for a long time, and every new alert would
/// be skipped. Start over from zero instead.
Future<InboxBatch> collectInbox(NotificationsServiceClient client, Int64 after) async {
  final entries = <InboxEntry>[];
  var cursor = after;
  var restarted = false;
  while (true) {
    final page = await client.listInbox(ListInboxRequest(afterId: cursor));
    // Once per collection, and only from a real cursor: a car whose latestId never covers the
    // entries it sends would otherwise send this round the loop forever.
    if (!restarted && page.latestId < cursor && cursor > Int64.ZERO) {
      restarted = true;
      cursor = Int64.ZERO;
      entries.clear(); // collected from the inbox that was wiped: not the car's any more
      continue;
    }
    // No progress means a car that ignored the cursor: stop rather than loop forever.
    if (page.entries.isEmpty || page.entries.last.id <= cursor) return InboxBatch(entries, cursor);
    entries.addAll(page.entries);
    cursor = page.entries.last.id;
  }
}
