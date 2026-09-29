import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/screens/startup/startup_controller.dart';
import 'package:bladewatch_ui/screens/startup/startup_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

class _FakeClock {
  DateTime now;
  _FakeClock(this.now);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

void main() {
  late FakePlatformChannel fakeChannel;
  late _FakeClock clock;

  DaemonChannel channel() => DaemonChannel(fakeChannel);

  void stubStatuses({bool camera = false, bool sentry = false, bool accSentry = false}) {
    fakeChannel.stub('daemon', 'processStatus', {
      'status': 'ok',
      'daemons': {
        'CAMERA_DAEMON': camera,
        'SENTRY_DAEMON': sentry,
        'ACC_SENTRY_DAEMON': accSentry,
        'PEAR_PEER': false,
      },
    });
  }

  setUp(() {
    fakeChannel = FakePlatformChannel();
    clock = _FakeClock(DateTime(2026, 1, 1, 12, 0, 0));
    stubStatuses();
  });

  StartupController buildController({Future<bool> Function()? healthCheck}) {
    return StartupController(
      daemonChannel: channel(),
      clock: clock.call,
      continueAnywayDelay: const Duration(seconds: 120),
      readyToNavigateDelay: const Duration(milliseconds: 1500),
      healthCheck: healthCheck ?? () async => true,
    );
  }

  group('initial state', () {
    test('all 3 core daemon rows start waiting with zero elapsed', () {
      final c = buildController();
      for (final d in CoreDaemon.values) {
        expect(c.rows[d]!.status, DaemonRowStatus.waiting);
        expect(c.rows[d]!.elapsed, Duration.zero);
      }
    });

    test('phase starts preparing, continue button hidden, not navigating', () {
      final c = buildController();
      expect(c.phase, StartupPhase.preparing);
      expect(c.showContinueButton, isFalse);
      expect(c.navigateToDashboard, isFalse);
    });
  });

  group('tick() with no daemons running', () {
    test('stays in preparing phase', () async {
      final c = buildController();
      await c.tick();
      expect(c.phase, StartupPhase.preparing);
      expect(c.rows[CoreDaemon.camera]!.status, DaemonRowStatus.waiting);
    });

    test('elapsed keeps ticking up for waiting rows', () async {
      final c = buildController();
      await c.tick();
      clock.advance(const Duration(seconds: 5));
      await c.tick();
      expect(c.rows[CoreDaemon.camera]!.elapsed, const Duration(seconds: 5));
    });
  });

  group('tick() with partial daemons running', () {
    test('phase becomes starting when 1 of 3 core daemons is running', () async {
      stubStatuses(camera: true);
      final c = buildController();
      await c.tick();
      expect(c.phase, StartupPhase.starting);
      expect(c.rows[CoreDaemon.camera]!.status, DaemonRowStatus.ready);
      expect(c.rows[CoreDaemon.sentry]!.status, DaemonRowStatus.waiting);
    });

    test('phase becomes starting when 2 of 3 core daemons are running', () async {
      stubStatuses(camera: true, sentry: true);
      final c = buildController();
      await c.tick();
      expect(c.phase, StartupPhase.starting);
    });

    test('a ready row freezes its elapsed time instead of continuing to tick', () async {
      stubStatuses();
      final c = buildController();
      await c.tick(); // camera still waiting at t=0
      clock.advance(const Duration(seconds: 3));
      stubStatuses(camera: true);
      await c.tick(); // camera becomes ready at t=3s
      expect(c.rows[CoreDaemon.camera]!.elapsed, const Duration(seconds: 3));

      clock.advance(const Duration(seconds: 10));
      await c.tick(); // camera stays ready; elapsed must not advance further
      expect(c.rows[CoreDaemon.camera]!.elapsed, const Duration(seconds: 3));
    });
  });

  group('tick() with all core daemons running', () {
    test('enters verifying phase and runs the health check', () async {
      stubStatuses(camera: true, sentry: true, accSentry: true);
      var healthCheckCalls = 0;
      final c = buildController(healthCheck: () async {
        healthCheckCalls++;
        return false; // stay in verifying for this assertion
      });

      await c.tick();

      expect(c.phase, StartupPhase.verifying);
      expect(healthCheckCalls, 1);
      expect(c.navigateToDashboard, isFalse);
    });

    test('a failed health check retries on the next tick rather than getting stuck', () async {
      stubStatuses(camera: true, sentry: true, accSentry: true);
      var healthCheckCalls = 0;
      final c = buildController(healthCheck: () async {
        healthCheckCalls++;
        return healthCheckCalls >= 2; // fails once, then succeeds
      });

      await c.tick();
      expect(c.phase, StartupPhase.verifying);
      await c.tick();
      expect(healthCheckCalls, 2);
    });

    test('a passing health check moves to ready but waits readyToNavigateDelay before navigating', () async {
      stubStatuses(camera: true, sentry: true, accSentry: true);
      final c = buildController(healthCheck: () async => true);

      await c.tick();
      expect(c.phase, StartupPhase.ready);
      expect(c.navigateToDashboard, isFalse, reason: 'must not navigate immediately');

      clock.advance(const Duration(milliseconds: 1000));
      await c.tick();
      expect(c.navigateToDashboard, isFalse, reason: 'still under the 1500ms delay');

      clock.advance(const Duration(milliseconds: 600));
      await c.tick();
      expect(c.navigateToDashboard, isTrue);
    });
  });

  group('continueAnyway()', () {
    test('navigates immediately regardless of daemon state', () {
      final c = buildController();
      c.continueAnyway();
      expect(c.navigateToDashboard, isTrue);
    });

    test('is a no-op once already navigating', () async {
      final c = buildController();
      var notifications = 0;
      c.continueAnyway();
      c.addListener(() => notifications++);
      c.continueAnyway();
      expect(notifications, 0);
    });
  });

  group('showContinueButton', () {
    test('stays hidden before continueAnywayDelay has elapsed', () async {
      final c = buildController();
      clock.advance(const Duration(seconds: 119));
      await c.tick();
      expect(c.showContinueButton, isFalse);
    });

    test('becomes visible once continueAnywayDelay has elapsed', () async {
      final c = buildController();
      clock.advance(const Duration(seconds: 120));
      await c.tick();
      expect(c.showContinueButton, isTrue);
    });
  });

  group('channel errors', () {
    // BladeWatch-t7js: these used to assert that the raw exception text was captured into
    // channelErrorMessage, which the screen then printed across its header in red. On the
    // head unit that produced "PlatformChannelError(daemonNotUp): ... ECONNREFUSED" as the
    // headline under "Getting your dashcam ready". daemonNotUp is the EXPECTED answer here
    // for the first ~45s after boot, so what these now pin is that the failure is absorbed
    // and the screen keeps telling the truth through the rows.

    test('a thrown PlatformChannelError does not escape tick() and leaves rows waiting', () async {
      fakeChannel.stubError(
        'daemon',
        'processStatus',
        const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'daemon not up'),
      );
      final c = buildController();

      await c.tick();

      expect(c.phase, StartupPhase.preparing);
      for (final d in CoreDaemon.values) {
        expect(c.rows[d]!.status, DaemonRowStatus.waiting);
      }
    });

    test('a timeout is absorbed the same way', () async {
      fakeChannel.stubTimeout('daemon', 'processStatus');
      final c = buildController();

      await c.tick();

      expect(c.phase, StartupPhase.preparing);
      for (final d in CoreDaemon.values) {
        expect(c.rows[d]!.status, DaemonRowStatus.waiting);
      }
    });

    test('a failing channel does not poison later ticks once it recovers', () async {
      fakeChannel.stubError(
        'daemon',
        'processStatus',
        const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'),
      );
      final c = buildController();
      await c.tick();
      expect(c.rows[CoreDaemon.values.first]!.status, DaemonRowStatus.waiting);

      stubStatuses(camera: true, sentry: true, accSentry: true);
      await c.tick();

      for (final d in CoreDaemon.values) {
        expect(c.rows[d]!.status, DaemonRowStatus.ready);
      }
    });
  });

  group('the navigated guard', () {
    test('tick() becomes a no-op once navigateToDashboard is already true', () async {
      final c = buildController();
      c.continueAnyway();
      final phaseBeforeExtraTick = c.phase;

      stubStatuses(camera: true, sentry: true, accSentry: true);
      await c.tick();

      expect(c.phase, phaseBeforeExtraTick, reason: 'a tick after navigating must not change state');
    });
  });

  test('notifyListeners fires on every tick', () async {
    final c = buildController();
    var notifications = 0;
    c.addListener(() => notifications++);

    await c.tick();

    expect(notifications, 1);
  });
}
