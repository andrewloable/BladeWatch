import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'adb_console_controller.dart';
import 'adb_console_models.dart';

/// Ground truth: `AdbConsoleFragment.kt` + `fragment_adb_console.xml`. Talks
/// directly to adbd over `AdbConnection` (`flutter_ui/lib/adb/adb_client.dart`)
/// — there is no daemon IPC command for this (see that file's doc comment) —
/// so this screen also has to render the 2 not-connected states a fragment
/// that always has ADB-via-dadb available never needed: [unavailable] (ADB
/// itself is off) and [authPending] (adbd is up but hasn't authorized this
/// app's key yet).
class AdbConsoleScreen extends StatefulWidget {
  final AdbConsoleController controller;

  const AdbConsoleScreen({super.key, required this.controller});

  @override
  State<AdbConsoleScreen> createState() => _AdbConsoleScreenState();
}

class _AdbConsoleScreenState extends State<AdbConsoleScreen> {
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.connect();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final command = _commandController.text;
    if (command.trim().isEmpty) return;
    _commandController.clear();
    widget.controller.execute(command);
  }

  void _selectPreset(AdbPresetCommand preset) {
    _commandController.text = preset.command;
    _commandController.selection = TextSelection.collapsed(offset: preset.command.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adb_console_hero_title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.adb_console_hero_subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _body(context, l10n, theme, c)),
      ],
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, ThemeData theme, AdbConsoleController c) {
    switch (c.connectionState) {
      case AdbConsoleConnectionState.connecting:
        return Center(
          key: const ValueKey('adb.connecting'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.url_connecting),
            ],
          ),
        );
      case AdbConsoleConnectionState.unavailable:
        return _explanation(
          key: 'adb.unavailable',
          theme: theme,
          icon: Icons.usb_off,
          title: l10n.adb_console_unavailable_title,
          body: l10n.adb_console_unavailable_body,
          l10n: l10n,
        );
      case AdbConsoleConnectionState.authPending:
        return _explanation(
          key: 'adb.authPending',
          theme: theme,
          icon: Icons.pending_outlined,
          title: l10n.adb_console_auth_pending_title,
          body: l10n.adb_console_auth_pending_body,
          l10n: l10n,
        );
      case AdbConsoleConnectionState.connected:
        return _console(context, l10n, theme, c);
    }
  }

  Widget _explanation({
    required String key,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String body,
    required AppLocalizations l10n,
  }) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('adb.retryButton'),
              onPressed: widget.controller.connect,
              child: Text(l10n.action_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _console(BuildContext context, AppLocalizations l10n, ThemeData theme, AdbConsoleController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Native groups the command field and its presets in one card headed
        // "PRESET COMMANDS", with a LABELLED Run button rather than a bare
        // send arrow (BladeWatch-mrsc).
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('adb.commandField'),
                        controller: _commandController,
                        enabled: !c.isExecuting,
                        decoration: InputDecoration(
                          prefixText: '${l10n.adb_prompt} ',
                          hintText: l10n.adb_command_hint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const ValueKey('adb.executeButton'),
                      onPressed: c.isExecuting ? null : _submit,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(l10n.action_run),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.adb_preset_commands_header.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: adbPresetCommands.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = adbPresetCommands[index];
                      return ActionChip(
                        key: ValueKey('adb.preset.$index'),
                        label: Text(preset.label),
                        onPressed: () => _selectPreset(preset),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adb_output_header.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              OutlinedButton(
                key: const ValueKey('adb.clearButton'),
                onPressed: c.clearOutput,
                child: Text(l10n.action_clear_output),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              // Outlined, as native has it, rather than a filled grey slab.
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Text(
                c.output.isEmpty ? l10n.adb_output_ready : c.output,
                key: const ValueKey('adb.output'),
                style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
