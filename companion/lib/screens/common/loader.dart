import 'dart:async';

import 'package:flutter/material.dart';

import '../../car/car_page.dart';

/// One fetch from the car and its three states. Most companion screens are "load something,
/// show it, act on it"; this is the loading and failure half of each, written once.
class Loader<T> extends ChangeNotifier {
  Loader(this._fetch);

  final Future<T> Function() _fetch;

  T? value;
  Object? error;
  bool loading = false;
  bool _disposed = false;

  /// A refresh keeps showing the last value while it runs; only a failure with nothing to show
  /// becomes an error screen.
  Future<void> load() async {
    loading = true;
    _notify();
    try {
      value = await _fetch();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Shows a [Loader]: a spinner until the first value, a retry on failure, [builder] after.
/// Pull to refresh reloads.
class LoaderView<T> extends StatelessWidget {
  const LoaderView({super.key, required this.loader, required this.builder});

  final Loader<T> loader;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: loader,
        builder: (context, _) {
          final value = loader.value;
          if (value == null) {
            if (loader.error != null && !loader.loading) return LoadError(onRetry: loader.load);
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(onRefresh: loader.load, child: builder(context, value));
        },
      );
}

/// Owns a set of [Loader]s for a screen's lifetime: loads them on first build, polls the ones
/// asked to, and disposes them.
mixin LoadersState<W extends StatefulWidget> on State<W> {
  final _loaders = <Loader<Object?>>[];
  final _timers = <Timer>[];

  Loader<T> loader<T>(Future<T> Function() fetch, {Duration? poll}) {
    final l = Loader<T>(fetch);
    _loaders.add(l);
    unawaited(l.load());
    if (poll != null) _timers.add(Timer.periodic(poll, (_) => unawaited(l.load())));
    return l;
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final l in _loaders) {
      l.dispose();
    }
    super.dispose();
  }
}

/// A page's standard padding and width cap, scrolling. Works on a phone and in a wide window.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ],
      );
}

/// A titled card section.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ?trailing,
            ]),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      );
}

/// A label and its value on one line.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ]),
      );
}

/// Shows [text] in a snackbar, replacing any still on screen: snackbars queue, so a refusal
/// right after a success would otherwise wait out the first one's four seconds.
void say(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Runs an action against the car and reports the outcome in a snackbar.
Future<bool> act(BuildContext context, Future<void> Function() action, {String? done, String? failed}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (done != null) say(messenger, done);
    return true;
  } catch (_) {
    if (failed != null) say(messenger, failed);
    return false;
  }
}
