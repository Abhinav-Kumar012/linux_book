#!/usr/bin/env bash
#
# build.sh - Convert the Linux Handbook from Markdown to HTML + PDF
#
# Usage:
#   ./build.sh          # build both HTML and PDF
#   ./build.sh html     # build HTML only
#   ./build.sh pdf      # build PDF only
#   ./build.sh clean    # remove build artifacts
#
# Requirements:
#   - pandoc (>= 2.18)
#   - xelatex (texlive-xetex, texlive-fonts-recommended, texlive-plain-generic)
#
# Install on Debian/Ubuntu:
#   sudo apt-get install -y pandoc texlive-xetex texlive-fonts-recommended texlive-plain-generic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="build"
HTML_DIR="$BUILD_DIR/html"
PDF_FILE="$BUILD_DIR/linux-handbook.pdf"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}>${NC} $*"; }
ok()    { echo -e "${GREEN}OK${NC} $*"; }
err()   { echo -e "${RED}ERR${NC} $*" >&2; }

check_deps() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        err "Missing dependencies: ${missing[*]}"
        err "Install with: sudo apt-get install -y pandoc texlive-xetex texlive-fonts-recommended texlive-plain-generic"
        exit 1
    fi
}

gather_chapters() {
    local -a files=()

    for part_dir in \
        part1-history part2-installation part3-shell part4-commands \
        part5-filesystems part6-process part7-memory part8-kernel \
        part9-syscalls part10-networking part11-security part12-containers \
        part13-ebpf part14-drivers part15-boot part16-elf \
        part17-debugging part18-performance part19-source-walkthrough \
        part20-programming
    do
        if [[ -d "$part_dir" ]]; then
            for f in "$part_dir"/*.md; do
                [[ -f "$f" ]] && files+=("$f")
            done
        fi
    done

    if [[ -d "appendices" ]]; then
        for f in appendices/*.md; do
            [[ -f "$f" ]] && files+=("$f")
        done
    fi

    printf '%s\n' "${files[@]}"
}

build_html() {
    check_deps pandoc

    info "Building HTML site..."
    mkdir -p "$HTML_DIR"/{css,js}

    # CSS
    cat > "$HTML_DIR/css/style.css" << 'CSSEOF'
:root {
    --bg: #fdfdfd; --fg: #1a1a1a; --accent: #d63384;
    --link: #0969da; --code-bg: #f6f8fa; --border: #d0d7de;
    --sidebar-w: 300px;
    --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    --font-mono: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
}
@media (prefers-color-scheme: dark) {
    :root { --bg: #0d1117; --fg: #c9d1d9; --accent: #f778ba; --link: #58a6ff; --code-bg: #161b22; --border: #30363d; }
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { scroll-behavior: smooth; }
body { font-family: var(--font-sans); font-size: 16px; line-height: 1.7; color: var(--fg); background: var(--bg); }
.page-wrapper { display: flex; min-height: 100vh; }
.sidebar { width: var(--sidebar-w); background: var(--code-bg); border-right: 1px solid var(--border); position: fixed; top: 0; left: 0; bottom: 0; overflow-y: auto; padding: 1rem 0; z-index: 100; transition: transform 0.25s ease; }
.sidebar-header { padding: 0.5rem 1rem 1rem; font-weight: 700; font-size: 1.1rem; border-bottom: 1px solid var(--border); margin-bottom: 0.5rem; }
.sidebar ul { list-style: none; }
.sidebar a { display: block; padding: 0.25rem 1rem; color: var(--fg); text-decoration: none; font-size: 0.85rem; border-left: 3px solid transparent; transition: all 0.15s; }
.sidebar a:hover, .sidebar a.active { background: var(--bg); color: var(--link); border-left-color: var(--accent); }
.sidebar .part-heading { font-weight: 600; font-size: 0.9rem; padding: 0.75rem 1rem 0.25rem; color: var(--accent); text-transform: uppercase; letter-spacing: 0.05em; }
.sidebar-toggle { display: none; position: fixed; top: 0.75rem; left: 0.75rem; z-index: 200; background: var(--accent); color: #fff; border: none; border-radius: 6px; padding: 0.5rem 0.75rem; font-size: 1.25rem; cursor: pointer; }
.content { margin-left: var(--sidebar-w); flex: 1; max-width: 52rem; padding: 2rem 3rem 4rem; }
.content h1 { font-size: 2rem; font-weight: 800; margin: 2rem 0 1rem; padding-bottom: 0.3rem; border-bottom: 2px solid var(--accent); }
.content h2 { font-size: 1.5rem; font-weight: 700; margin: 2.5rem 0 0.75rem; color: var(--accent); }
.content h3 { font-size: 1.2rem; font-weight: 600; margin: 2rem 0 0.5rem; }
.content h4, .content h5, .content h6 { font-size: 1rem; font-weight: 600; margin: 1.5rem 0 0.5rem; }
.content p { margin-bottom: 1rem; }
.content a { color: var(--link); text-decoration: none; border-bottom: 1px solid transparent; }
.content a:hover { border-bottom-color: var(--link); }
code { font-family: var(--font-mono); font-size: 0.875em; background: var(--code-bg); padding: 0.15em 0.4em; border-radius: 4px; }
pre { background: var(--code-bg); border: 1px solid var(--border); border-radius: 8px; padding: 1rem 1.25rem; overflow-x: auto; margin-bottom: 1.5rem; font-size: 0.85rem; line-height: 1.6; }
pre code { background: none; padding: 0; border-radius: 0; font-size: inherit; }
table { width: 100%; border-collapse: collapse; margin-bottom: 1.5rem; font-size: 0.9rem; }
th, td { padding: 0.5rem 0.75rem; border: 1px solid var(--border); text-align: left; }
th { background: var(--code-bg); font-weight: 600; }
tr:hover { background: var(--code-bg); }
ul, ol { margin: 0 0 1rem 1.5rem; }
li { margin-bottom: 0.25rem; }
blockquote { border-left: 4px solid var(--accent); padding: 0.5rem 1rem; margin: 0 0 1rem; background: var(--code-bg); border-radius: 0 6px 6px 0; }
blockquote p { margin-bottom: 0; }
.mermaid { text-align: center; margin: 1.5rem 0; background: #fff; padding: 1rem; border-radius: 8px; border: 1px solid var(--border); }
@media (prefers-color-scheme: dark) { .mermaid { background: #161b22; } }
.scroll-top { position: fixed; bottom: 2rem; right: 2rem; background: var(--accent); color: #fff; border: none; border-radius: 50%; width: 44px; height: 44px; font-size: 1.25rem; cursor: pointer; opacity: 0; transition: opacity 0.2s; z-index: 50; }
.scroll-top.visible { opacity: 1; }
@media print { .sidebar, .sidebar-toggle, .scroll-top { display: none; } .content { margin-left: 0; max-width: 100%; } a { color: var(--fg); } pre { page-break-inside: avoid; } }
@media (max-width: 900px) { .sidebar { transform: translateX(-100%); } .sidebar.open { transform: translateX(0); } .sidebar-toggle { display: block; } .content { margin-left: 0; padding: 1rem; } }
CSSEOF

    # JavaScript
    cat > "$HTML_DIR/js/main.js" << 'JSEOF'
document.addEventListener('DOMContentLoaded', () => {
    const sidebar = document.querySelector('.sidebar');
    const toggle = document.querySelector('.sidebar-toggle');
    if (toggle && sidebar) {
        toggle.addEventListener('click', () => sidebar.classList.toggle('open'));
        document.querySelector('.content').addEventListener('click', () => sidebar.classList.remove('open'));
    }
    const tocLinks = document.querySelectorAll('.sidebar a[href^="#"]');
    const observer = new IntersectionObserver(entries => {
        entries.forEach(e => {
            if (e.isIntersecting) {
                tocLinks.forEach(l => l.classList.remove('active'));
                const link = document.querySelector('.sidebar a[href="#' + e.target.id + '"]');
                if (link) link.classList.add('active');
            }
        });
    }, { rootMargin: '-20% 0px -75% 0px' });
    document.querySelectorAll('.content h1[id], .content h2[id]').forEach(h => observer.observe(h));
    const btn = document.querySelector('.scroll-top');
    if (btn) {
        window.addEventListener('scroll', () => btn.classList.toggle('visible', window.scrollY > 500));
        btn.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
    }
    if (typeof mermaid !== 'undefined') {
        mermaid.initialize({ startOnLoad: true, theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default' });
    }
});
JSEOF

    # Gather chapters
    local -a chapters
    mapfile -t chapters < <(gather_chapters)

    if [[ ${#chapters[@]} -eq 0 ]]; then
        err "No markdown files found!"
        exit 1
    fi
    info "Found ${#chapters[@]} markdown files"

    # Extract TOC from README.md
    info "Generating table of contents..."
    local toc_html=""
    local current_part=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+(Part[[:space:]]+[0-9]+.*)$ ]]; then
            current_part="${BASH_REMATCH[1]}"
            toc_html+="<div class=\"part-heading\">${current_part}</div><ul>"
        elif [[ "$line" =~ ^##[[:space:]]+(Appendices) ]]; then
            current_part="${BASH_REMATCH[1]}"
            toc_html+="<div class=\"part-heading\">${current_part}</div><ul>"
        elif [[ "$line" =~ ^-\ Chapter\ ([0-9]+):\ (.*)$ ]]; then
            local ch_num="${BASH_REMATCH[1]}"
            local ch_title="${BASH_REMATCH[2]}"
            toc_html+="<li><a href=\"#ch${ch_num}\">${ch_title}</a></li>"
        elif [[ "$line" =~ ^-\ Appendix\ ([A-Z]):\ (.*)$ ]]; then
            local app_letter="${BASH_REMATCH[1]}"
            local app_title="${BASH_REMATCH[2]}"
            local anchor
            anchor=$(echo "$app_letter" | tr 'A-Z' 'a-z')
            toc_html+="<li><a href=\"#appendix-${anchor}\">${app_title}</a></li>"
        fi
    done < README.md

    # Build combined markdown
    info "Combining markdown files..."
    local combined="$BUILD_DIR/combined.md"
    : > "$combined"

    local ch_num=0
    for f in "${chapters[@]}"; do
        ch_num=$((ch_num + 1))
        echo "" >> "$combined"
        sed -E '1s/^# (.+)$/# <a id="ch'"$ch_num"'">\1<\/a>/' "$f" >> "$combined"
        printf '\n\n\\newpage\n\n' >> "$combined"
    done

    # Run pandoc
    info "Running pandoc -> HTML..."

    local header_file="$BUILD_DIR/_header.html"
    local before_file="$BUILD_DIR/_before.html"
    local after_file="$BUILD_DIR/_after.html"

    cat > "$header_file" << 'HEOF'
<meta name="viewport" content="width=device-width, initial-scale=1.0">
HEOF

    cat > "$before_file" << BEOF
<button class="sidebar-toggle" aria-label="Toggle navigation">&#9776;</button>
<nav class="sidebar">
  <div class="sidebar-header">The Comprehensive Linux Handbook</div>
  ${toc_html}
</nav>
<div class="page-wrapper"><div class="content">
BEOF

    cat > "$after_file" << 'AEOF'
</div></div>
<button class="scroll-top" aria-label="Scroll to top">&#8593;</button>
<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
<script src="js/main.js"></script>
AEOF

    pandoc "$combined" \
        --from markdown \
        --to html5 \
        --standalone \
        --toc \
        --toc-depth=2 \
        --highlight-style=tango \
        --metadata title="The Comprehensive Linux Handbook" \
        --css css/style.css \
        --include-in-header="$header_file" \
        --include-before-body="$before_file" \
        --include-after-body="$after_file" \
        --output "$HTML_DIR/index.html"

    ok "HTML built -> $HTML_DIR/index.html"

    # Per-chapter HTML
    info "Building per-chapter HTML files..."
    mkdir -p "$HTML_DIR/chapters"
    ch_num=0
    for f in "${chapters[@]}"; do
        ch_num=$((ch_num + 1))
        local basename
        basename=$(basename "$f" .md)
        pandoc "$f" \
            --from markdown \
            --to html5 \
            --standalone \
            --highlight-style=tango \
            --css ../css/style.css \
            --include-in-header=<(echo '<meta name="viewport" content="width=device-width, initial-scale=1.0"><link rel="stylesheet" href="../css/style.css">') \
            --include-before-body=<(echo '<div class="content"><a href="../index.html" style="font-size:0.9rem">&larr; Back to index</a>') \
            --include-after-body=<(echo '</div><script src="../js/main.js"></script>') \
            --output "$HTML_DIR/chapters/${basename}.html" \
            2>/dev/null || true
    done
    ok "Per-chapter HTML built in $HTML_DIR/chapters/"

    # Clean temp files
    rm -f "$header_file" "$before_file" "$after_file"
}

build_pdf() {
    check_deps pandoc xelatex

    info "Building PDF..."
    mkdir -p "$BUILD_DIR"

    local -a chapters
    mapfile -t chapters < <(gather_chapters)

    if [[ ${#chapters[@]} -eq 0 ]]; then
        err "No markdown files found!"
        exit 1
    fi

    local combined="$BUILD_DIR/combined.md"
    if [[ ! -f "$combined" ]]; then
        : > "$combined"
        for f in "${chapters[@]}"; do
            cat "$f" >> "$combined"
            printf '\n\n\\newpage\n\n' >> "$combined"
        done
    fi

    pandoc "$combined" \
        --from markdown \
        --to pdf \
        --pdf-engine=xelatex \
        --toc \
        --toc-depth=2 \
        --highlight-style=tango \
        --variable geometry:margin=1in \
        --variable fontsize=11pt \
        --variable documentclass=report \
        --variable papersize=a4 \
        --variable colorlinks=true \
        --variable linkcolor=blue \
        --variable urlcolor=blue \
        --metadata title="The Comprehensive Linux Handbook" \
        --metadata author="Generated with pandoc" \
        --output "$PDF_FILE"

    ok "PDF built -> $PDF_FILE ($(du -h "$PDF_FILE" | cut -f1))"
}

clean() {
    info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    ok "Done"
}

case "${1:-all}" in
    html)  build_html ;;
    pdf)   build_pdf ;;
    clean) clean ;;
    all)
        build_html
        build_pdf
        echo ""
        ok "Build complete!"
        echo -e "  HTML: ${BOLD}$HTML_DIR/index.html${NC}"
        echo -e "  PDF:  ${BOLD}$PDF_FILE${NC}"
        ;;
    *)
        err "Usage: $0 [html|pdf|clean|all]"
        exit 1
        ;;
esac
