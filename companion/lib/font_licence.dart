import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Space Mono (the HUD typeface, bundled by packages/bladewatch_theme) is SIL OFL 1.1, which requires its notice to
/// travel with the font. Registered here so it is listed on the licences page beside the packages' own.
void registerFontLicence([AssetBundle? bundle]) {
  LicenseRegistry.addLicense(() async* {
    final text = await (bundle ?? rootBundle).loadString('packages/bladewatch_theme/assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Space Mono'], text);
  });
}
