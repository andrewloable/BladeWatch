#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Audit the two i18n catalogs for machine-translation damage (BladeWatch-1yqg).

The Flutter ARB catalogs (flutter_ui/lib/l10n/app_*.arb) and the Android ones
(app/src/main/res/values-*/strings.xml) were machine-translated INDEPENDENTLY,
so they drifted apart and each carried its own defects. The build already gates
key parity, placeholder parity, letterless values and mixed script (see
validateArbCatalogs / validateAndroidStrings in app/build.gradle.kts). This
script covers the checks that need judgement rather than a hard rule, so it
prints findings instead of failing.

    python3 tools/i18n/audit_catalogs.py            # everything
    python3 tools/i18n/audit_catalogs.py drift      # one check

Checks:
  drift     ARB and Android disagree on a key (ignoring their format syntax)
  dropped   a translation lost a sentence English has
  bleed     training-corpus text (Europarl fragments, scraped web breadcrumbs)
  长         a translation is implausibly longer than the English

Run `sync_android_from_arb.py` to push the ARB text into the Android catalogs
once the ARB side has been reviewed.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARB = os.path.join(ROOT, 'flutter_ui/lib/l10n')
RES = os.path.join(ROOT, 'app/src/main/res')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from catalog_compare import same  # noqa: E402

ANDROID = {'de': 'de', 'es': 'es', 'fr': 'fr', 'hi': 'hi', 'it': 'it', 'ja': 'ja', 'ko': 'ko',
           'nb': 'nb', 'nl': 'nl', 'pt_BR': 'pt-rBR', 'ru': 'ru', 'th': 'th', 'tr': 'tr',
           'vi': 'vi', 'zh_CN': 'zh-rCN', 'zh_TW': 'zh-rTW'}
# Thai marks a sentence end with a SPACE, not a full stop, so terminator counts
# are meaningless there and every Thai hit was a false positive.
NO_SENTENCE_PUNCTUATION = {'th'}
CJK = {'ja', 'ko', 'zh', 'zh_CN', 'zh_TW', 'th'}


def arb(loc):
    with open(os.path.join(ARB, f'app_{loc}.arb'), encoding='utf-8') as fh:
        return {k: v for k, v in json.load(fh).items()
                if not k.startswith('@') and isinstance(v, str)}


def locales():
    return sorted(os.path.basename(p)[4:-4]
                  for p in os.listdir(ARB) if p.endswith('.arb') and p != 'app_en.arb')


def android_strings(av):
    with open(os.path.join(RES, f'values-{av}/strings.xml'), encoding='utf-8') as fh:
        return dict(re.findall(r'<string name="([^"]+)">(.*?)</string>', fh.read(), re.S))


def check_drift(en):
    total = 0
    for loc, av in sorted(ANDROID.items()):
        a, x = arb(loc), android_strings(av)
        bad = [k for k, v in x.items() if isinstance(a.get(k), str) and not same(a[k], v)]
        total += len(bad)
        for k in bad:
            print(f'  drift   {loc:6} {k}\n            arb: {a[k][:70]!r}\n            xml: {x[k][:70]!r}')
    print(f'drift: {total}')


def check_dropped(en):
    term = re.compile(r'[.!?。！？।]+')
    n = lambda v: len(term.findall(re.sub(r'\{[^}]*\}', '', v)))
    total = 0
    for loc in locales():
        if loc in NO_SENTENCE_PUNCTUATION:
            continue
        d = arb(loc)
        for k, v in en.items():
            want = n(v)
            if want >= 2 and isinstance(d.get(k), str) and n(d[k]) < want:
                print(f'  dropped {loc:6} {k}: {n(d[k])}/{want} sentences')
                total += 1
    print(f'dropped: {total}')


def check_bleed(en):
    probes = ['parlament', 'europ', 'comisión', 'kommission', 'mitgliedstaat', 'états membres',
              'estados miembros', 'gobierno', 'gouvernement', 'regierung', 'vrouwen en kinderen',
              '其他國家', '其他类型', '遊戲', '樓盤', '沒有人知道', '首頁', '您的位置', '聯繫我們',
              'je vous en prie']
    total = 0
    for loc in locales():
        d = arb(loc)
        for k, v in d.items():
            low = v.lower()
            hit = next((t for t in probes if t in low), None)
            if hit and hit not in (en.get(k) or '').lower():
                print(f'  bleed   {loc:6} {k}: {v[:60]!r}  [{hit}]')
                total += 1
    print(f'bleed: {total}')


def check_long(en):
    total = 0
    for loc in locales():
        d = arb(loc)
        cap = 1.6 if loc in CJK else 3.2
        for k, v in en.items():
            t = d.get(k)
            if isinstance(t, str) and 3 <= len(v) <= 40 and len(t) > len(v) * cap + 6:
                print(f'  长      {loc:6} {k}: en={v!r} -> {t[:60]!r}')
                total += 1
    print(f'长: {total}')


CHECKS = {'drift': check_drift, 'dropped': check_dropped, 'bleed': check_bleed, 'long': check_long}

if __name__ == '__main__':
    wanted = sys.argv[1:] or list(CHECKS)
    template = arb('en')
    for name in wanted:
        if name not in CHECKS:
            sys.exit(f'unknown check {name!r}; pick from {", ".join(CHECKS)}')
        CHECKS[name](template)
