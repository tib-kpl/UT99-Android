# Project maintenance

- Develop both menu variants together on `master`: `classic` uses the original
  UT99 menu, `normal` uses the console/phone menu. Engine and compatibility fixes
  must apply to both; do not maintain separate menu branches.
- Keep one regular GitHub release per master build, containing both signed APKs.
- Run `tools/check_menu_variants.py` on the two unsigned release APKs before
  publication. Native libraries, assets, resources and manifest must match.
- Do not add Co-authored-by trailers or other co-author attribution to commits.
