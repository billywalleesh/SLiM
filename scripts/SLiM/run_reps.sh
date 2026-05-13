OUTDIR="/c/Users/WilliamWallisch/msc_workspace/SLiM/data/raw"

for N in 100 200 500 1000; do
    echo "Running with N == ${N}"

    "C:/msys64/mingw64/bin/slim.exe" \
        -s 1 \
        -d MU=1e-7 \
        -d R=1e-8 \
        -d N=${N} \
        -d G="N*10" \
        rep.slim > "${OUTDIR}/out_${N}.txt"

    echo
done
