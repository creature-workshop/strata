Filed by the nightly fuzz, `test/silt-fuzz.sh`, from the run below. Each case reproduces with `bash test/silt-fuzz.sh --seeds 1 --from <seed>` on its tier (`SILT_THRESHOLD=0` for awk) and reduces by hand into a golden fileset in a directory of its own, `test/fixtures/silt/<name>/`.

