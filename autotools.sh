#!/usr/bin/env bash
# buildenv fix for stupidity

AUTOTOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOTOOLS_CACHE_DIR="${AUTOTOOLS_DIR}/.autotools/"

# get the autotools versios
autotool_version() {
    local first_line
    first_line=$("$1" --version 2>/dev/null | head -n 1) || return 1
    printf '%s\n' "${first_line##* }"
}

install_autotool() (
    set -e
    unset DESTDIR
    local tool="$1" version="$2" prefix="$3" archive workdir
    archive="${tool}-${version}.tar.gz"
    workdir=$(mktemp -d "${TMPDIR:-/tmp}/ethereal-autotools.XXXXXXXX")
    trap 'rm -rf -- "$workdir"' EXIT

    echo "Installing ${tool} ${version} in ${prefix}"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 "https://ftpmirror.gnu.org/gnu/${tool}/${archive}" -o "${workdir}/${archive}"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "${workdir}/${archive}" "https://ftpmirror.gnu.org/gnu/${tool}/${archive}"
    else
        echo "ERROR: curl or wget is needed to download ${tool}." >&2
        exit 1
    fi

    tar -xf "${workdir}/${archive}" -C "$workdir"
    cd "${workdir}/${tool}-${version}"
    ./configure --prefix="$prefix"
    make -j"${JOBS:-1}"
    make install
)

ensure_autotool() {
    local tool="$1" version="$2" prefix="$3" selected="" candidate=""
    if candidate=$(command -v "$tool" 2>/dev/null) && \
       [[ "$(autotool_version "$candidate")" == "$version" ]]; then
        selected="$candidate"
    elif [[ "$(autotool_version "${prefix}/bin/${tool}")" == "$version" ]]; then
        selected="${prefix}/bin/${tool}"
    else
        install_autotool "$tool" "$version" "$prefix"
        selected="${prefix}/bin/${tool}"
        if [[ "$(autotool_version "$selected")" != "$version" ]]; then
            echo "ERROR: ${tool} ${version} was not installed correctly." >&2
            return 1
        fi
    fi

    PATH="$(dirname "$selected"):${PATH}"
    export PATH
    printf 'using %s %s (%s)\n' "$tool" "$version" "$selected"
    case "$tool" in
        autoconf)
            export AUTOCONF="$selected"
            export AUTOM4TE="$(dirname "$selected")/autom4te"
            ;;
        automake)
            export AUTOMAKE="$selected"
            export ACLOCAL="$(dirname "$selected")/aclocal"
            ;;
    esac
}

ensure_autotool autoconf 2.69 "${AUTOTOOLS_CACHE_DIR}/autoconf-2.69"
ensure_autotool automake 1.15.1 "${AUTOTOOLS_CACHE_DIR}/automake-1.15.1"
