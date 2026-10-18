Copied from https://github.com/nextlevelbuilder/ui-ux-pro-max-skill (.claude/skills/ui-ux-pro-max, v2.15.0)
at commit 56ea9cf174ed86786187daa9de0e6247cb0747e4 (MIT). Its tests and data-maintenance script are left out.
Checked before adding: the scripts use only the Python standard library, make no network calls, run no commands,
and write files only with --persist.

Rules for Jenny (AGENTS.md and DESIGN.md beat this skill):
- Run it from the repo root: python3 .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --domain ux
  (SKILL.md's ${CLAUDE_PLUGIN_ROOT} path is for plugin installs; for this project the path above works).
- Use it for focused lookups: --domain ux / icons / color, and --stack swiftui.
- Don't use --design-system --persist. Jenny's design system is DESIGN.md, so don't create a design-system/ folder.
  If a result disagrees with DESIGN.md (fonts, colors, web units like px), follow DESIGN.md.
- Ignore web-only advice (CSS, Tailwind, GSAP, Google Fonts, React). Jenny is SwiftUI with SF Pro and Dynamic Type.
- Don't edit these files. To update, copy a newer version and change the commit above.
