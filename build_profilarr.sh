#!/usr/bin/env bash
set -e

# --- CONFIG ---
REPO_NAME="profilarr"
ZIP_NAME="profilarr_v2.4_fixed.zip"
MAINTAINER="Kazan2"
DESC="Profilarr v2.4+ database for Radarr and Sonarr featuring balanced, space-saving HEVC/x265 profiles, dual-audio anime support, and TRaSH-Guides naming. Includes exclusion filters for 3D, HDR, French, German, and Extras."

# --- CLEAN ---
rm -rf "$REPO_NAME" "$ZIP_NAME"
mkdir -p "$REPO_NAME"/{custom_formats,profiles,regex_patterns,scripts}

# --- METADATA ---
cat > "$REPO_NAME/metadata.yml" <<EOF
name: Profilarr Database – Austitious Edition
type: database
schemaVersion: 2
maintainer: $MAINTAINER
description: >
  $DESC
applications:
  - radarr
  - sonarr
tags:
  - hevc
  - x265
  - anime
  - profilarr
  - trash-guides
  - space-saving
license: GPL-3.0
EOF

# --- LICENSE ---
wget -q https://www.gnu.org/licenses/gpl-3.0.txt -O "$REPO_NAME/LICENSE"

# --- README ---
cat > "$REPO_NAME/README.yml" <<EOF
name: Profilarr Database – Austitious Edition
description: >
  A public Profilarr v2.4+ repository optimized for space-saving HEVC/x265 encoding and dual-audio anime.
  Includes TRaSH-Guides naming, soft exclusion filters (3D/HDR/French/German/Extras), and balanced profiles
  for Radarr and Sonarr.
EOF

# --- BASIC CUSTOM FORMATS ---
cat > "$REPO_NAME/custom_formats/hevc-x265.yml" <<EOF
name: HEVC / x265
description: Detects x265 or HEVC releases.
specifications:
  - name: x|h265 or HEVC
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '[xh][ ._-]?265|\\bHEVC(\\b|\\d)'
EOF

cat > "$REPO_NAME/custom_formats/10-bit.yml" <<EOF
name: 10-bit
description: Detects 10-bit encodes.
specifications:
  - name: 10-bit flag
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '\\b10[- ]?bit\\b'
EOF

cat > "$REPO_NAME/custom_formats/small-encode-groups.yml" <<EOF
name: Small Encode Groups
description: Trusted small encode groups like PSA or Joy.
specifications:
  - name: Compact groups
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '\\b(PSA|Joy|GalaxyRG|YIFY|Tigole)\\b'
EOF

# --- EXCLUSION CUSTOM FORMATS ---
declare -A EXCLUSIONS=(
  ["no-french"]="French"
  ["no-german"]="German"
  ["no-3d"]="3D"
  ["no-extras"]="Extras"
)
for name in "${!EXCLUSIONS[@]}"; do
cat > "$REPO_NAME/custom_formats/$name.yml" <<EOF
name: No ${EXCLUSIONS[$name]}
description: Deprioritize ${EXCLUSIONS[$name]} releases.
specifications:
  - name: ${EXCLUSIONS[$name]} tag
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '(\\b${EXCLUSIONS[$name]}\\b)'
EOF
done

cat > "$REPO_NAME/custom_formats/no-hdr.yml" <<EOF
name: No HDR
description: Prefer SDR releases instead of HDR for space efficiency.
specifications:
  - name: HDR tag
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '(\\bHDR10?\\b|\\bDolby[ ._-]?Vision\\b|\\bDV\\b)'
EOF

# --- DUAL AUDIO FORMATS ---
cat > "$REPO_NAME/custom_formats/dual-audio.yml" <<EOF
name: Dual Audio
description: Detects English+Japanese or Multi Audio releases.
specifications:
  - name: Dual audio keywords
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '(Dual[ ._-]?Audio|Eng\\+Jpn|Multi[ ._-]?Audio)'
EOF

cat > "$REPO_NAME/custom_formats/softsubs-preferred.yml" <<EOF
name: Softsubs Preferred
description: Detects softsubbed releases (ASS/SUB).
specifications:
  - name: Softsub tags
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '(Softsub|ASS|Subbed)'
EOF

cat > "$REPO_NAME/custom_formats/avoid-x264.yml" <<EOF
name: Avoid x264
description: Filters out x264 encodes in favor of x265.
specifications:
  - name: x264 tag
    implementation: ReleaseTitleSpecification
    negate: false
    required: true
    fields:
      value: '\\bx264\\b'
EOF

# --- PROFILES ---
cat > "$REPO_NAME/profiles/1080p-hevc-space-saver.yml" <<'EOF'
name: 1080p HEVC (Space Saver)
description: >
  Balanced 1080p HEVC/x265 Radarr profile optimized for space savings with fallback to 720p/480p.
tags: [hevc, x265, radarr]
upgradesAllowed: true
minCustomFormatScore: 0
upgradeUntilScore: 60
minScoreIncrement: 10
custom_formats:
  - { name: HEVC / x265, score: 50 }
  - { name: 10-bit, score: 20 }
  - { name: Small Encode Groups, score: 25 }
  - { name: Avoid x264, score: -50 }
  - { name: No HDR, score: -10 }
  - { name: No French, score: -100 }
  - { name: No German, score: -100 }
  - { name: No 3D, score: -100 }
  - { name: No Extras, score: -100 }
qualities:
  - { id: 6, name: Bluray-1080p }
  - { id: 5, name: WEBDL-1080p }
  - { id: 4, name: WEBRip-1080p }
  - { id: 3, name: Bluray-720p }
  - { id: 2, name: WEBDL-720p }
  - { id: 0, name: WEBDL-480p }
upgrade_until:
  id: 6
  name: Bluray-1080p
language: English
EOF

cat > "$REPO_NAME/profiles/anime-1080p-dual-audio.yml" <<'EOF'
name: Anime 1080p Dual Audio (HEVC)
description: >
  Dual-audio 1080p anime profile optimized for HEVC/x265 encodes with Multi (Eng+Jpn) language.
tags: [anime, hevc, dual-audio, sonarr]
upgradesAllowed: true
minCustomFormatScore: 0
upgradeUntilScore: 70
minScoreIncrement: 10
custom_formats:
  - { name: HEVC / x265, score: 50 }
  - { name: 10-bit, score: 20 }
  - { name: Dual Audio, score: 100 }
  - { name: Softsubs Preferred, score: 10 }
  - { name: Avoid x264, score: -50 }
  - { name: No French, score: -100 }
  - { name: No German, score: -100 }
  - { name: No 3D, score: -100 }
  - { name: No Extras, score: -100 }
  - { name: No HDR, score: -10 }
qualities:
  - { id: 6, name: Bluray-1080p }
  - { id: 5, name: WEBDL-1080p }
  - { id: 4, name: WEBRip-1080p }
  - { id: 3, name: Bluray-720p }
  - { id: 2, name: WEBDL-720p }
  - { id: 0, name: WEBDL-480p }
upgrade_until:
  id: 6
  name: Bluray-1080p
language: Multi (Eng+Jpn)
EOF

# --- REGEX ---
cat > "$REPO_NAME/regex_patterns/anime-dual-audio.yml" <<EOF
name: Anime Dual Audio
description: Detects Eng+Jpn or Dual Audio releases.
patterns:
  include:
    - '(Dual[ ._-]?Audio|Eng\\+Jpn|Multi[ ._-]?Audio)'
EOF

cat > "$REPO_NAME/regex_patterns/exclusions.yml" <<EOF
name: Exclusions
description: Negative filters for unwanted tags.
patterns:
  exclude:
    - '(3D|French|German|Extras|HDR)'
EOF

# --- SCRIPT ---
cat > "$REPO_NAME/scripts/sync-profilarr.yml" <<EOF
name: Sync Profilarr Repository
description: Use Profilarr's built-in sync or API call to refresh this database.
steps:
  - name: Sync
    run: echo "Use Profilarr UI or API to sync Austitious Edition."
EOF

# --- ZIP ---
cd "$REPO_NAME"
zip -rq "../$ZIP_NAME" .
cd ..
echo "✅ Profilarr v2.4+ Austitious Edition built successfully: $ZIP_NAME"
