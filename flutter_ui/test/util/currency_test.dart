import 'package:bladewatch_ui/util/currency.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-9uu6.3: currency display.
///
/// Costs used to render as naive concatenation — `'${trip.currency} ${cost.toStringAsFixed(2)}'`
/// — which produces "USD 12.34" and ignores that JPY has no minor unit, that many locales put
/// the symbol after the amount, and that the symbol for a code is not the code.
///
/// The compatibility half matters just as much: a config predating the picker holds a bare
/// symbol, and every trip already priced in it must keep rendering exactly as before.
void main() {
  group('isIsoCodeShaped', () {
    test('accepts exactly three ASCII letters, either case', () {
      expect(Currency.isIsoCodeShaped('USD'), isTrue);
      expect(Currency.isIsoCodeShaped('php'), isTrue);
      expect(Currency.isIsoCodeShaped('eUr'), isTrue);
    });

    test('rejects anything that is not three letters', () {
      for (final v in ['', r'$', 'kr', 'Rp', 'USDX', 'US1', 'US ', '€']) {
        expect(Currency.isIsoCodeShaped(v), isFalse, reason: 'should reject "$v"');
      }
    });
  });

  group('format — ISO codes go through ICU', () {
    test('a known code renders its symbol, not the code', () {
      final usd = Currency.format(12.34, 'USD', locale: 'en_US');
      expect(usd, contains('12.34'));
      expect(usd, contains(r'$'), reason: 'ICU should resolve USD to a symbol');
    });

    /// THE case that fails under naive concatenation: JPY has no minor unit, so a correct
    /// formatter shows no decimal places at all.
    test('a zero-decimal currency drops the minor unit', () {
      final jpy = Currency.format(1234.0, 'JPY', locale: 'en_US');
      expect(jpy, isNot(contains('.00')),
          reason: 'JPY has no minor unit; "1234.00" means the formatter was bypassed');
      expect(jpy, contains('1,234'));
    });

    test('a lower case code is accepted and normalised', () {
      expect(Currency.format(5.0, 'usd', locale: 'en_US'),
          equals(Currency.format(5.0, 'USD', locale: 'en_US')));
    });

    test('an unrecognised but well formed code still renders the amount', () {
      final out = Currency.format(9.5, 'XYZ', locale: 'en_US');
      expect(out, contains('9.5'));
      expect(out, isNotEmpty);
    });
  });

  group('format — legacy values render exactly as before', () {
    /// The pre-picker rendering was `'$currency ${amount.toStringAsFixed(2)}'`. Reproduced
    /// here independently so a change to the production path is caught rather than mirrored.
    String legacyRender(double amount, String currency) =>
        '$currency ${amount.toStringAsFixed(2)}';

    test('a bare symbol keeps its original rendering', () {
      for (final symbol in [r'$', '€', '£', '₹', '¥']) {
        expect(Currency.format(12.3, symbol), equals(legacyRender(12.3, symbol)),
            reason: 'historical trips priced in "$symbol" must not change appearance');
      }
    });

    test('a lower case label is not mistaken for a code', () {
      expect(Currency.format(12.3, 'kr'), equals(legacyRender(12.3, 'kr')));
      expect(Currency.format(12.3, 'Rp'), equals(legacyRender(12.3, 'Rp')));
    });
  });

  group('optionsFor — the picker must never assert', () {
    const catalogue = ['EUR', 'GBP', 'JPY', 'PHP', 'USD'];

    test('a catalogue code is offered exactly once', () {
      final opts = Currency.optionsFor('USD', catalogue);
      expect(opts.where((c) => c == 'USD').length, 1,
          reason: 'DropdownButtonFormField asserts on anything but exactly one match');
      expect(opts, equals(catalogue), reason: 'no need to alter the list');
    });

    /// THE crash this exists to prevent. A config predating the picker holds a bare symbol,
    /// which is not an ISO code. Without this, the settings sheet asserts the moment the
    /// catalogue loads — on precisely the owners whose settings most need changing.
    test('a legacy value absent from the catalogue is still offered exactly once', () {
      for (final legacy in [r'$', 'kr', 'Rp', '₹']) {
        final opts = Currency.optionsFor(legacy, catalogue);
        expect(opts.where((c) => c == legacy).length, 1,
            reason: 'legacy value "$legacy" must appear exactly once, not zero times');
        expect(opts.first, legacy,
            reason: 'prepended so it is visible without scrolling 162 entries');
        expect(opts.length, catalogue.length + 1);
      }
    });

    test('every catalogue entry survives alongside a legacy value', () {
      final opts = Currency.optionsFor(r'$', catalogue);
      for (final c in catalogue) {
        expect(opts, contains(c));
      }
    });

    test('a null or empty catalogue still offers the current value', () {
      expect(Currency.optionsFor('USD', null), equals(['USD']));
      expect(Currency.optionsFor(r'$', null), equals([r'$']));
      expect(Currency.optionsFor('USD', const []), equals(['USD']));
    });

    test('an empty current value falls back rather than offering a blank entry', () {
      expect(Currency.optionsFor('', null), equals([Currency.defaultCode]));
      expect(Currency.optionsFor('', catalogue), equals(catalogue));
      expect(Currency.optionsFor('   ', catalogue), equals(catalogue));
    });
  });

  group('format — nothing to show', () {
    test('null and empty yield an empty string', () {
      expect(Currency.format(12.0, null), isEmpty);
      expect(Currency.format(12.0, ''), isEmpty);
      expect(Currency.format(12.0, '   '), isEmpty);
    });
  });
}
