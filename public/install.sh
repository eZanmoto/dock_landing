# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# `$0 [--help] [--to <dir>] [--target <target>] [--version <version>]` attempts
# to install the given `<version>` and `<target>` version of the Dock binary to
# `<dir>`.

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
    local default_tgt="$(default_target || true)"
    local default_vsn="$(latest_version "$REPO")"

    local help=
    local dir="$default_dir"
    local version="$default_vsn"
    local target="$default_tgt"
    while [ $# -gt 0 ] ; do
        case "$1" in
            --help)
                help=1
                break
                ;;
            --to)
                dir="$2"
                ;;
            --target)
                target="$2"
                ;;
            --version)
                version="$2"
                ;;
            *)
                break
                ;;
        esac
        shift 2
    done

    if [ -z "$target" ] ; then
        die "A default target couldn't be calculated for your environment.

Please use \`--target\` to provide an explicit target.
"
    fi

    if [ ! -z "$help" -o $# -gt 0 ] ; then
        usage \
            "$0" \
            "$default_dir" \
            "$default_tgt" \
            "$default_vsn"

        local exit_code=0
        if [ -z "$help" ] ; then
            exit_code=1
        fi
        exit "$exit_code"
    fi
    local prog="$0"

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
    local default_tgt="$3"
    local default_vsn="$4"

    echo "usage: $prog [--help] [--to <dir>] [--target <target>] [--version <version>]

Options:
    --help              output help information
    --target <target>   the binary format to install (default: '$default_tgt')
    --to <dir>          the directory to install to (default: '$default_dir')
    --version <version> the version to install (default: '$default_vsn')
" >&2
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

default_target() {
    local machine="$(uname --machine)"
    if [ "$machine" != 'x86_64' ] ; then
        exit 1
    fi

    if [ "$(uname --kernel-name)" != 'Linux' ] ; then
        exit 1
    fi

    echo "${machine}-unknown-linux-musl"
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
