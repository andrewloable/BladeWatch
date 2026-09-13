import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../shell/locale_controller.dart';

/// Native-script display name for each supported tag — ground truth:
/// `LanguagePickerDialog.NATIVE_NAMES`. Deliberately not an ARB catalog: a
/// language's own name in its own script does not change depending on which
/// language the picker itself is currently displayed in (native makes the
/// exact same choice, hardcoding this map rather than localizing it).
const Map<String, String> kLocaleNativeNames = {
  'en': 'English',
  'zh-CN': '简体中文',
  'zh-TW': '繁體中文',
  'pt-BR': 'Português (Brasil)',
  'es': 'Español',
  'de': 'Deutsch',
  'fr': 'Français',
  'it': 'Italiano',
  'nb': 'Norsk bokmål',
  'nl': 'Nederlands',
  'ja': '日本語',
  'ko': '한국어',
  'th': 'ไทย',
  'vi': 'Tiếng Việt',
  'hi': 'हिन्दी',
  'tr': 'Türkçe',
  'ru': 'Русский',
};

/// Opens the language picker as a modal bottom sheet — ground truth:
/// `LanguagePickerDialog.show()`'s `BottomSheetDialog`. Both of the shell's
/// entry points (the toolbar/rail language button and Settings → Appearance's
/// language row) call this the same way native calls the same dialog from
/// multiple places.
Future<void> showLanguagePickerSheet(BuildContext context, LocaleController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => LanguagePickerSheet(controller: controller),
  );
}

class LanguagePickerSheet extends StatelessWidget {
  final LocaleController controller;

  const LanguagePickerSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 32, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outline, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.language_picker_title, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        Text(
                          l10n.language_picker_subtitle_fmt(kSupportedLocaleTags.length),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('languagePicker.close'),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.cd_close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _Row(
                    isCurrent: controller.isAuto,
                    title: l10n.language_auto_title,
                    subtitle: l10n.language_auto_subtitle(kLocaleNativeNames[_systemNameKey(context)] ?? 'English'),
                    tag: null,
                    onTap: () {
                      controller.select(kAutoLocaleTag);
                      Navigator.of(context).pop();
                    },
                  ),
                  for (final tag in kSupportedLocaleTags)
                    _Row(
                      isCurrent: !controller.isAuto && controller.rawTag == tag,
                      title: kLocaleNativeNames[tag] ?? tag,
                      subtitle: null,
                      tag: tag,
                      onTap: () {
                        controller.select(tag);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Best-effort supported tag for the platform's current locale, purely to
  /// label the Auto row's subtitle (e.g. "Follow system · English") — native
  /// resolves this the same way `LocaleManager.get()` does when no explicit
  /// pick has been made. Falls back to English on no match, same as native's
  /// own `DEFAULT_LANG`.
  String _systemNameKey(BuildContext context) {
    final platformLocale = View.of(context).platformDispatcher.locale;
    final withRegion = platformLocale.countryCode != null ? '${platformLocale.languageCode}-${platformLocale.countryCode}' : null;
    if (withRegion != null && kSupportedLocaleTags.contains(withRegion)) return withRegion;
    if (kSupportedLocaleTags.contains(platformLocale.languageCode)) return platformLocale.languageCode;
    return 'en';
  }
}

class _Row extends StatelessWidget {
  final bool isCurrent;
  final String title;
  final String? subtitle;
  final String? tag;
  final VoidCallback onTap;

  const _Row({required this.isCurrent, required this.title, required this.subtitle, required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('languagePicker.row.${tag ?? 'auto'}'),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag != null) ...[
            Text(tag!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontFamily: 'monospace')),
            const SizedBox(width: 12),
          ],
          Icon(Icons.check, color: isCurrent ? theme.colorScheme.primary : Colors.transparent, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
