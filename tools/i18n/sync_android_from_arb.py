#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Push audited ARB values into the Android catalogs where they genuinely differ.

The two catalogs were machine-translated independently; the ARB side has been
reviewed (BladeWatch-aklv + BladeWatch-1yqg) and the Android side has not, so
the ARB is the better source. Format syntax is converted rather than copied:
each {argN} becomes the specifier the Android string ALREADY used at that
position (%1$d, %1$.1f, %2$s ...), so a %d slot never silently becomes %s.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from catalog_compare import same
from catalog_compare import specs_of
ANDROID = {'de':'de','es':'es','fr':'fr','hi':'hi','it':'it','ja':'ja','ko':'ko','nb':'nb','nl':'nl',
           'pt_BR':'pt-rBR','ru':'ru','th':'th','tr':'tr','vi':'vi','zh_CN':'zh-rCN','zh_TW':'zh-rTW'}
DRY = '--apply' not in sys.argv


def to_android(arb_value, old_xml_value):
    """ARB text -> Android <string> body, reusing the slot TYPES already there.

    Taking the specifier from the existing string (%1$d, %1$.1f, %2$s) matters:
    swapping a %d for a %s would change how the number is formatted, and %.1f
    to %d would drop the decimal.
    """
    found = specs_of(old_xml_value)
    by_slot = {slot: spec for spec, slot in found if slot}
    if not by_slot:
        by_slot = {str(i + 1): spec for i, (spec, _) in enumerate(found)}
    # Escape the literal percents FIRST, then insert specifiers, so the percent
    # signs the specifiers contain are never doubled.
    out = arb_value.replace('%', '%%')
    out = re.sub(r'\{arg(\d+)\}', lambda m: by_slot.get(m.group(1), f'%{m.group(1)}$s'), out)
    out = out.replace('&', '&amp;').replace('<', '&lt;')
    out = out.replace('\n', r'\n').replace("'", r"\'")
    return out

total = 0
for loc, av in sorted(ANDROID.items()):
    arb = json.load(open(os.path.join(ROOT, f'flutter_ui/lib/l10n/app_{loc}.arb')))
    xp = os.path.join(ROOT, f'app/src/main/res/values-{av}/strings.xml')
    src = open(xp, encoding='utf-8').read()
    pairs = re.findall(r'<string name="([^"]+)">(.*?)</string>', src, re.S)
    n = 0
    for k, old in pairs:
        new_arb = arb.get(k)
        if not isinstance(new_arb, str) or same(new_arb, old):
            continue
        new = to_android(new_arb, old)
        if DRY:
            print(f'{loc:6} {k}\n       old: {old[:80]!r}\n       new: {new[:80]!r}')
        else:
            pat = re.compile(r'(<string name="%s">)(.*?)(</string>)' % re.escape(k), re.S)
            src = pat.sub(lambda mo: mo.group(1) + new + mo.group(3), src, count=1)
        n += 1
    if not DRY and n:
        open(xp, 'w', encoding='utf-8').write(src)
    total += n
    if not DRY:
        print(f'{loc:6} synced {n}')
print(('DRY RUN: ' if DRY else 'SYNCED: ') + str(total))
