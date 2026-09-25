#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Two-panel climate figure: the gradient the demes sit on, and the warming.
# Plain scientific styling - frame, grey ramp, stepped colour bars.
#
#   python scripts/GMT/prep_climate_grids.py      # once, to build the grids
#   bash   scripts/GMT/map_climate_gradient.sh
#
# Requires GMT >= 6 with DCW + GSHHG, and Ghostscript.
# ---------------------------------------------------------------------------
set -euo pipefail
ROOT="${MSC_WORKSPACE:-$HOME/msc_workspace}"; SLIM="$ROOT/SLiM"
GRD="$SLIM/data/processed"; OUT="$SLIM/results/figures"; mkdir -p "$OUT"
LOCS="$SLIM/input/grib_pop_index_local_adaptation/population_locations/grib_population_locations_4pop_swiss_plateau.csv"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
awk -F, 'NR>1 {print $3, $4}' "$LOCS" > "$TMP/sites.txt"

R=-R6/10.5/46/47.75
J=-JM8c

gmt begin "$OUT/climate_gradient" png,pdf
  gmt set FONT_ANNOT_PRIMARY 8p,Helvetica,black FONT_LABEL 9p,Helvetica,black \
          MAP_FRAME_TYPE plain MAP_FRAME_PEN 0.6p,black MAP_TICK_LENGTH_PRIMARY 2p

  gmt subplot begin 1x2 -Fs8c/5.2c -M0.4c/1.6c -A"a)"+jTL+o0.15c

    gmt subplot set 0
      gmt makecpt -Cgray -T2/15/1 -I -H > "$TMP/t.cpt"
      gmt grdimage "$GRD/t2m_norm.nc" -C"$TMP/t.cpt" $R $J -nn
      gmt coast $R $J -Df -ECH+p0.8p,black
      gmt basemap $R $J -Bxa1f0.5 -Bya0.5f0.25 -BWSne
      for i in 1 2 3 4; do awk -v n=$i 'NR==n' "$TMP/sites.txt" \
        | gmt plot $R $J -Sc0.16c -Gblack -W0.6p,white; done
      echo "6.1432 46.2044 Geneva"     | gmt text $R $J -F+f7p,Helvetica,black+jML -D0.18c/0c
      echo "7.4474 46.9479 Bern"       | gmt text $R $J -F+f7p,Helvetica,black+jTC -D0c/-0.18c
      echo "8.5417 47.3769 Zurich"     | gmt text $R $J -F+f7p,Helvetica,black+jTC -D0c/-0.18c
      echo "9.3767 47.4245 St. Gallen" | gmt text $R $J -F+f7p,Helvetica,black+jBC -D0c/0.18c
      gmt colorbar -C"$TMP/t.cpt" -DJBC+w6.5c/0.28c+h+o0/1.0c \
        -Bxa2f1+l"Mean annual 2 m temperature, 1991-2020 (@.C)"

    gmt subplot set 1
      gmt makecpt -Cgray -T1.4/2.3/0.1 -I -H > "$TMP/d.cpt"
      gmt grdimage "$GRD/t2m_change.nc" -C"$TMP/d.cpt" $R $J -nn
      gmt coast $R $J -Df -ECH+p0.8p,black
      gmt basemap $R $J -Bxa1f0.5 -Bya0.5f0.25 -BWSne
      for i in 1 2 3 4; do awk -v n=$i 'NR==n' "$TMP/sites.txt" \
        | gmt plot $R $J -Sc0.16c -Gblack -W0.6p,white; done
      gmt colorbar -C"$TMP/d.cpt" -DJBC+w6.5c/0.28c+h+o0/1.0c \
        -Bxa0.2f0.1+l"Warming, 1996-2025 minus 1940-1969 (@.C)"

  gmt subplot end
gmt end
echo "wrote $OUT/climate_gradient.png (and .pdf)"
