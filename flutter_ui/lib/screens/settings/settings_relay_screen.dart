import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../gen/l10n/app_localizations.dart';
import 'settings_relay_controller.dart';

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

/// Settings > Relay access (BladeWatch-a7mu): the "Use my relay" switch and the relay key.
class SettingsRelayScreen extends StatefulWidget {
  final SettingsRelayController controller;

  const SettingsRelayScreen({super.key, required this.controller});

  @override
  State<SettingsRelayScreen> createState() => _SettingsRelayScreenState();
}

class _SettingsRelayScreenState extends State<SettingsRelayScreen> {
  final _keyField = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _keyField.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // The field is cleared once the key is stored: the full key is never shown again.
    if (await widget.controller.saveKey(_keyField.text)) _keyField.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;
    final error = switch (c.error) {
      RelayKeyError.invalid => l10n.settings_relay_key_invalid,
      RelayKeyError.saveFailed => l10n.settings_relay_save_failed,
      null => null,
    };

    // The pane title and description come from the Settings hub's shared header.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                key: const ValueKey('relay.enabled'),
                secondary: const Icon(Icons.alt_route),
                title: Text(l10n.settings_relay_use_title),
                subtitle: Text(l10n.settings_relay_use_subtitle),
                value: c.enabled,
                onChanged: c.loading ? null : c.setEnabled,
              ),
              if (c.enabled) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                if (c.showKeyField)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!c.hasKey)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l10n.settings_relay_key_needed,
                              key: const ValueKey('relay.key.needed'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        TextField(
                          key: const ValueKey('relay.key.field'),
                          controller: _keyField,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [RelayKeyInputFormatter()],
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: l10n.settings_relay_key_label,
                            hintText: '0000-0000-0000',
                            errorText: error,
                          ),
                          onSubmitted: (_) => _save(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton(
                              key: const ValueKey('relay.key.save'),
                              onPressed: c.saving ? null : _save,
                              child: Text(l10n.settings_relay_save),
                            ),
                            if (c.hasKey) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                key: const ValueKey('relay.key.cancel'),
                                onPressed: () {
                                  _keyField.clear();
                                  c.cancelEditing();
                                },
                                child: Text(l10n.action_cancel),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  ListTile(
                    key: const ValueKey('relay.key.saved'),
                    leading: const Icon(Icons.key),
                    title: Text(l10n.settings_relay_key_label),
                    subtitle: Text(c.maskedKey!, key: const ValueKey('relay.key.masked')),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          key: const ValueKey('relay.key.change'),
                          onPressed: c.startEditing,
                          child: Text(l10n.settings_relay_change),
                        ),
                        TextButton(
                          key: const ValueKey('relay.key.remove'),
                          onPressed: c.removeKey,
                          child: Text(l10n.settings_relay_remove),
                        ),
                      ],
                    ),
                  ),
              ],
              // A failed switch or remove has no field to carry its error line.
              if (error != null && !(c.enabled && c.showKeyField))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    error,
                    key: const ValueKey('relay.error'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Text(l10n.settings_relay_explainer, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
