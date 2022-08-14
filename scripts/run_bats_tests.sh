# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 [--no-caching] [tests]` runs the Bats tests defined in `scripts/test`.

set -o errexit

while [ $# -gt 0 ] ; do
    case "$1" in
        --no-caching)
            disable_curl_caching=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# -gt 1 ] ; then
    echo "usage: $0 [--no-caching] [tests]" >&2
    exit 1
fi

bats_filter=
if [ $# -gt 0 ] ; then
    bats_filter="$1"
fi

proj_dir="$PWD"
tgt_dir="$proj_dir/target"
tgt_gen_dir="$tgt_dir/gen/bats_tests"
tgt_scratch_dir="$tgt_dir/scratch/bats_tests"

mkdir \
    --parents \
    "$tgt_gen_dir"

rm \
    --force \
    --recursive \
    "$tgt_scratch_dir"

mkdir \
    --parents \
    "$tgt_scratch_dir"

if [ -z "$bats_filter" ] ; then
    DISABLE_CURL_CACHING="$disable_curl_caching" \
        SCRIPTS_DIR="$proj_dir/scripts" \
        TEST_GEN_DIR="$tgt_gen_dir" \
        TEST_SCRATCH_DIR="$tgt_scratch_dir" \
            npx bats 'scripts/test'
else
    DISABLE_CURL_CACHING="$disable_curl_caching" \
        SCRIPTS_DIR="$proj_dir/scripts" \
        TEST_GEN_DIR="$tgt_gen_dir" \
        TEST_SCRATCH_DIR="$tgt_scratch_dir" \
            npx bats 'scripts/test' \
                --filter "$bats_filter"
fi
