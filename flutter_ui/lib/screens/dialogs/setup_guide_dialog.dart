import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../shell/locale_controller.dart';
import 'language_picker_sheet.dart';
import 'setup_guide_controller.dart';

/// First-launch / post-update setup guide — ground truth:
/// `SetupGuideDialog.java` + `dialog_setup_guide.xml` (BladeWatch-yz1e.11).
///
/// Two of native's 3 steps' checkmarks are intentionally never shown here,
/// matching (Language) or narrowing (Overlay) native's own real behaviour
/// rather than guessing at it:
/// - Language: native's `ivLanguageCheck` is hardcoded `VISIBLE` in the
///   layout and never touched in code ("Auto is a valid selection out of
///   the box") — ported the same way, as a permanently-shown check.
/// - Auto-start: native's `ivAutoStartCheck` defaults `INVISIBLE` and is
///   never set `VISIBLE` anywhere in `SetupGuideDialog.java` — dead UI in
///   native too; this port matches that (never shown), not "fixes" it.
/// - Overlay: native checks `Settings.canDrawOverlays(context)` for *its
///   own* package. This dialog's overlay step targets the main app's
///   package instead (see `MainActivity.kt`'s `openOverlaySettings()` doc
///   comment for why), whose grant state cannot be queried without
///   `AppOpsManager` reflection this port cannot verify without a device —
///   left for BladeWatch-imh6 to confirm/wire on-device rather than guessed
///   at here.
/// [updatedToVersion] drives the version banner and is the caller's
/// responsibility, not this function's — ground truth:
/// `SetupGuideDialog.show(context, isUpdate)`'s two call sites: `showIfNeeded()`
/// passes its own real `isUpdate` verdict (from comparing install markers);
/// the public force-show overload hardcodes `false` unconditionally, so a
/// user manually re-opening the guide from Settings never sees a stale
/// "updated to vX" banner regardless of what actually changed since. Callers
/// pass `controller.checkIfNeeded()`'s result — which also sets
/// [SetupGuideController.updatedToVersion] as a side effect — for the
/// auto-show path, and omit it (or pass `null`) for a force-show.
Future<void> showSetupGuideDialog(
  BuildContext context,
  SetupGuideController controller,
  LocaleController localeController, {
  String? updatedToVersion,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _SetupGuideDialogContent(
      controller: controller,
      localeController: localeController,
      updatedToVersion: updatedToVersion,
    ),
  );
}

class _SetupGuideDialogContent extends StatelessWidget {
  final SetupGuideController controller;
  final LocaleController localeController;
  final String? updatedToVersion;

  const _SetupGuideDialogContent({required this.controller, required this.localeController, required this.updatedToVersion});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.setup_guide_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (updatedToVersion != null) ...[
              Container(
                key: const ValueKey('setupGuide.versionBanner'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  l10n.setup_version_banner(updatedToVersion!),
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(l10n.setup_guide_subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            _StepCard(
              step: l10n.setup_step_one_label,
              title: l10n.setup_language_title,
              body: l10n.setup_language_body,
              buttonLabel: l10n.setup_language_button,
              showCheck: true,
              buttonKey: const ValueKey('setupGuide.openLanguage'),
              onPressed: () => showLanguagePickerSheet(context, localeController),
            ),
            const SizedBox(height: 12),
            _StepCard(
              step: l10n.setup_step_two_label,
              title: l10n.setup_autostart_title,
              body: l10n.setup_autostart_body,
              buttonLabel: l10n.setup_autostart_button,
              showCheck: false,
              buttonKey: const ValueKey('setupGuide.openAutoStart'),
              onPressed: controller.openAutoStartSettings,
            ),
            const SizedBox(height: 12),
            _StepCard(
              step: l10n.setup_step_three_label,
              title: l10n.setup_overlay_title,
              body: l10n.setup_overlay_body,
              buttonLabel: l10n.setup_overlay_button,
              showCheck: false,
              buttonKey: const ValueKey('setupGuide.openOverlay'),
              onPressed: controller.openOverlaySettings,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('setupGuide.skip'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.action_remind_me_later),
        ),
        FilledButton(
          key: const ValueKey('setupGuide.done'),
          onPressed: () async {
            await controller.markSeen();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n.action_done),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String body;
  final String buttonLabel;
  final bool showCheck;
  final Key buttonKey;
  final VoidCallback onPressed;

  const _StepCard({
    required this.step,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.showCheck,
    required this.buttonKey,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(step, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (showCheck) Icon(Icons.check, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(key: buttonKey, onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
