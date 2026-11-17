#!/usr/bin/env python3
"""mdrender - a small markdown renderer for the terminal (standard library only).

Used by nvagent (chat) and by the Vim markdown preview.

    python3 mdrender.py FILE.md [--width N] [--json]

  (no flag)  prints coloured text (ANSI)
  --json     prints {"lines": [{"t": text, "s": [[byte_start, byte_len, [styles]], ...]}]}
             which the Vim preview turns into text properties.
"""
import json
import os
import re
import shutil
import sys
import textwrap
import unicodedata
import zlib

RESET, BOLD, DIM, ITAL, UL, STRK = (
    "\033[0m", "\033[1m", "\033[2m", "\033[3m", "\033[4m", "\033[9m")
NBOLD, NITAL, NUL, NSTRK, FG0 = "\033[22m", "\033[23m", "\033[24m", "\033[29m", "\033[39m"
RED, GREEN, YEL, BLUE, PUR, CYN, GRAY = (
    "\033[31m", "\033[32m", "\033[33m", "\033[34m", "\033[35m", "\033[36m", "\033[90m")
BGCODE = "\033[48;5;236m"
NBG = "\033[49m"

ANSI = re.compile(r"\033\[([0-9;]*)m")
MARK = re.compile(r"\ue000[^\ue001]*\ue001|\ue002")  # link markers: \ue000 URL \ue001 text \ue002
LINKS = False  # True: remember where the links are (Vim preview)


# ----------------------------------------------------------------------------
# widths and ANSI-aware wrapping
# ----------------------------------------------------------------------------
def cw(ch):
    if unicodedata.combining(ch):
        return 0
    return 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1


def dispw(s):
    return sum(cw(c) for c in MARK.sub("", ANSI.sub("", s)))


def _update_active(active, params):
    for code in (params.split(";") if params else ["0"]):
        if code in ("", "0"):
            active.clear()
            continue
        off = {"22": ("1", "2"), "23": ("3",), "24": ("4",), "29": ("9",), "49": ("48",)}
        if code in off:
            active[:] = [a for a in active if a not in off[code]]
        elif code == "39":
            active[:] = [a for a in active if not (a[:2] in ("38", "30", "31", "32", "33", "34",
                                                             "35", "36", "37", "90"))]
        else:
            active.append(params if ";" in params else code)
            return


def wrap_ansi(s, width, first="", rest=""):
    """Wrap a string that contains ANSI codes; style survives line breaks."""
    width = max(10, width)
    items = []
    for i, piece in enumerate(re.split(r"(\033\[[0-9;]*m)", s)):
        if i % 2:
            items.append(("a", piece, 0))
        else:
            for tok in re.findall(r"\s+|\S+", piece):
                items.append(("s" if tok.isspace() else "w", tok, dispw(tok)))
    lines, cur, curw, active, pend = [], [], 0, [], ""
    indent, lead = first, first

    def start():
        return lead + "".join("\033[%sm" % a for a in active)

    def flush():
        nonlocal cur, curw
        text = "".join(cur)
        lines.append(text + (RESET if active else ""))
        cur, curw = [], 0

    cur = [start()]
    curw = dispw(lead)
    visible = False
    for kind, tok, w in items:
        if kind == "a":
            cur.append(tok)
            _update_active(active, ANSI.match(tok).group(1))
        elif kind == "s":
            if visible:
                pend = tok if "\n" not in tok else " "
        else:
            room = width - curw - (dispw(pend) if visible else 0)
            if visible and w > room:
                flush()
                lead = rest
                cur = [start()]
                curw = dispw(lead)
                visible, pend = False, ""
            if w > width - curw:  # a single huge word: split it
                chunk = ""
                for ch in tok:
                    if dispw(chunk) + cw(ch) > width - curw:
                        cur.append(chunk)
                        flush()
                        lead = rest
                        cur = [start()]
                        curw = dispw(lead)
                        chunk = ""
                    chunk += ch
                tok, w = chunk, dispw(chunk)
            if visible:
                cur.append(pend)
                curw += dispw(pend)
            cur.append(tok)
            curw += w
            visible, pend = True, ""
    if visible or not lines:
        flush()
    return lines


# ----------------------------------------------------------------------------
# inline markdown
# ----------------------------------------------------------------------------
def inline(s):
    stash = []

    def keep(text):
        stash.append(text)
        return "\x00%d\x00" % (len(stash) - 1)

    s = re.sub(r"\\([\\`*_{}\[\]()#+\-.!|~>])", lambda m: keep(m.group(1)), s)
    s = re.sub(r"``(.+?)``|`([^`]+)`",
               lambda m: keep(CYN + (m.group(1) or m.group(2)) + FG0), s)
    s = re.sub(r"!\[([^\]]*)\]\(([^)\s]+)[^)]*\)",
               lambda m: keep(DIM + "▣ " + (m.group(1) or m.group(2)) + NBOLD), s)

    def link(m):
        url = m.group(2)
        shown = url if len(url) <= 34 else url[:31] + "…"
        a, b = ("\ue000%s\ue001" % url, "\ue002") if LINKS else ("", "")
        return keep(a + UL + BLUE + m.group(1) + NUL + FG0 + b + DIM + " (" + shown + ")" + NBOLD)

    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)", link, s)
    s = re.sub(r"<(https?://[^>\s]+)>", lambda m: keep(UL + BLUE + m.group(1) + NUL + FG0), s)
    s = re.sub(r"\*\*(.+?)\*\*|__(.+?)__",
               lambda m: BOLD + (m.group(1) or m.group(2)) + NBOLD, s)
    s = re.sub(r"(?<![\*\w])\*(?![\s*])(.+?)(?<![\s*])\*(?![\*\w])",
               lambda m: ITAL + m.group(1) + NITAL, s)
    s = re.sub(r"(?<![_\w])_(?![\s_])(.+?)(?<![\s_])_(?![_\w])",
               lambda m: ITAL + m.group(1) + NITAL, s)
    s = re.sub(r"~~(.+?)~~", lambda m: STRK + m.group(1) + NSTRK, s)
    for _ in range(3):  # stashed items can contain stashed items
        s = re.sub(r"\x00(\d+)\x00", lambda m: stash[int(m.group(1))], s)
    return s


# ----------------------------------------------------------------------------
# code highlighting
# ----------------------------------------------------------------------------
KW = {
    "c": set("if else while for do switch case break continue return goto sizeof typedef struct "
             "union enum static const extern void int char long short unsigned signed float "
             "double size_t bool true false NULL class public private new delete function let "
             "var fn pub use mod impl func import from package interface".split()),
    "py": set("def class return if elif else for while import from as with try except finally "
              "raise lambda yield pass break continue in is not and or None True False "
              "async await global nonlocal assert del".split()),
    "sh": set("if then else elif fi for while do done case esac function in return exit echo "
              "export local set unset cd source".split()),
}
LANGS = {"c": "c", "h": "c", "cpp": "c", "c++": "c", "cc": "c", "js": "c", "javascript": "c",
         "ts": "c", "java": "c", "go": "c", "rust": "c", "rs": "c", "py": "py", "python": "py",
         "sh": "sh", "bash": "sh", "zsh": "sh", "fish": "sh", "shell": "sh", "make": "sh",
         "makefile": "sh"}
_STR = r"""(?P<st>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')"""
TOK = {
    "c": re.compile(r"(?P<cm>//.*|/\*.*?\*/|/\*.*$)|" + _STR + r"|(?P<nu>\b\d[\w.]*\b)|"
                    r"(?P<w>[A-Za-z_]\w*)"),
    "h": re.compile(r"(?P<cm>#.*)|" + _STR + r"|(?P<nu>\b\d[\w.]*\b)|(?P<w>[A-Za-z_]\w*)"),
}


def hl(lang, ln, state):
    kind = LANGS.get((lang or "").lower())
    if not kind:
        return ln
    if state.get("bc"):
        i = ln.find("*/")
        if i < 0:
            return GRAY + ln + FG0
        state["bc"] = False
        return GRAY + ln[:i + 2] + FG0 + hl(lang, ln[i + 2:], state)
    if kind == "c" and ln.lstrip().startswith("#"):
        return CYN + ln + FG0
    rx = TOK["c" if kind == "c" else "h"]

    def rep(m):
        g, t = m.lastgroup, m.group(0)
        if g == "cm":
            if t.startswith("/*") and not t.endswith("*/"):
                state["bc"] = True
            return GRAY + t + FG0
        if g == "st":
            return GREEN + t + FG0
        if g == "nu":
            return YEL + t + FG0
        if t in KW[kind]:
            return PUR + t + FG0
        if ln[m.end():m.end() + 1] == "(":
            return BLUE + t + FG0
        return t

    return rx.sub(rep, ln)


# ----------------------------------------------------------------------------
# tables
# ----------------------------------------------------------------------------
def _cells(row):
    row = row.strip()
    if row.startswith("|"):
        row = row[1:]
    if row.endswith("|") and not row.endswith("\\|"):
        row = row[:-1]
    return [c.strip().replace("\\|", "|") for c in re.split(r"(?<!\\)\|", row)]


def render_table(rows, width, indent):
    if len(rows) < 2 or not re.match(r"^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$", rows[1]):
        return None
    head = _cells(rows[0])
    seps = _cells(rows[1])
    body = [_cells(r) for r in rows[2:]]
    n = len(head)
    align = []
    for i in range(n):
        s = seps[i] if i < len(seps) else "---"
        align.append("c" if s.startswith(":") and s.endswith(":") else
                     "r" if s.endswith(":") else "l")
    data = [[inline(c) for c in head]] + [
        [inline(c) for c in (r + [""] * n)[:n]] for r in body]
    cols = [max(3, max(dispw(r[i]) for r in data)) for i in range(n)]
    avail = width - len(indent) - (3 * n + 1)
    while sum(cols) > avail and max(cols) > 6:
        cols[cols.index(max(cols))] -= 1
    out = []

    def rule(l, m, r):
        return indent + GRAY + l + m.join("─" * (c + 2) for c in cols) + r + FG0

    def row_lines(cells, bold):
        wrapped = []
        for i, c in enumerate(cells):
            w = wrap_ansi((BOLD + c + NBOLD) if bold else c, cols[i]) or [""]
            wrapped.append(w)
        height = max(len(w) for w in wrapped)
        lines = []
        for k in range(height):
            parts = []
            for i, w in enumerate(wrapped):
                text = w[k] if k < len(w) else ""
                pad = cols[i] - dispw(text)
                if align[i] == "r":
                    text = " " * pad + text
                elif align[i] == "c":
                    text = " " * (pad // 2) + text + " " * (pad - pad // 2)
                else:
                    text = text + " " * pad
                parts.append(" " + text + " ")
            lines.append(indent + GRAY + "│" + FG0 + (GRAY + "│" + FG0).join(parts)
                         + GRAY + "│" + FG0)
        return lines

    out.append(rule("┌", "┬", "┐"))
    out += row_lines(data[0], True)
    out.append(rule("├", "┼", "┤"))
    for r in data[1:]:
        out += row_lines(r, False)
    out.append(rule("└", "┴", "┘"))
    return out


# ----------------------------------------------------------------------------
# the streaming renderer
# ----------------------------------------------------------------------------
FENCE = re.compile(r"^\s*(```+|~~~+)\s*([\w+#.-]*)")
LIST = re.compile(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$")
HEAD = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
HR = re.compile(r"^\s*([-*_])(\s*\1){2,}\s*$")
QUOTE = re.compile(r"^\s*((?:>\s?)+)(.*)$")
FILE_RE = re.compile(r"(?<![\w/.-])((?:[\w.-]+/)*[\w-]+\.[A-Za-z]{1,4})(:\d+(?:-\d+)?)?(?![\w])")


class MDStream:
    """feed() text as it streams in; finished lines go to emit().

    width       function returning the usable width
    blocks      optional list: every closed code block is appended as {lang, text}
    join        True = merge the lines of a paragraph (documents); False = chat
    file_ok     optional function(path) -> bool; existing files get underlined
    """

    def __init__(self, emit, width=None, indent="  ", blocks=None, join=False, file_ok=None):
        self.emit = emit
        self.width = width or (lambda: shutil.get_terminal_size((80, 24)).columns)
        self.indent, self.blocks, self.join, self.file_ok = indent, blocks, join, file_ok
        self.buf, self.code, self.fence, self.lang = "", False, "", ""
        self.cur, self.hs, self.table, self.para = [], {"bc": False}, [], []
        self.blank = True

    # -- public -------------------------------------------------------------
    def feed(self, text):
        self.buf += text
        while "\n" in self.buf:
            line, self.buf = self.buf.split("\n", 1)
            self._line(line)

    def flush(self):
        if self.buf:
            self._line(self.buf)
            self.buf = ""
        self._end_para()
        self._end_table()
        if self.code:
            self._close_code()

    # -- helpers ------------------------------------------------------------
    def _w(self):
        return max(24, self.width() - len(self.indent) - 1)

    def _out(self, s=""):
        self.emit(s)
        self.blank = (s == "")

    def _links(self, s):
        if not self.file_ok:
            return s

        def mark(m):
            return UL + CYN + m.group(0) + NUL + FG0 if self.file_ok(m.group(1)) else m.group(0)

        return FILE_RE.sub(mark, s)

    def _text(self, text, first, rest):
        for ln in wrap_ansi(self._links(inline(text)), self._w(), first, rest):
            self._out(ln)

    def _end_para(self):
        if self.para:
            self._text(" ".join(p.strip() for p in self.para), self.indent, self.indent)
            self.para = []

    def _end_table(self):
        if not self.table:
            return
        rows, self.table = self.table, []
        lines = render_table(rows, self.width(), self.indent)
        if lines is None:
            for r in rows:
                self._text(r, self.indent, self.indent)
        else:
            for ln in lines:
                self._out(ln)

    def _close_code(self):
        self.code = False
        if self.blocks is not None:
            self.blocks.append({"lang": self.lang, "text": "\n".join(self.cur)})
            self._out(DIM + self.indent + "└─ /copy %d" % len(self.blocks) + RESET)
        else:
            self._out(DIM + self.indent + "└─" + RESET)

    # -- one source line ----------------------------------------------------
    def _line(self, ln):
        if self.code:
            m = FENCE.match(ln)
            if m and m.group(1)[0] == self.fence[0] and len(m.group(1)) >= len(self.fence) \
                    and ln.strip() == m.group(1):
                self._close_code()
                return
            self.cur.append(ln)
            self._out(DIM + self.indent + "│ " + RESET + hl(self.lang, ln, self.hs))
            return
        m = FENCE.match(ln)
        if m:
            self._end_para()
            self._end_table()
            self.code, self.fence, self.lang = True, m.group(1), m.group(2).lower()
            self.cur, self.hs = [], {"bc": False}
            n = (len(self.blocks) + 1) if self.blocks is not None else 0
            self._out(DIM + self.indent + "┌─ " + (self.lang or "code")
                      + (" · [%d]" % n if n else "") + RESET)
            return
        if ln.lstrip().startswith("|"):
            self._end_para()
            self.table.append(ln)
            return
        self._end_table()
        st = ln.strip()
        if not st:
            self._end_para()
            if not self.blank:
                self._out("")
            return
        h = HEAD.match(st)
        if h:
            self._end_para()
            level, text = len(h.group(1)), h.group(2)
            if not self.blank:
                self._out("")
            body = inline(text)
            if level == 1:
                self._out(self.indent + BOLD + CYN + ANSI.sub("", body).upper() + RESET)
                self._out(self.indent + CYN + "━" * min(self._w(), max(8, dispw(body))) + FG0)
            elif level == 2:
                self._out(self.indent + BOLD + CYN + ANSI.sub("", body) + RESET)
                self._out(self.indent + GRAY + "─" * min(self._w(), max(8, dispw(body))) + FG0)
            elif level == 3:
                self._out(self.indent + BOLD + PUR + ANSI.sub("", body) + RESET)
            else:
                self._out(self.indent + BOLD + DIM + ANSI.sub("", body) + RESET)
            return
        if HR.match(st):
            self._end_para()
            self._out(DIM + self.indent + "─" * self._w() + RESET)
            return
        q = QUOTE.match(ln)
        if q:
            self._end_para()
            depth = q.group(1).count(">")
            bar = (GRAY + "▎" + FG0 + " ") * depth
            for out in wrap_ansi(ITAL + inline(q.group(2)) + NITAL, self._w() - 2 * depth):
                self._out(self.indent + bar + out)
            return
        li = LIST.match(ln)
        if li:
            self._end_para()
            level = len(li.group(1).replace("\t", "    ")) // 2
            marker = li.group(2)
            body = li.group(3)
            if marker in ("-", "*", "+"):
                bullet = ("•", "◦", "▪")[min(level, 2)]
                tm = re.match(r"^\[([ xX])\]\s+(.*)$", body)
                if tm:
                    bullet = "☑" if tm.group(1) in "xX" else "☐"
                    body = tm.group(2)
            else:
                bullet = marker
            first = self.indent + "  " * level + PUR + bullet + FG0 + " "
            rest = self.indent + "  " * level + " " * (dispw(bullet) + 1)
            self._text(body, first, rest)
            return
        if self.join:
            self.para.append(st)
        else:
            lead = len(ln) - len(ln.lstrip())
            pad = self.indent + (" " * min(lead, 8))
            self._text(st, pad, pad)


# ----------------------------------------------------------------------------
# ANSI -> spans (for the Vim preview)
# ----------------------------------------------------------------------------
_FG = {"31": "red", "32": "green", "33": "yellow", "34": "blue", "35": "purple", "36": "cyan",
       "90": "gray"}


def ansi_to_spans(line):
    """-> (text, spans, links): spans [byte_start, byte_len, [styles]], links [byte_start, byte_len, url]"""
    text, spans, links = "", [], []
    active = {}
    pos = 0
    start = None
    link = None

    def close(end):
        nonlocal start
        if start is not None and end > start[0] and start[1]:
            spans.append([start[0], end - start[0], list(start[1])])
        start = None

    for i, piece in enumerate(re.split(r"(\033\[[0-9;]*m)", line)):
        if i % 2:
            close(pos)
            params = ANSI.match(piece).group(1)
            codes = params.split(";") if params else ["0"]
            j = 0
            while j < len(codes):
                c = codes[j]
                if c in ("0", ""):
                    active.clear()
                elif c == "1":
                    active["b"] = 1
                elif c == "2":
                    active["d"] = 1
                elif c == "3":
                    active["i"] = 1
                elif c == "4":
                    active["u"] = 1
                elif c == "9":
                    active["s"] = 1
                elif c == "22":
                    active.pop("b", None)
                    active.pop("d", None)
                elif c == "23":
                    active.pop("i", None)
                elif c == "24":
                    active.pop("u", None)
                elif c == "29":
                    active.pop("s", None)
                elif c == "39":
                    active.pop("fg", None)
                elif c in _FG:
                    active["fg"] = _FG[c]
                elif c == "48" and j + 2 < len(codes):
                    active["bg"] = 1
                    j += 2
                elif c == "49":
                    active.pop("bg", None)
                j += 1
            start = [pos, sorted(("fg_" + v) if k == "fg" else k for k, v in active.items())]
        else:
            for sub in re.split(r"(\ue000[^\ue001]*\ue001|\ue002)", piece):
                if sub.startswith("\ue000"):
                    link = [pos, sub[1:-1]]
                elif sub == "\ue002":
                    if link and pos > link[0]:
                        links.append([link[0], pos - link[0], link[1]])
                    link = None
                else:
                    text += sub
                    pos += len(sub.encode("utf-8"))
    close(pos)
    if link and pos > link[0]:
        links.append([link[0], pos - link[0], link[1]])
    return text, spans, links


def render_text(src, width, indent="  ", join=True, blocks=None):
    out = []
    md = MDStream(out.append, width=lambda: width, indent=indent, join=join, blocks=blocks)
    md.feed(src if src.endswith("\n") else src + "\n")
    md.flush()
    return out


# ----------------------------------------------------------------------------
# HTML export
# ----------------------------------------------------------------------------
import html as _html  # noqa: E402


def _esc(s):
    return _html.escape(s, quote=False)


def _safe_url(u):
    u = u.strip()
    return "#" if re.match(r"^\s*(javascript|data|vbscript):", u, re.I) else _html.escape(u, quote=True)


def h_inline(s):
    stash = []

    def keep(t):
        stash.append(t)
        return "\x00%d\x00" % (len(stash) - 1)

    s = re.sub(r"\\([\\`*_{}\[\]()#+\-.!|~>])", lambda m: keep(_esc(m.group(1))), s)
    s = re.sub(r"``(.+?)``|`([^`]+)`",
               lambda m: keep("<code>%s</code>" % _esc(m.group(1) or m.group(2))), s)
    s = re.sub(r"!\[([^\]]*)\]\(([^)\s]+)[^)]*\)",
               lambda m: keep('<img src="%s" alt="%s">' % (_safe_url(m.group(2)),
                                                           _html.escape(m.group(1), quote=True))), s)
    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)",
               lambda m: keep('<a href="%s">' % _safe_url(m.group(2))) + m.group(1) + keep("</a>"), s)
    s = re.sub(r"<(https?://[^>\s]+)>",
               lambda m: keep('<a href="%s">%s</a>' % (_safe_url(m.group(1)), _esc(m.group(1)))), s)
    s = _esc(s)
    s = re.sub(r"\*\*(.+?)\*\*|__(.+?)__", lambda m: "<strong>%s</strong>" % (m.group(1) or m.group(2)), s)
    s = re.sub(r"(?<![\*\w])\*(?![\s*])(.+?)(?<![\s*])\*(?![\*\w])", r"<em>\1</em>", s)
    s = re.sub(r"(?<![_\w])_(?![\s_])(.+?)(?<![\s_])_(?![_\w])", r"<em>\1</em>", s)
    s = re.sub(r"~~(.+?)~~", r"<del>\1</del>", s)
    for _ in range(3):
        s = re.sub(r"\x00(\d+)\x00", lambda m: stash[int(m.group(1))], s)
    return s


def html_hl(lang, code):
    kind = LANGS.get((lang or "").lower())
    if not kind:
        return _esc(code)
    rx = TOK["c" if kind == "c" else "h"]
    state = {"bc": False}
    out = []
    for ln in code.split("\n"):
        if state["bc"]:
            i = ln.find("*/")
            if i < 0:
                out.append('<span class="cm">%s</span>' % _esc(ln))
                continue
            state["bc"] = False
            head, ln = '<span class="cm">%s</span>' % _esc(ln[:i + 2]), ln[i + 2:]
        else:
            head = ""
        if kind == "c" and ln.lstrip().startswith("#"):
            out.append(head + '<span class="pp">%s</span>' % _esc(ln))
            continue
        pos, buf = 0, []
        for m in rx.finditer(ln):
            buf.append(_esc(ln[pos:m.start()]))
            g, t = m.lastgroup, m.group(0)
            if g == "cm":
                if t.startswith("/*") and not t.endswith("*/"):
                    state["bc"] = True
                buf.append('<span class="cm">%s</span>' % _esc(t))
            elif g == "st":
                buf.append('<span class="st">%s</span>' % _esc(t))
            elif g == "nu":
                buf.append('<span class="nu">%s</span>' % _esc(t))
            elif t in KW[kind]:
                buf.append('<span class="kw">%s</span>' % _esc(t))
            elif ln[m.end():m.end() + 1] == "(":
                buf.append('<span class="fn">%s</span>' % _esc(t))
            else:
                buf.append(_esc(t))
            pos = m.end()
        buf.append(_esc(ln[pos:]))
        out.append(head + "".join(buf))
    return "\n".join(out)


def _h_list(items):
    html, stack = [], []
    for lvl, ordered, text in items:
        tag = "ol" if ordered else "ul"
        while stack and stack[-1][0] > lvl:
            html.append("</li></%s>" % stack.pop()[1])
        if stack and stack[-1][0] == lvl:
            html.append("</li>")
        else:
            html.append("<%s>" % tag)
            stack.append((lvl, tag))
        tm = re.match(r"^\[([ xX])\]\s+(.*)$", text)
        if tm:
            chk = " checked" if tm.group(1) in "xX" else ""
            html.append('<li class="task"><input type="checkbox" disabled%s> %s' % (chk, h_inline(tm.group(2))))
        else:
            html.append("<li>" + h_inline(text))
    while stack:
        html.append("</li></%s>" % stack.pop()[1])
    return "".join(html)


def _h_blocks(lines):
    out, i, n = [], 0, len(lines)

    def structural(ln):
        st = ln.strip()
        return (FENCE.match(ln) or HEAD.match(st) or HR.match(st) or QUOTE.match(ln)
                or LIST.match(ln) or ln.lstrip().startswith("|"))

    while i < n:
        ln = lines[i]
        m = FENCE.match(ln)
        if m:
            fence, lang, code = m.group(1), m.group(2), []
            i += 1
            while i < n and not (lines[i].strip() == fence or
                                 (FENCE.match(lines[i]) and lines[i].strip() == m.group(1))):
                code.append(lines[i])
                i += 1
            i += 1
            out.append('<pre><code class="language-%s">%s</code></pre>' % (
                _html.escape(lang or "text", quote=True), html_hl(lang, "\n".join(code))))
            continue
        if not ln.strip():
            i += 1
            continue
        h = HEAD.match(ln.strip())
        if h:
            lv = len(h.group(1))
            slug = re.sub(r"[^\w\- ]", "", h.group(2).lower()).strip().replace(" ", "-")
            out.append('<h%d id="%s">%s</h%d>' % (lv, slug, h_inline(h.group(2)), lv))
            i += 1
            continue
        if HR.match(ln.strip()):
            out.append("<hr>")
            i += 1
            continue
        if QUOTE.match(ln):
            inner = []
            while i < n and QUOTE.match(lines[i]):
                inner.append(re.sub(r"^\s*>\s?", "", lines[i]))
                i += 1
            out.append("<blockquote>%s</blockquote>" % "".join(_h_blocks(inner)))
            continue
        if ln.lstrip().startswith("|") and i + 1 < n and re.match(
                r"^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$", lines[i + 1]):
            head, seps = _cells(ln), _cells(lines[i + 1])
            i += 2
            body = []
            while i < n and lines[i].lstrip().startswith("|"):
                body.append(_cells(lines[i]))
                i += 1

            def al(k):
                sp = seps[k] if k < len(seps) else ""
                return "center" if sp.startswith(":") and sp.endswith(":") else \
                    "right" if sp.endswith(":") else "left"

            t = ["<table><thead><tr>"] + ['<th style="text-align:%s">%s</th>' % (al(k), h_inline(c))
                                          for k, c in enumerate(head)] + ["</tr></thead><tbody>"]
            for r in body:
                t.append("<tr>" + "".join('<td style="text-align:%s">%s</td>' % (al(k), h_inline(c))
                                          for k, c in enumerate(r)) + "</tr>")
            t.append("</tbody></table>")
            out.append("".join(t))
            continue
        li = LIST.match(ln)
        if li:
            items = []
            while i < n:
                li = LIST.match(lines[i])
                if li:
                    lvl = len(li.group(1).replace("\t", "    ")) // 2
                    items.append([lvl, li.group(2) not in ("-", "*", "+"), li.group(3)])
                    i += 1
                elif lines[i].strip() and lines[i].startswith(("  ", "\t")) and items:
                    items[-1][2] += " " + lines[i].strip()
                    i += 1
                elif not lines[i].strip() and i + 1 < n and LIST.match(lines[i + 1]):
                    i += 1
                else:
                    break
            out.append(_h_list(items))
            continue
        para = []
        while i < n and lines[i].strip() and not (para and structural(lines[i])):
            para.append(lines[i].strip())
            i += 1
        out.append("<p>%s</p>" % h_inline(" ".join(para)))
    return out


HTML_CSS = """
:root{color-scheme:light dark;--bg:#fff;--fg:#1f2328;--mut:#656d76;--bd:#d0d7de;--code:#f6f8fa;--link:#0969da;
--kw:#cf222e;--st:#0a3069;--nu:#0550ae;--cm:#6e7781;--fn:#8250df;--pp:#953800}
@media(prefers-color-scheme:dark){:root{--bg:#0d1117;--fg:#e6edf3;--mut:#8b949e;--bd:#30363d;--code:#161b22;
--link:#58a6ff;--kw:#ff7b72;--st:#a5d6ff;--nu:#79c0ff;--cm:#8b949e;--fn:#d2a8ff;--pp:#ffa657}}
body{background:var(--bg);color:var(--fg);font:16px/1.6 -apple-system,Segoe UI,Helvetica,Arial,sans-serif;
max-width:860px;margin:2rem auto;padding:0 1rem}
h1,h2{border-bottom:1px solid var(--bd);padding-bottom:.3em}a{color:var(--link)}
code{background:var(--code);padding:.15em .35em;border-radius:5px;font-size:90%}
pre{background:var(--code);padding:1em;border-radius:8px;overflow:auto}pre code{background:none;padding:0}
blockquote{border-left:4px solid var(--bd);margin:1em 0;padding:0 1em;color:var(--mut)}
table{border-collapse:collapse;margin:1em 0}th,td{border:1px solid var(--bd);padding:.4em .8em}
th{background:var(--code)}hr{border:0;border-top:1px solid var(--bd)}img{max-width:100%}
li.task{list-style:none;margin-left:-1.2em}
.kw{color:var(--kw)}.st{color:var(--st)}.nu{color:var(--nu)}.cm{color:var(--cm);font-style:italic}
.fn{color:var(--fn)}.pp{color:var(--pp)}
@media print{body{max-width:none;margin:0}pre{white-space:pre-wrap}}
"""


def md_to_html(src, title="Document"):
    body = "\n".join(_h_blocks(src.splitlines()))
    return ('<!DOCTYPE html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>%s</title><style>%s</style></head><body>\n%s\n</body></html>\n') % (
                _esc(title), HTML_CSS, body)


# ----------------------------------------------------------------------------
# PDF export: a browser / wkhtmltopdf / weasyprint if there is one, else a built-in writer
# ----------------------------------------------------------------------------
_PDF_FG = {"red": (0.80, 0.20, 0.25), "green": (0.20, 0.55, 0.20), "yellow": (0.70, 0.50, 0.05),
           "blue": (0.15, 0.40, 0.80), "purple": (0.60, 0.25, 0.75), "cyan": (0.05, 0.50, 0.55),
           "gray": (0.45, 0.45, 0.45)}
_PDF_MAP = str.maketrans({"─": "-", "━": "=", "│": "|", "┌": "+", "┐": "+", "└": "+", "┘": "+",
                          "├": "+", "┤": "+", "┬": "+", "┴": "+", "┼": "+", "▎": "|", "◦": "o",
                          "▪": "-", "☑": "[x]", "☐": "[ ]", "▣": "[img]", "✦": "*", "…": "...",
                          "•": "\x95", "’": "'", "‘": "'", "“": '"', "”": '"', "–": "-", "—": "-"})


def _segments(text, spans):
    raw = text.encode("utf-8")
    cuts = {0, len(raw)}
    for st, ln, _ in spans:
        cuts.update((st, st + ln))
    cuts = sorted(cuts)
    segs = []
    for a, b in zip(cuts, cuts[1:]):
        styles = set()
        for st, ln, sty in spans:
            if st <= a and b <= st + ln:
                styles.update(sty)
        segs.append((raw[a:b].decode("utf-8", "replace"), styles))
    return segs


def _pdf_str(t):
    b = t.translate(_PDF_MAP).encode("cp1252", "replace")
    return b.replace(b"\\", b"\\\\").replace(b"(", b"\\(").replace(b")", b"\\)")


def builtin_pdf(src, out_path):
    size, lead, cw_ = 9.0, 11.5, 5.4
    left, top, bottom = 40.0, 800.0, 45.0
    cols = int((595 - 2 * left) / cw_) - 1
    lines = render_text(src, cols + 2, indent="", join=True)
    pages, cur, y = [], [], top
    for ln in lines:
        text, spans, _ = ansi_to_spans(ln)
        if y < bottom:
            pages.append(b"\n".join(cur))
            cur, y = [], top
        x = left
        for seg, styles in _segments(text, spans):
            if not seg:
                continue
            font = "F%d" % (1 + (1 if "b" in styles else 0) + (2 if "i" in styles else 0))
            col = (0.5, 0.5, 0.5) if "d" in styles else (0.1, 0.1, 0.1)
            for sty in styles:
                if sty.startswith("fg_"):
                    col = _PDF_FG.get(sty[3:], col)
            w = len(seg.translate(_PDF_MAP)) * cw_
            cur.append(b"BT /%s %.1f Tf %.2f %.2f %.2f rg %.1f %.1f Td (%s) Tj ET" % (
                font.encode(), size, col[0], col[1], col[2], x, y, _pdf_str(seg)))
            if "u" in styles:
                cur.append(b"%.1f w %.2f %.2f %.2f RG %.1f %.1f m %.1f %.1f l S" % (
                    0.5, col[0], col[1], col[2], x, y - 1.5, x + w, y - 1.5))
            x += w
        y -= lead
    pages.append(b"\n".join(cur))
    objs = [b"<< /Type /Catalog /Pages 2 0 R >>", None]
    fonts = ["Courier", "Courier-Bold", "Courier-Oblique", "Courier-BoldOblique"]
    for f in fonts:
        objs.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /%s /Encoding /WinAnsiEncoding >>" % f.encode())
    kids = []
    for content in pages:
        page_no = len(objs) + 1
        kids.append(b"%d 0 R" % page_no)
        objs.append(b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents %d 0 R "
                    b"/Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R /F4 6 0 R >> >> >>" % (page_no + 1))
        z = zlib.compress(content)
        objs.append(b"<< /Length %d /Filter /FlateDecode >>\nstream\n" % len(z) + z + b"\nendstream")
    objs[1] = b"<< /Type /Pages /Kids [%s] /Count %d >>" % (b" ".join(kids), len(kids))
    out, offsets = bytearray(b"%PDF-1.4\n"), []
    for i, o in enumerate(objs, 1):
        offsets.append(len(out))
        out += b"%d 0 obj\n" % i + o + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objs) + 1)
    for off in offsets:
        out += b"%010d 00000 n \n" % off
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objs) + 1, xref)
    with open(out_path, "wb") as f:
        f.write(out)
    return "built-in writer"


def export_pdf(src, md_path, out_path):
    import subprocess
    import tempfile
    hp = os.path.join(tempfile.mkdtemp(prefix="mdpdf-"), "doc.html")
    with open(hp, "w", encoding="utf-8") as f:
        f.write(md_to_html(src, os.path.basename(md_path)))
    browsers = ["chromium", "chromium-browser", "google-chrome", "google-chrome-stable", "chrome",
                "microsoft-edge", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                "/Applications/Chromium.app/Contents/MacOS/Chromium"]
    tries = []
    for b in browsers:
        exe = shutil.which(b) or (b if os.path.isfile(b) else None)
        if exe:
            tries.append((os.path.basename(exe), [exe, "--headless", "--disable-gpu", "--no-sandbox",
                                                  "--no-pdf-header-footer", "--print-to-pdf=" + out_path,
                                                  "file://" + hp]))
            break
    if shutil.which("wkhtmltopdf"):
        tries.append(("wkhtmltopdf", ["wkhtmltopdf", "-q", hp, out_path]))
    if shutil.which("weasyprint"):
        tries.append(("weasyprint", ["weasyprint", "-q", hp, out_path]))
    for name, cmd in tries:
        try:
            if os.path.exists(out_path):
                os.remove(out_path)
            subprocess.run(cmd, capture_output=True, timeout=90)
            if os.path.exists(out_path) and os.path.getsize(out_path) > 200:
                return name
        except Exception:
            continue
    return builtin_pdf(src, out_path)


def main(argv):
    global LINKS
    width = shutil.get_terminal_size((80, 24)).columns
    as_json = "--json" in argv
    opts = {}
    args = []
    skip = False
    for i, a in enumerate(argv[1:], 1):
        if skip:
            skip = False
        elif a in ("--width", "--html", "--pdf", "--title") and i + 1 < len(argv):
            opts[a] = argv[i + 1]
            skip = True
        elif not a.startswith("--"):
            args.append(a)
    if "--width" in opts:
        width = int(opts["--width"])
    src = open(args[0], encoding="utf-8", errors="replace").read() if args else sys.stdin.read()
    name = opts.get("--title") or (args[0] if args else "document")
    if "--html" in opts:
        with open(opts["--html"], "w", encoding="utf-8") as f:
            f.write(md_to_html(src, os.path.basename(name)))
        print("html: " + opts["--html"])
        return
    if "--pdf" in opts:
        how = export_pdf(src, name, opts["--pdf"])
        print("pdf (%s): %s" % (how, opts["--pdf"]))
        return
    if as_json:
        LINKS = True
    lines = render_text(src, width, indent=" ", join=True)
    if as_json:
        res = []
        for ln in lines:
            t, sp, lk = ansi_to_spans(ln)
            res.append({"t": t, "s": sp, "l": lk})
        sys.stdout.write(json.dumps({"lines": res}))
    else:
        print("\n".join(lines))


if __name__ == "__main__":
    main(sys.argv)
