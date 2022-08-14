# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 <version> <target> <dir>` attempts to install the given `<version>` and
# `<target>` version of the Dock binary to `<dir>`.

set -o errexit

PROJ='dock'
REPO="ezanmoto/$PROJ"

main() {
    assert_commands_exist \
        '
            cat
            curl
            grep
            install
            mktemp
            sed
            tar
            trap
        '

    if [ $# -ne 3 ] ; then
        usage "$prog"
    fi

    local prog="$0"
    local version="$1"
    local target="$2"
    local dir="$3"

    local tarball_name="${PROJ}-${version}-${target}.tar.gz"

    version_info=$(
        curl \
                --fail \
                --location \
                --silent \
                "https://api.github.com/repos/$REPO/releases/tags/$version" \
            || die "Couldn't find version '$version' of $PROJ.

You can find a list of available versions on [the GitHub releases page for
Dock](https://github.com/ezanmoto/dock/releases).
"
    )

    tarball_url_line=$(
        echo "$version_info" \
            | grep "browser_download_url" \
            | grep "$tarball_name" \
            || die "Couldn't find target '$target' for $PROJ $version.

You may be able to install 'dock' using
[Rust](https://github.com/eZanmoto/dock), or you can request pre-built binaries
for your platform on [the Dock
project](https://github.com/ezanmoto/dock/issues).
"
    )

    tarball_url=$(
        echo "$tarball_url_line" \
            | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/'
    )

    local tmpd="$(mktemp --directory)"
    trap "rm -rf $tmpd" EXIT

    curl \
            --fail \
            --location \
            --silent \
            "$tarball_url" \
        | tar \
            --extract \
            --gzip \
            --directory "$tmpd" \
        || die "\nCouldn't download release"

    install \
        --mode 755 \
        "$tmpd/$PROJ" \
        "$dir/$PROJ"
}

usage() {
    local prog="$0"

    cat \
        >&2 \
        <<EOF
usage: $prog <version> <target> <dir>
EOF
    exit 1
}

assert_commands_exist() {
    local reqd_cmds="$1"
    for cmd in $reqd_cmds ; do
        if ! command_exists "$cmd" ; then
            die "couldn't find required command '$cmd'"
        fi
    done
}

command_exists() {
    command \
            -v \
            "$@" \
        > /dev/null \
        2>&1
}

die() {
    echo "$@" >&2
    exit 1
}

main "$@"
