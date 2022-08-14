# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 <prog> <cache-dir> [param*]` runs a new invocation of `<prog> [param*]` if
# a cached version of such a set of parameters isn't available, otherwise the
# cached STDOUT is output and the cached exit code is returned.

set -o errexit

if [ $# -lt 2 ] ; then
    echo "usage: $0 <prog> <cache-dir> [param*]" >&2
    exit 1
fi

prog="$1"
cache_dir="$2"

shift 2

fname="$(urlencode "$*").cache"
fpath="$cache_dir/$fname"

if [ ! -f "$fpath" ] ; then
    tmpf="$fpath.swp"

    # We create an empty line at the top of the temporary file that'll be
    # replaced by the exit code later.
    echo '' \
        > "$tmpf"

    # We disable `errexit` for the next command so that we can capture its
    # exit code even if it failed.
    set +o errexit

    "$prog" "$@" \
        >> "$tmpf"

    exit_code="$?"

    set -o errexit

    sed \
        --in-place \
        "1 s/^/$exit_code/" \
        "$tmpf"

    mv \
        "$tmpf" \
        "$fpath"
fi

# We use `sed` to output all lines but the first, as the first line contains the
# cached exit code.
sed \
    '1d' \
    "$fpath"

exit_code="$(
    head \
        -1 \
        "$fpath"
)"

exit "$exit_code"
