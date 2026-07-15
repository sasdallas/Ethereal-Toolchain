#!/usr/bin/bash

set -e

if [[ -z "${SYSROOT}" ]]; then
	echo "ERROR: Please set \$SYSROOT before running this script."
	echo "SYSROOT is the system root of the cloned Ethereal installation."
	echo "Clone Ethereal, run make install-headers, and your sysroot is in build-output/sysroot"
	exit 1
fi

if [[ -z "${ARCH}" ]]; then
	echo "ERROR: Please set \$ARCH before running this script."
	exit 1
fi

if [[ -z "${PREFIX}" ]]; then
	echo "WARNING: Assuming prefix is /usr"
	export PREFIX=/usr
fi

if [[ -z "${GCC_VERSION}" ]]; then
	export GCC_VERSION=12.2.0
fi

if [[ -z "${BINUTILS_VERSION}" ]]; then
	export BINUTILS_VERSION=2.42
fi

if [[ -z "${DESTDIR}" ]]; then
	echo "WARNING: Assuming destination directory is /"
	export DESTDIR=/
	NEED_AUTH_INSTALL=1
else
	NEED_AUTH_INSTALL=0
fi

if [[ -z "${JOBS}" ]]; then
	export JOBS=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)
fi


if ! test -d "build-gcc"; then
    echo "You haven't built GCC yet, or the build-gcc directory is missing."
    exit 1
fi

echo "SYSTEM ROOT: ${SYSROOT}"
echo "ARCHITECTURE: ${ARCH}"
echo "PREFIX: ${PREFIX}"
echo "INSTALL DIR: ${DESTDIR}"
echo "GCC TARGET VERSION: ${GCC_VERSION}"
echo "BINUTILS TARGET VERSION: ${BINUTILS_VERSION}"
echo "JOBS: ${JOBS}"

if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
        echo "AUTH: Required"
else
        echo "AUTH: Unnecessary"
fi

set -u

echo "=============================================================="

read -p "Does everything above look good? [Y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
fi

cd build-gcc
make -j${JOBS} all-target-libstdc++-v3

if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
        sudo make DESTDIR=${DESTDIR} install-target-libstdc++-v3
else
        make DESTDIR=${DESTDIR} install-target-libstdc++-v3
fi

