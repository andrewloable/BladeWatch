import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';
import 'package:bladewatch_companion/inbox_sync.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pages the way the car's CompanionInbox.list does: ids after the cursor, oldest
/// first, two at a time, with the latest id held.
class _Car implements RpcTransport {
  _Car(Iterable<int> ids, {this.ignoresCursor = false, this.latestId})
      : ids = ids.map(Int64.new).toList();

  final List<Int64> ids;
  final bool ignoresCursor;
  final int? latestId;
  final asked = <Int64>[];

  @override
  Future<T> call<T>(String service, String method, Object? request, [T Function(Object? json)? decode]) async {
    final after = (request as ListInboxRequest).afterId;
    asked.add(after);
    final page = ids.where((id) => ignoresCursor || id > after).take(2);
    return ListInboxResponse(
      entries: page.map((id) => InboxEntry(id: id, title: 'alert $id')),
      latestId: latestId != null ? Int64(latestId!) : (ids.isEmpty ? Int64.ZERO : ids.last),
      oldestId: ids.isEmpty ? Int64.ZERO : ids.first,
    ) as T;
  }
}

List<int> _ids(InboxBatch b) => b.entries.map((e) => e.id.toInt()).toList();

void main() {
  test('collects everything after the cursor across pages, and returns the new cursor', () async {
    final car = _Car([3, 4, 5, 6, 7]);
    final batch = await collectInbox(NotificationsServiceClient(car), Int64(4));

    expect(_ids(batch), [5, 6, 7]);
    expect(batch.cursor, Int64(7));
    expect(car.asked, [Int64(4), Int64(6), Int64(7)]);
  });

  test('nothing new leaves the cursor where it was', () async {
    final batch = await collectInbox(NotificationsServiceClient(_Car([1, 2])), Int64(2));
    expect(batch.entries, isEmpty);
    expect(batch.cursor, Int64(2));
  });

  test('a car whose ids went backwards was wiped: start over from zero, once', () async {
    final car = _Car([1, 2]);
    final batch = await collectInbox(NotificationsServiceClient(car), Int64(50));

    expect(_ids(batch), [1, 2]);
    expect(batch.cursor, Int64(2));
    expect(car.asked.first, Int64(50));
    expect(car.asked[1], Int64.ZERO);

    final empty = await collectInbox(NotificationsServiceClient(_Car([])), Int64(9));
    expect(empty.cursor, Int64.ZERO);
  });

  test('a car whose latestId never covers its entries cannot keep it looping either', () async {
    final car = _Car([1, 2, 3], latestId: 0);
    final batch = await collectInbox(NotificationsServiceClient(car), Int64(2));
    expect(_ids(batch), [1, 2, 3], reason: 'each once: what came before the restart is dropped');
    expect(car.asked, hasLength(4), reason: 'one restart from 2, then 0, 2, 3');
  });

  test('a car that ignores the cursor cannot keep it looping', () async {
    final car = _Car([1, 2, 3], ignoresCursor: true);
    final batch = await collectInbox(NotificationsServiceClient(car), Int64.ZERO);

    expect(_ids(batch), [1, 2]);
    expect(batch.cursor, Int64(2));
    expect(car.asked, hasLength(2));
  });
}
