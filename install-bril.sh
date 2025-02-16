#!/usr/bin/env bash

usage() {
    cat <<EOF
Usage: $0 (<directory-to-install-bril>|-h|--help)

Arguments:
  <directory-to-install-bril>       A directory to create the environment in

Options:
  -h, --help                        Show this help message and exit
EOF
    exit 1
}

print_info() {
    cat << EOF
✅ Successfully installed bril
ℹ️  To activate the environment, run: "source $(realpath $DIR/bin/activate --relative-to $OLDPWD)"
ℹ️  To deactivate, run: "deactivate"
EOF
}

die() {
    echo "Installation failed"
    exit 1
}

create_activation_file() {
    cat > bin/activate << 'EOF'
# This file must be used with "source bin/activate" *from bash*
# You cannot run it directly

deactivate () {
    # reset old environment variables
    if [ -n "${_OLD_BRIL_PATH:-}" ] ; then
        PATH="${_OLD_BRIL_PATH:-}"
        export PATH
    fi
    unset _OLD_BRIL_PATH

    # Call hash to forget past commands. Without forgetting
    # past commands the $PATH changes we made may not be respected
    hash -r 2> /dev/null

    if [ -n "${_OLD_BRIL_PS1:-}" ] ; then
        PS1="${_OLD_BRIL_PS1:-}"
        export PS1
    fi
    unset _OLD_BRIL_PS1

    if [ -n "${_OLD_BRIL_UV_TOOL_BIN_DIR:-}" ] ; then
        UV_TOOL_BIN_DIR="${_OLD_BRIL_UV_TOOL_BIN_DIR:-}"
        export UV_TOOL_BIN_DIR
    fi
    unset _OLD_BRIL_UV_TOOL_BIN_DIR

    if [ -n "${_OLD_BRIL_UV_TOOL_DIR:-}" ] ; then
        UV_TOOL_DIR="${_OLD_BRIL_UV_TOOL_DIR:-}"
        export UV_TOOL_DIR
    fi
    unset _OLD_BRIL_UV_TOOL_DIR

    unset _BRIL_ENV
    if [ ! "${1:-}" = "nondestructive" ] ; then
    # Self destruct!
        unset -f deactivate
    fi
}

# unset irrelevant variables
deactivate nondestructive

export _BRIL_ENV="$(dirname $(realpath $0))"

_OLD_BRIL_PATH="$PATH"
PATH="$_BRIL_ENV:$PATH"
export PATH

_OLD_BRIL_PS1="${PS1:-}"
PS1="[bril] ${PS1:-}"
export PS1

_OLD_BRIL_UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-}"
_OLD_BRIL_UV_TOOL_DIR="${UV_TOOL_DIR:-}"
UV_TOOL_BIN_DIR=$_BRIL_ENV
UV_TOOL_DIR="$(dirname $_BRIL_ENV)/uv"
export UV_TOOL_BIN_DIR
export UV_TOOL_DIR

# Call hash to forget past commands. Without forgetting
# past commands the $PATH changes we made may not be respected
hash -r 2> /dev/null
EOF
}


if [[ $# -ne 1 ]]; then
    echo "ERROR: Incorrect number of arguments."
    usage
fi

DIR="$1"

if test $DIR = "-h" || test $DIR = "--help"; then
    usage
fi

if ! command -v deno &>/dev/null; then
    echo "ERROR: deno is not installed."
    exit 1
fi

if ! command -v uv &>/dev/null; then
    echo "ERROR: uv is not installed."
    exit 1
fi

OLDPWD=$PWD
DIR="$(realpath "$DIR")"
mkdir -p "$DIR"
cd "$DIR"
mkdir -p bin
mkdir -p uv
git clone https://github.com/sampsyo/bril bril >/dev/null 2>&1 || die
create_activation_file

# install brili
deno install -g --root $DIR bril/brili.ts >/dev/null 2>&1 || die

# install bril2txt and bril2json
export UV_TOOL_BIN_DIR="$DIR/bin"
export UV_TOOL_DIR="$DIR/uv"
uv tool install bril/bril-txt --force >/dev/null 2>&1 || die

print_info
