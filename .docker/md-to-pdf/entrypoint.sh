#!/bin/sh

set -e

pandoc CV.md \
  -o CV.pdf \
  --lua-filter=/custom_tags.lua \
  --lua-filter=/link_styles.lua \
  --lua-filter=/header_styles.lua \
  --pdf-engine=xelatex \
  -V pagestyle=empty \
  -V geometry:left=1.4cm \
  -V geometry:right=1.4cm \
  -V geometry:top=1.4cm \
  -V geometry:bottom=1cm \
  -V fontsize=10pt \
  -V mainfont="Noto Sans" \
  -V sansfont="Noto Sans" \
  -V monofont="Noto Sans Mono" \
  -V header-includes="\usepackage{xcolor}" \
  -V header-includes="\color[HTML]{1A1A1A}" \
  -V header-includes="\linespread{1.07}" \
  -V header-includes="\hyphenpenalty=10000" \
  -V header-includes="\exhyphenpenalty=10000" \
  -V header-includes="\usepackage{enumitem}" \
  -V header-includes="\setlist[itemize,1]{label=\textbullet}" \
  -V header-includes="\setlist[itemize,2]{label=\textbullet}" \
  -V header-includes="\setlist[itemize,3]{label=\textbullet}" \
  -V header-includes="\AtBeginDocument{\raggedright\sloppy}"
