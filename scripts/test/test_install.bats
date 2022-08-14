# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

# TODO Split this file into success tests and failure tests.

setup_file() {
    bats_require_minimum_version 1.5.0

    if [ -z "$SCRIPTS_DIR" ] ; then
        echo "'\$SCRIPTS_DIR' isn't set" >&2
        exit 1
    fi

    if [ -z "$TEST_GEN_DIR" ] ; then
        echo "'\$TEST_GEN_DIR' isn't set" >&2
        exit 1
    fi

    if [ -z "$TEST_SCRATCH_DIR" ] ; then
        echo "'\$TEST_SCRATCH_DIR' isn't set" >&2
        exit 1
    fi

    export CACHING_BIN_DIR="$TEST_GEN_DIR/caching_bin"
    mkdir \
        --parents \
        "$CACHING_BIN_DIR"

    local curl_cache_dir="$TEST_GEN_DIR/curl_cache"
    mkdir \
        --parents \
        "$curl_cache_dir"

    gen_caching_curl_bin \
        "$SCRIPTS_DIR/caching.sh" \
        "$curl_cache_dir" \
        "$CACHING_BIN_DIR/curl"
}

gen_caching_curl_bin() {
    local caching_script="$1"
    local cache_dir="$2"
    local target="$3"

    echo "
        #!/usr/bin/env sh

        sh '$caching_script' \\
            /usr/bin/curl \\
            '$curl_cache_dir' \\
            \"\$@\"
    " \
        | unindent '        ' \
        > "$target"

    chmod \
        +x \
        "$target"
}

unindent() {
    local prefix="$1"

    sed \
        --expression='1d' \
        --expression='$d' \
        --expression="s/^$prefix//"
}

setup() {
    local target_test_dir="$TEST_SCRATCH_DIR/$BATS_TEST_NAME"
    mkdir "$target_test_dir"

    local test_dir="$(dirname "$BATS_TEST_FILENAME")"
    INSTALL_SH="$SCRIPTS_DIR/install.sh"

    PROJ='dock'
    VERSION='0.35.5'
    TARGET='x86_64-unknown-linux-musl'
    DIR="$target_test_dir"

    if [ -z "$DISABLE_CURL_CACHING" ] ; then
        PATH="$CACHING_BIN_DIR:$PATH"
    fi
}

# Given (1) an empty test directory `<dir>`
# When `<dir>/<proj> --version` is run
# Then (A) the command is unsuccessful
@test "command isn't in <dir>" {
    # (1)

    run \
        -127 \
        "$DIR/$PROJ" \
            --version

    # (A)
    assert_status 127
}

# When the install script is run with valid arguments
# Then (A) the command is successful
#     AND (B) the output is empty
@test "install command to <dir>" {
    run /bin/sh "$INSTALL_SH" \
        "$VERSION" \
        "$TARGET" \
        "$DIR"

    # (A)
    assert_status 0
    # (B)
    assert_output ''
}

assert_status() {
    local exp_status="$1"

    if [ "$status" -ne "$exp_status" ] ; then
        fail "Unexpected status code; expected $exp_status, got $status"
    fi
}

fail() {
    local msg="$1"

    echo
    echo -e "$msg"
    echo
    echo 'Output:'
    echo
    echo "$output" \
        | sed 's/^/[~] /'

    exit 1
}

assert_output() {
    local exp_output="$1"

    if [ "$output" != "$exp_output" ] ; then
        expectation="$(
            echo "$exp_output" \
                | sed 's/^/[~] /'
        )"

        fail "Unexpected output; expected:\n\n$expectation"
    fi
}

# Given (1) PATH is empty
# When the install script is run
# Then (A) the command is unsuccessful
#     AND (B) the output indicates that a required command couldn't be found
@test "missing dependencies" {
    # (1)
    local path=

    PATH="$path" run /bin/sh "$INSTALL_SH"

    # (A)
    assert_status 1
    # (B)
    assert_partial_output "couldn't find required command"
}

assert_partial_output() {
    local exp_output="$1"

    if ! echo "$output" | grep "$exp_output" ; then
        fail "Unexpected output; expected to match '$exp_output'"
    fi
}

# Given (1) an empty test directory `<dir>`
#     AND (2) the install script is run
# When `<dir>/<proj> --version` is run
# Then (A) the command is successful
#     AND (B) the output indicates that a required command couldn't be found
@test "command is installed correctly" {
    # (1)
    # (2)
    /bin/sh "$INSTALL_SH" \
        "$VERSION" \
        "$TARGET" \
        "$DIR"

    run "$DIR/$PROJ" --version

    # (A)
    assert_status 0
    # (B)
    assert_output "$PROJ $VERSION"
}

# When the install script is run with an invalid version
# Then (A) the command is unsuccessful
#     AND (B) the output indicates that a required command couldn't be found
@test "invalid version" {
    run /bin/sh "$INSTALL_SH" \
        'bad_version' \
        "$TARGET" \
        "$DIR"

    # (A)
    assert_status 1
    # (B)
    assert_partial_output "Couldn't find version 'bad_version'"
}

# When the install script is run with an invalid target
# Then (A) the command is unsuccessful
#     AND (B) the output indicates that the target couldn't be found
@test "invalid target" {
    run /bin/sh "$INSTALL_SH" \
        "$VERSION" \
        'bad_target' \
        "$DIR"

    # (A)
    assert_status 1
    # (B)
    assert_partial_output "Couldn't find target 'bad_target'"
}

# When the install script is run with a nonexistent directory
# Then (A) the command is unsuccessful
#     AND (B) the output indicates that the directory doesn't exist
@test "invalid dir" {
    run /bin/sh "$INSTALL_SH" \
        "$VERSION" \
        "$TARGET" \
        "$DIR/nonexistent"

    # (A)
    assert_status 1
    # (B)
    assert_partial_output 'install: cannot create .*: No such file or directory'
}

# Given (1) a file is created at `<dir>`
# When the install script is run with `<dir>`
# Then (A) the command is unsuccessful
#     AND (B) the output indicates that the directory doesn't exist
@test "<dir> is a file" {
    dir="$DIR/dummy"
    # (1)
    touch "$dir"

    run /bin/sh "$INSTALL_SH" \
        "$VERSION" \
        "$TARGET" \
        "$dir"

    # (A)
    assert_status 1
    # (B)
    assert_partial_output 'install: .*: Not a directory'
}
