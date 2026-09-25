#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Map of the four Swiss Plateau demes with migration links, drawn in GMT 6.
#
# Usage:   bash map_4pop_migration.sh [weak|strong|decay]
# Output:  results/figures/map_4pop_migration_<treatment>.{png,pdf}
#
# Requires: GMT >= 6, with the DCW and GSHHG datasets and Ghostscript.
#   Ubuntu/Debian : sudo apt install gmt gmt-dcw gmt-gshhg ghostscript
#   conda         : conda install -c conda-forge gmt
#   Windows       : official installer from generic-mapping-tools.org,
#                   then run this from Git Bash
# ---------------------------------------------------------------------------
set -euo pipefail

TREAT="${1:-strong}"                       # weak | strong | decay
ROOT="${MSC_WORKSPACE:-$HOME/msc_workspace}"
SLIM="$ROOT/SLiM"
IN="$SLIM/input/grib_pop_index_local_adaptation"
OUT="$SLIM/results/figures"
mkdir -p "$OUT"

LOCS="$IN/population_locations/grib_population_locations_4pop_swiss_plateau.csv"
MIG="$IN/migration_matrix/grib_migration_matrix_4pop_${TREAT}.csv"
[ -f "$LOCS" ] || { echo "missing: $LOCS" >&2; exit 1; }
[ -f "$MIG"  ] || { echo "missing: $MIG"  >&2; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# sites.txt : lon lat   (population order p0..p3 is fixed project-wide)
awk -F, 'NR>1 {print $3, $4}' "$LOCS" > "$TMP/sites.txt"

# links.txt : one multi-segment entry per unordered pair, rate in the header
awk -F, -v S="$TMP/sites.txt" '
  BEGIN { n=0; while ((getline line < S) > 0) { split(line,a," "); lon[++n]=a[1]; lat[n]=a[2] } }
  { for (j=1; j<=NF; j++) m[NR,j]=$j }
  END { for (i=1;i<=n;i++) for (j=i+1;j<=n;j++)
          printf "> rate=%s\n%s %s\n%s %s\n", m[i,j], lon[i], lat[i], lon[j], lat[j] }
' "$MIG" > "$TMP/links.txt"

R=-R5.70/10.65/45.75/47.95
J=-JT8.22/46.85/17c

gmt begin "$OUT/map_4pop_migration_${TREAT}" png,pdf
  gmt set FONT_ANNOT_PRIMARY 11p,Helvetica,60/60/60 MAP_TICK_LENGTH_PRIMARY 0p

  # Neighbours for context - uncomment if you want them. Off is cleaner.
  # gmt coast $R $J -Df -EFR,DE,IT,AT,LI+ggray94

  gmt coast $R $J -Df -ECH+gwhite+p1.1p,120/120/120
  gmt plot "$TMP/links.txt" $R $J -W0.7p,180/180/180

  awk 'NR==1' "$TMP/sites.txt" | gmt plot $R $J -Sc0.50c -G42/120/214 -W2p,white
  awk 'NR==2' "$TMP/sites.txt" | gmt plot $R $J -Sc0.50c -G235/104/52 -W2p,white
  awk 'NR==3' "$TMP/sites.txt" | gmt plot $R $J -Sc0.50c -G27/175/122 -W2p,white
  awk 'NR==4' "$TMP/sites.txt" | gmt plot $R $J -Sc0.50c -G237/161/0  -W2p,white

  # Labels. -j sets which corner of the text sits at the point; -D nudges it.
  echo "6.1432 46.2044 Geneva"     | gmt text $R $J -F+f17p,Helvetica-Bold,black+jML -D0.42c/0c
  echo "7.4474 46.9479 Bern"       | gmt text $R $J -F+f17p,Helvetica-Bold,black+jTC -D0c/-0.42c
  echo "8.5417 47.3769 Zurich"     | gmt text $R $J -F+f17p,Helvetica-Bold,black+jBC -D0c/0.42c
  echo "9.3767 47.4245 St. Gallen" | gmt text $R $J -F+f17p,Helvetica-Bold,black+jBL -D0.42c/0.12c

  gmt basemap $R $J -Lg9.75/45.95+w50k+f+u -B+n
gmt end

echo "wrote $OUT/map_4pop_migration_${TREAT}.png (and .pdf)"
awk -F, 'NR==1 {printf "link rate (%s): %s per generation\n", "'"$TREAT"'", $2}' "$MIG"
