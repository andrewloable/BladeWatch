#!/usr/bin/env python3
"""
Generate Flutter ARB catalogs from the Android strings.xml catalogs.

Usage:
    python3 tools/i18n/xml_to_arb.py

Run from the project root (BladeWatch/). Reads app/src/main/res/values*/strings.xml
(624 <string> + 8 <plurals> keys per locale) and writes one
flutter_ui/lib/l10n/app_<locale>.arb per locale, 632 keys each.

Idempotent: every run rewrites all 17 ARB files from scratch.

Key set is driven by the English template (values/strings.xml). Every translated
locale currently carries 7 extra keys (rail_integrations, integrations_*) that
don't exist in the template -- stale leftovers from a removed/renamed screen.
Since only template keys are ever looked up per locale, those 7 are silently
skipped (reported on stdout, not treated as an error) rather than ported, so
every ARB ends up with exactly the template's key set -- see BladeWatch-ncbb.3
task notes for the full list and reasoning.

Format-specifier mapping: Android %1$s / %2$d / %1$.1f / bare %d / %% all become
{argN} ARB placeholders (position N, defaulting to 1 for the non-positional bare
form -- verified no string mixes bare and positional specifiers). Precision
(the ".1"/".0" in %1$.1f) is dropped: the placeholder is untyped (Object), and
decimal formatting becomes the calling Dart code's job, same as it already is
Kotlin/Java's job today via String.format at each call site.

<plurals> become one ICU plural clause per key: "{argN, plural, one{...}
other{...}}", where argN is the lowest-numbered placeholder appearing in the
item text (the one actually being pluralized -- verified against the one
two-placeholder plural in this dataset, dashboard_insight_uptime_days_hours,
where the lower-numbered placeholder is the day count that changes the noun
form and the higher-numbered one is the hour count that does not).
"""

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).parent.parent.parent
RES_DIR = ROOT / "app/src/main/res"
ARB_DIR = ROOT / "flutter_ui/lib/l10n"

# Android res/values* dir name -> ARB locale code (BCP-47-ish, underscore for
# region, matching Dart's Locale.toString()). "values" is the English template.
LOCALES = {
    "values": "en",
    "values-de": "de",
    "values-es": "es",
    "values-fr": "fr",
    "values-hi": "hi",
    "values-it": "it",
    "values-ja": "ja",
    "values-ko": "ko",
    "values-nb": "nb",
    "values-nl": "nl",
    "values-pt-rBR": "pt_BR",
    "values-ru": "ru",
    "values-th": "th",
    "values-tr": "tr",
    "values-vi": "vi",
    "values-zh-rCN": "zh_CN",
    "values-zh-rTW": "zh_TW",
}

# %1$s, %2$d, %1$.1f, %1$.0f, bare %d, %%  -- every form actually used in this
# catalog (verified against all 17 locale files before writing this).
PLACEHOLDER_RE = re.compile(r'%(?:(\d+)\$)?(?:\.(\d+))?([sdf%])')


def unescape_android(text: str) -> str:
    """Undo Android string-resource escaping (verified: no \\t, \\\\, \\@, \\?,
    or quote-wrapped values exist in this catalog, so only these three)."""
    return text.replace("\\'", "'").replace('\\"', '"').replace('\\n', '\n')


def convert_placeholders(text: str) -> str:
    """Android %n$s / %n$.Nf / bare %d / %% -> ARB {argN} / literal %."""
    def repl(m: re.Match) -> str:
        if m.group(3) == '%':
            return '%'
        pos = m.group(1) or '1'
        return '{arg' + pos + '}'
    return PLACEHOLDER_RE.sub(repl, text)


def placeholders_in(*texts: str) -> list[str]:
    """Distinct {argN} names actually present, in numeric order."""
    found = set()
    for t in texts:
        found.update(re.findall(r'\{(arg\d+)\}', t))
    return sorted(found, key=lambda n: int(n[3:]))


def non_translatable_keys(template_path: Path) -> set[str]:
    """
    Keys marked translatable="false" in the English template -- these must be
    pinned to the template's own value for every locale (see main()). Found by
    inspecting 4 such keys (the settings_about_*_url ones): despite the
    translatable="false" marker, a past bulk/LLM translation pass over this
    catalog translated them anyway, and having no real content to translate (a
    bare URL), it silently hallucinated unrelated sentences in most locales
    (e.g. values-de's settings_about_source_url is "Das ist ein sehr schoenes
    Beispiel." -- "This is a very nice example.", not a URL at all), left it
    blank in values-th, and mildly mangled it (bracket-wrapped, or http not
    https) in values-ko/values-nb. This is a real, pre-existing bug in the
    shipped native app across most of its 16 non-English locales -- filed as
    BladeWatch-i18n-url-corruption for the native side, out of scope here.
    """
    root = ET.parse(template_path).getroot()
    return {
        el.get('name')
        for el in root
        if el.tag == 'string' and el.get('name') and el.get('translatable') == 'false'
    }


def parse_strings_xml(path: Path) -> dict[str, tuple[str, object]]:
    """
    Parse one strings.xml. Returns {name: (kind, value)} in document order,
    where kind is "string" (value: str) or "plurals" (value: {quantity: str}).
    Values are already Android-unescaped and placeholder-converted.
    """
    root = ET.parse(path).getroot()
    result: dict[str, tuple[str, object]] = {}
    for el in root:
        name = el.get('name')
        if name is None:
            continue
        if el.tag == 'string':
            result[name] = ('string', convert_placeholders(unescape_android(el.text or '')))
        elif el.tag == 'plurals':
            items = {}
            for item in el:
                if item.tag == 'item' and item.get('quantity'):
                    items[item.get('quantity')] = convert_placeholders(unescape_android(item.text or ''))
            result[name] = ('plurals', items)
    return result


def to_arb_value(kind: str, value: object) -> str:
    if kind == 'string':
        assert isinstance(value, str)
        return value
    assert isinstance(value, dict)
    one = value.get('one', value.get('other', ''))
    other = value.get('other', '')
    control = (placeholders_in(one, other) or ['arg1'])[0]
    return '{' + control + ', plural, one{' + one + '} other{' + other + '}}'


def write_arb(locale_code: str, arb: dict[str, object]) -> Path:
    out_path = ARB_DIR / f"app_{locale_code}.arb"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(arb, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return out_path


def main() -> None:
    template_dir = RES_DIR / "values"
    template_data = parse_strings_xml(template_dir / "strings.xml")
    template_keys = list(template_data.keys())
    pinned = non_translatable_keys(template_dir / "strings.xml")

    ARB_DIR.mkdir(parents=True, exist_ok=True)
    fallbacks_written: set[str] = set()

    for dirname, locale_code in LOCALES.items():
        xml_path = RES_DIR / dirname / "strings.xml"
        data = parse_strings_xml(xml_path)
        is_template = dirname == "values"

        arb: dict[str, object] = {"@@locale": locale_code}
        missing = [name for name in template_keys if name not in data]
        if missing:
            print(f"ERROR: {dirname}: missing {len(missing)} key(s) present in the "
                  f"template: {missing[:5]}", file=sys.stderr)
            sys.exit(1)

        for name in template_keys:
            # translatable="false" keys are pinned to the template's value --
            # never the locale's own (see non_translatable_keys() docstring:
            # several locales have corrupted/hallucinated text here instead).
            kind, value = template_data[name] if name in pinned else data[name]
            arb_value = to_arb_value(kind, value)
            arb[name] = arb_value
            if is_template:
                arb_value_texts = (value,) if kind == 'string' else tuple(value.values())
                ph = placeholders_in(*arb_value_texts)
                arb[f"@{name}"] = {"placeholders": {p: {} for p in ph}} if ph else {}

        out_path = write_arb(locale_code, arb)
        orphans = set(data.keys()) - set(template_keys)
        note = f"  (skipped {len(orphans)} orphan key(s) not in template)" if orphans else ""
        print(f"{dirname:16s} -> {out_path.name:20s} {len(template_keys)} keys{note}")

        # flutter gen-l10n requires a bare-language fallback ARB for every
        # region/script-qualified locale (app_pt.arb for pt_BR, app_zh.arb for
        # zh_CN/zh_TW). This catalog has no such generic variant in Android
        # either (only values-pt-rBR and values-zh-rCN/-rTW exist) -- the
        # first region variant encountered for a given base language becomes
        # that language's fallback, which for "zh" is zh_CN (simplified),
        # matching the common real-world default.
        base = locale_code.split('_')[0]
        if base != locale_code and base not in LOCALES.values() and base not in fallbacks_written:
            fallback_arb = dict(arb)
            fallback_arb["@@locale"] = base
            fallback_path = write_arb(base, fallback_arb)
            fallbacks_written.add(base)
            print(f"{'':16s} -> {fallback_path.name:20s} (fallback copy for bare '{base}')")

    print("\nDone.")


if __name__ == "__main__":
    main()
