#!/usr/bin/env python3
"""
Regression check for xml_to_arb.py's conversion logic (BladeWatch-ncbb.3).

Usage:
    python3 tools/i18n/test_xml_to_arb.py

Covers the non-trivial branching in the script: Android escape/format-specifier
conversion and ICU plural construction. Does not re-check parity/gen-l10n —
those are covered by running `./gradlew validateArbCatalogs` and
`flutter gen-l10n` / `flutter analyze` against the real generated output.
"""

import tempfile
import unittest
from pathlib import Path

from xml_to_arb import (
    convert_placeholders,
    non_translatable_keys,
    parse_strings_xml,
    to_arb_value,
    unescape_android,
)


class UnescapeAndroidTest(unittest.TestCase):
    def test_escaped_apostrophe(self):
        self.assertEqual(unescape_android("head unit\\'s own"), "head unit's own")

    def test_escaped_quote(self):
        self.assertEqual(unescape_android('the \\"USB debugging\\" toggle'), 'the "USB debugging" toggle')

    def test_literal_newline_escape_becomes_real_newline(self):
        self.assertEqual(unescape_android("line one\\n\\nline two"), "line one\n\nline two")

    def test_plain_text_untouched(self):
        self.assertEqual(unescape_android("Dashboard"), "Dashboard")


class ConvertPlaceholdersTest(unittest.TestCase):
    def test_positional_string(self):
        self.assertEqual(convert_placeholders("Camera %1$d set"), "Camera {arg1} set")

    def test_two_positional_args(self):
        self.assertEqual(convert_placeholders("%1$d of %2$d running"), "{arg1} of {arg2} running")

    def test_bare_non_positional_defaults_to_arg1(self):
        self.assertEqual(convert_placeholders("%d recording deleted"), "{arg1} recording deleted")

    def test_precision_is_dropped_from_the_placeholder(self):
        self.assertEqual(convert_placeholders("%1$.1f%% on %2$s"), "{arg1}% on {arg2}")

    def test_literal_percent_with_no_other_specifier(self):
        self.assertEqual(convert_placeholders("Vent 12%%"), "Vent 12%")

    def test_string_with_no_specifiers_is_untouched(self):
        self.assertEqual(convert_placeholders("Dashboard"), "Dashboard")


class ToArbValueTest(unittest.TestCase):
    def test_plain_string_passthrough(self):
        self.assertEqual(to_arb_value('string', 'Dashboard'), 'Dashboard')

    def test_single_placeholder_plural_controlled_by_that_placeholder(self):
        value = to_arb_value('plurals', {
            'one': '{arg1} recording deleted',
            'other': '{arg1} recordings deleted',
        })
        self.assertEqual(
            value,
            '{arg1, plural, one{{arg1} recording deleted} other{{arg1} recordings deleted}}',
        )

    def test_two_placeholder_plural_controlled_by_lower_numbered_arg(self):
        # dashboard_insight_uptime_days_hours: arg1 (days) changes the plural
        # form, arg2 (hours) does not -- the lowest-numbered placeholder must
        # be the ICU plural-control variable, not arg2.
        value = to_arb_value('plurals', {
            'one': 'BladeWatch online for {arg1} day, {arg2} hr',
            'other': 'BladeWatch online for {arg1} days, {arg2} hr',
        })
        self.assertTrue(value.startswith('{arg1, plural,'))
        self.assertIn('{arg2}', value)

    def test_plural_missing_one_falls_back_to_other(self):
        value = to_arb_value('plurals', {'other': '{arg1} items'})
        self.assertEqual(value, '{arg1, plural, one{{arg1} items} other{{arg1} items}}')


class NonTranslatableKeysTest(unittest.TestCase):
    def test_only_translatable_false_keys_are_returned(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "strings.xml"
            path.write_text(
                '<resources>'
                '<string name="normal">Hello</string>'
                '<string name="pinned" translatable="false">https://example.com</string>'
                '</resources>',
                encoding='utf-8',
            )
            self.assertEqual(non_translatable_keys(path), {"pinned"})


class ParseStringsXmlTest(unittest.TestCase):
    def test_string_and_plurals_both_parsed_in_document_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "strings.xml"
            path.write_text(
                '<resources>'
                '<string name="a">Hi \\\'there\\\'</string>'
                '<plurals name="b">'
                '<item quantity="one">%d item</item>'
                '<item quantity="other">%d items</item>'
                '</plurals>'
                '</resources>',
                encoding='utf-8',
            )
            result = parse_strings_xml(path)
            self.assertEqual(list(result.keys()), ["a", "b"])
            self.assertEqual(result["a"], ("string", "Hi 'there'"))
            self.assertEqual(result["b"], ("plurals", {"one": "{arg1} item", "other": "{arg1} items"}))


if __name__ == "__main__":
    unittest.main()
