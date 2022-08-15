# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 [--to <dir>] [--version <version>] <target>` attempts to install the given
# `<version>` and `<target>` version of the Dock binary to `<dir>`.

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
            tar
            trap
        '

    local default_dir='/usr/local/bin'
    local default_vsn="$(latest_version "$REPO")"

    if [ $# -lt 1 ] ; then
        usage \
            "$0" \
            "$default_dir" \
            "$default_vsn"
    fi

    local dir="$default_dir"
    local version="$default_vsn"
    while [ $# -gt 1 ] ; do
        case "$1" in
            --to)
                dir="$2"
                ;;
            --version)
                version="$2"
                ;;
            *)
                usage \
                    "$0" \
                    "$default_dir" \
                    "$default_vsn"
                ;;
        esac
        shift 2
    done

    local prog="$0"
    local target="$1"

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
            | extract_json_string browser_download_url
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
    local prog="$1"
    local default_dir="$2"
    local default_vsn="$3"

    cat \
        >&2 \
        <<EOF
usage: $prog [--to <dir>] [--version <version>] <target>

Options:
    --to <dir>          the directory to install to (default: '$default_dir')
    --version <version> the version to install (default: '$default_vsn')
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

extract_json_string() {
    local field="$1"

    grep "\"$field\": " \
        | cut \
            --delimiter='"' \
            --fields=4
}

latest_version() {
    local repo="$1"

    curl \
            --fail \
            --silent \
            "https://api.github.com/repos/$repo/releases/latest" \
        | extract_json_string tag_name
}

main "$@"
