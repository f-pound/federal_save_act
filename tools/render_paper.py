#!/usr/bin/env python3
"""render_paper.py — render papers/computational_amicus_brief_method_and_results.md
to web/paper/index.html (the published white paper page)."""
import re, html, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "papers/computational_amicus_brief_method_and_results.md"
DST = ROOT / "web/paper/index.html"

def inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', t)
    t = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', t)
    t = re.sub(r'(?<![">])(https?://[^\s<)]+)', r'<a href="\1">\1</a>', t)
    return t

def render(src):
    lines = src.split('\n'); out = []; para = []
    title = lines[0].lstrip('# ').strip(); meta = lines[2].strip('* ')
    i = 3
    def flush():
        nonlocal para
        if para: out.append('<p>' + inline(' '.join(para)) + '</p>'); para = []
    while i < len(lines):
        l = lines[i]
        if l.startswith('```'):
            flush(); j = i + 1; buf = []
            while j < len(lines) and not lines[j].startswith('```'): buf.append(lines[j]); j += 1
            out.append('<pre><code>' + html.escape('\n'.join(buf)) + '</code></pre>'); i = j + 1; continue
        if l.startswith('|'):
            flush(); rows = []
            while i < len(lines) and lines[i].startswith('|'):
                cells = [c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', c) for c in cells): rows.append(cells)
                i += 1
            h, body = rows[0], rows[1:]
            out.append('<div class="tbl"><table><thead><tr>' + ''.join(f'<th>{inline(c)}</th>' for c in h) + '</tr></thead><tbody>' +
                       ''.join('<tr>' + ''.join(f'<td>{inline(c)}</td>' for c in r) + '</tr>' for r in body) + '</tbody></table></div>'); continue
        m = re.match(r'^(#{1,3}) (.*)', l)
        if m:
            flush(); level = len(m.group(1)); txt = m.group(2)
            if level == 2:
                num = re.match(r'^(\d+|Appendix [A-C])\. (.*)', txt)
                out.append(f'<h2><span class="num">{num.group(1)}</span>{inline(num.group(2))}</h2>' if num else (f'<h2 class="abs-h">{inline(txt)}</h2>' if txt == 'Abstract' else f'<h2>{inline(txt)}</h2>'))
            else: out.append(f'<h{level}>{inline(txt)}</h{level}>')
            i += 1; continue
        if l.strip() == '---': flush(); out.append('<hr>'); i += 1; continue
        if re.match(r'^\s*[-*] ', l) or re.match(r'^\s*\d+\. ', l):
            flush(); ordered = bool(re.match(r'^\s*\d+\. ', l)); items = []
            while i < len(lines) and (re.match(r'^\s*[-*] ', lines[i]) or re.match(r'^\s*\d+\. ', lines[i])):
                items.append(re.sub(r'^\s*([-*]|\d+\.) ', '', lines[i])); i += 1
            tag = 'ol' if ordered else 'ul'
            out.append(f'<{tag}>' + ''.join(f'<li>{inline(x)}</li>' for x in items) + f'</{tag}>'); continue
        if l.strip() == '': flush(); i += 1; continue
        para.append(l.strip()); i += 1
    flush()
    return title, meta, '\n'.join(out)

CSS = '''
:root { --ground:#F4F5F0; --ink:#18202B; --ink-soft:#3A4450; --slate:#5B6672; --rule:#C9CEC4; --panel:#E8EBE5; --accent:#8C2F2F; --accent-ink:#6E2323; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --ground:#14181D; --ink:#E6E8E3; --ink-soft:#C2C7C0; --slate:#98A2AB; --rule:#333B45; --panel:#1D232A; --accent:#D9857F; --accent-ink:#E8A39E; } }
:root[data-theme="dark"] { --ground:#14181D; --ink:#E6E8E3; --ink-soft:#C2C7C0; --slate:#98A2AB; --rule:#333B45; --panel:#1D232A; --accent:#D9857F; --accent-ink:#E8A39E; }
body { background:var(--ground); color:var(--ink); font-family:"Source Serif 4", Georgia, "Times New Roman", serif; font-size:17px; line-height:1.58; margin:0; }
.paper { max-width:68ch; margin:0 auto; padding:56px 24px 96px; }
header.masthead { border-bottom:2px solid var(--accent); padding-bottom:20px; margin-bottom:36px; }
.eyebrow { font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:12px; letter-spacing:.08em; text-transform:uppercase; color:var(--accent); margin:0 0 14px; }
h1 { font-family:Fraunces, "Iowan Old Style", Georgia, serif; font-weight:600; font-size:clamp(30px, 4.6vw, 42px); line-height:1.12; letter-spacing:-.01em; margin:0 0 16px; text-wrap:balance; font-variation-settings:"opsz" 144; }
h1 .sub { font-weight:400; font-size:.62em; line-height:1.25; display:block; margin-top:8px; color:var(--ink-soft); }
.meta { display:flex; flex-wrap:wrap; gap:6px 22px; font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:12.5px; color:var(--slate); }
.meta a { color:var(--slate); }
h2 { font-family:Fraunces, Georgia, serif; font-weight:600; font-size:24px; line-height:1.25; margin:48px 0 14px; text-wrap:balance; display:flex; gap:14px; align-items:baseline; font-variation-settings:"opsz" 72; }
h2 .num { font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:13px; color:var(--accent); letter-spacing:.04em; flex:none; min-width:2.6em; }
h2.abs-h { font-size:13px; font-family:"IBM Plex Mono", ui-monospace, monospace; text-transform:uppercase; letter-spacing:.1em; color:var(--accent); margin-top:0; font-weight:500; }
h2.abs-h + p { font-size:16px; line-height:1.55; color:var(--ink-soft); border-left:3px solid var(--rule); padding-left:16px; }
h3 { font-family:Fraunces, Georgia, serif; font-weight:600; font-size:18.5px; margin:30px 0 8px; text-wrap:balance; }
p { margin:0 0 16px; }
a { color:var(--accent-ink); text-decoration-thickness:1px; text-underline-offset:2px; }
a:focus-visible { outline:2px solid var(--accent); outline-offset:2px; }
code { font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:.86em; color:var(--accent-ink); background:var(--panel); padding:1px 5px; border-radius:3px; }
pre { background:var(--panel); border:1px solid var(--rule); border-radius:4px; padding:14px 16px; overflow-x:auto; font-size:13.5px; line-height:1.5; }
pre code { background:none; color:var(--ink); padding:0; }
ul, ol { padding-left:1.3em; margin:0 0 16px; } li { margin:0 0 6px; }
hr { border:0; border-top:1px solid var(--rule); margin:40px 0; }
.tbl { overflow-x:auto; margin:0 0 20px; border:1px solid var(--rule); border-radius:4px; }
table { border-collapse:collapse; width:100%; font-size:14.5px; font-variant-numeric:tabular-nums; }
th, td { text-align:left; padding:8px 12px; border-bottom:1px solid var(--rule); vertical-align:top; }
th { font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:11.5px; letter-spacing:.06em; text-transform:uppercase; color:var(--slate); background:var(--panel); font-weight:500; }
tr:last-child td { border-bottom:0; } strong { font-weight:600; }
@media (max-width:600px) { body { font-size:16px; } .paper { padding:36px 18px 64px; } }
'''

def main():
    title, meta, body = render(SRC.read_text(encoding='utf-8'))
    head, sub = title.split(':', 1)
    page = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="The Computational Amicus Brief: machine-checked conditional legal argument, with the Federal SAVE Act as a worked example.">
<title>The Computational Amicus Brief</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600;9..144,700&family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,600;1,8..60,400&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>{CSS}</style>
</head>
<body>
<div class="paper">
<header class="masthead">
<p class="eyebrow">White paper · Federal SAVE Act</p>
<h1>{html.escape(head.strip())}<span class="sub">{html.escape(sub.strip())}</span></h1>
<div class="meta">{inline(meta)}</div>
</header>
{body}
</div>
</body>
</html>
'''
    DST.parent.mkdir(parents=True, exist_ok=True)
    DST.write_text(page, encoding='utf-8'); print(f"wrote {DST.relative_to(ROOT)}")

if __name__ == "__main__":
    main()
