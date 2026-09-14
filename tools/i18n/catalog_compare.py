# -*- coding: utf-8 -*-
"""Compare the two catalogs on MEANING, ignoring their different format syntax.

ARB uses {arg1} and a real newline; Android uses %1$d / %1$.1f / %s, escapes a
literal percent as %%, XML-escapes & and <, and writes newline as \\n. None of
that is a translation difference.

NOTE the flag class deliberately excludes a space: printf allows "% d", but
including it here made "%% auf" match as a specifier and mangled every string
containing a literal percent.
"""
import re
SPEC = re.compile(r'%(?:(\d+)\$)?[-#+0,(]*\d*(?:\.\d+)?[a-zA-Z]')
NUL = '\x00'   # one format specifier
PCT = '\x01'   # a literal percent that was written %%

def specs_of(v):
    """Specifiers in order, with %% (a literal percent) masked out first."""
    masked = v.replace('%%', PCT)
    return [(m.group(0), m.group(1)) for m in SPEC.finditer(masked)]

def from_android(v):
    v = v.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
    v = v.replace('\\n', '\n').replace("\\'", "'").replace('\\"', '"')
    v = v.replace('%%', PCT)              # protect a literal percent
    v = SPEC.sub(NUL, v)                  # every specifier -> one marker
    return v.replace(PCT, '%')

def from_arb(v):
    return re.sub(r'\{\w+\}', NUL, v)

def same(arb, xml):
    squash = lambda s: re.sub(r'\s+', ' ', s.replace('’', "'").replace('‘', "'")).strip()
    return squash(from_arb(arb)) == squash(from_android(xml))
