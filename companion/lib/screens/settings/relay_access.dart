import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pear/flutter_pear.dart';

import '../../car/car_store.dart';
import '../../i18n.dart';

/// Groups typed digits as a relay key, 4-4-4 (4821-0937-5562), and drops anything else.
class RelayKeyInputFormatter extends TextInputFormatter {
  const RelayKeyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final groups = [
      for (var i = 0; i < digits.length; i += 4) digits.substring(i, i + 4 > digits.length ? digits.length : i + 4),
    ];
    final text = groups.join('-');
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Opens [RelayAccessPanel] in a dialog: from the "can't reach the car" page, where the car's
/// screens (Settings included) are not available -- exactly when a relay is needed.
Future<void> showRelayAccess(BuildContext context, CarStore store, {required Future<void> Function() onChanged}) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('companion.relay_access')),
        content: SingleChildScrollView(child: RelayAccessPanel(store: store, onChanged: onChanged)),
        actions: [
          TextButton(
            key: const ValueKey('relay.close'),
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.close')),
          ),
        ],
      ),
    );

/// The owner's own relay (BladeWatch-a7mu): reach a car that is online through its SIM from mobile
/// data. The same 12-digit key goes on the relay, the car and every companion. Off by default.
///
/// The key is kept in [CarStore], like the car credential, and shown only masked once saved.
/// [onChanged] runs after every saved change: the session looks for the car again, applying it.
class RelayAccessPanel extends StatefulWidget {
  const RelayAccessPanel({super.key, required this.store, required this.onChanged});

  final CarStore store;
  final Future<void> Function() onChanged;

  @override
  State<RelayAccessPanel> createState() => _RelayAccessPanelState();
}

class _RelayAccessPanelState extends State<RelayAccessPanel> {
  final _field = TextEditingController();
  var _editing = false;
  String? _error;

  CarStore get _store => widget.store;
  bool get _hasKey => _store.relayKey != null;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Applies [change] to the store and saves it; on failure puts everything back.
  Future<bool> _apply(void Function() change) async {
    final enabled = _store.relayEnabled;
    final key = _store.relayKey;
    change();
    try {
      await _store.save();
    } catch (_) {
      _store
        ..relayEnabled = enabled
        ..relayKey = key;
      if (mounted) setState(() => _error = context.tr('errors.save_failed'));
      return false;
    }
    if (mounted) setState(() => _error = null);
    await widget.onChanged();
    return true;
  }

  Future<void> _save() async {
    final String digits;
    try {
      digits = Pear.normalizeRelayKey(_field.text);
    } on ArgumentError {
      setState(() => _error = context.tr('companion.relay_key_invalid'));
      return;
    }
    if (await _apply(() => _store.relayKey = digits)) {
      _field.clear();
      if (mounted) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final theme = Theme.of(context);
    final key = _store.relayKey;
    final showField = _editing || !_hasKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          key: const ValueKey('relay.enabled'),
          contentPadding: EdgeInsets.zero,
          title: Text(tr('companion.relay_use')),
          subtitle: Text(tr('companion.relay_use_hint')),
          value: _store.relayEnabled,
          onChanged: (on) => _apply(() => _store.relayEnabled = on),
        ),
        if (_store.relayEnabled) ...[
          if (showField) ...[
            if (!_hasKey)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tr('companion.relay_key_needed'), key: const ValueKey('relay.key.needed')),
              ),
            TextField(
              key: const ValueKey('relay.key.field'),
              controller: _field,
              keyboardType: TextInputType.number,
              inputFormatters: const [RelayKeyInputFormatter()],
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: tr('companion.relay_key'), hintText: '0000-0000-0000', errorText: _error),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton(key: const ValueKey('relay.key.save'), onPressed: _save, child: Text(tr('common.save'))),
              if (_hasKey)
                TextButton(
                  key: const ValueKey('relay.key.cancel'),
                  onPressed: () => setState(() {
                    _field.clear();
                    _editing = false;
                    _error = null;
                  }),
                  child: Text(tr('common.cancel')),
                ),
            ]),
          ] else ...[
            ListTile(
              key: const ValueKey('relay.key.saved'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr('companion.relay_key')),
              // Only the last group, ever: the key is the relay's password.
              subtitle: Text('••••-••••-${key!.substring(key.length - 4)}', key: const ValueKey('relay.key.masked')),
            ),
            Wrap(spacing: 8, children: [
              TextButton(
                key: const ValueKey('relay.key.change'),
                onPressed: () => setState(() {
                  _editing = true;
                  _error = null;
                }),
                child: Text(tr('companion.relay_change')),
              ),
              TextButton(
                key: const ValueKey('relay.key.remove'),
                onPressed: () => _apply(() => _store
                  ..relayKey = null
                  ..relayEnabled = false),
                child: Text(tr('companion.relay_remove')),
              ),
            ]),
          ],
        ],
        if (_error != null && !(_store.relayEnabled && showField))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, key: const ValueKey('relay.error'), style: TextStyle(color: theme.colorScheme.error)),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(tr('companion.relay_explainer'), style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
