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
	export GCC_VERSION=14.2.0
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

# Check arguments
FORCE=0
for arg in "$@"; do
    if [[ "$arg" == "-f" || "$arg" == "--force" ]]; then
        FORCE=1
        break
    fi
done

echo "SYSTEM ROOT: ${SYSROOT}"
echo "BUILD SYSTEM ROOT: ${BUILD_SYSROOT}"
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

if [[ "$FORCE" -eq 1 ]]; then
    echo "Forced build"
else
    read -p "Does everything above look good? [Y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 1
    fi
fi

echo -e "\nOkay, everything looks good - building now.\n\n"

source "$(dirname "${BASH_SOURCE[0]}")/autotools.sh"

if test -d "build-binutils"; then
	echo "Clearing old build data (binutils)"
	rm binutils-${BINUTILS_VERSION}.tar.gz || true
	rm -rf binutils-${BINUTILS_VERSION} || true
	rm -rf build-binutils || true
fi

if test -d "build-gcc"; then
	echo "Clearing old build data (GCC)"
	rm -rf gcc-${GCC_VERSION}.tar.gz || true
	rm -rf gcc-${GCC_VERSION} || true
	rm -rf build-gcc || true
fi

# First, do binutils
echo "Downloading binutils"
wget https://ftpmirror.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz
tar -xf binutils-${BINUTILS_VERSION}.tar.gz
cd binutils-${BINUTILS_VERSION}

echo "Applying patch"
patch -p1 < ../binutils-${BINUTILS_VERSION}.patch
cd ..

# Patch binutils
echo "Patching binutils"
cd binutils-${BINUTILS_VERSION}/ld
automake
cd ../..


# Build binutils
echo "Starting build of binutils"
mkdir build-binutils
cd build-binutils

../binutils-${BINUTILS_VERSION}/configure --target=${ARCH}-ethereal --prefix=$PREFIX --disable-werror --with-sysroot=$SYSROOT --enable-default-execstack=no
make -j${JOBS} all

if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
	sudo make DESTDIR=${DESTDIR} install
else
	make DESTDIR=${DESTDIR} install
fi

# This is needed
export PATH=${DESTDIR}/usr/bin/:$PATH

echo "Binutils built and installed successfully"
cd ..

# Do GCC
echo "Downloading GCC"
wget https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz
tar -xf gcc-${GCC_VERSION}.tar.gz

# Apply patch
echo "Applying GCC patch"
cd gcc-${GCC_VERSION}
patch -p1 < ../gcc-${GCC_VERSION}.patch
cd ..
echo "Patch applied successfully"

# Reconfigure libstdc++-v3
echo "Reconfiguring libstdc++-v3"
cd gcc-${GCC_VERSION}/libstdc++-v3
autoconf
cd ../..
echo "Reconfigured libstdc++-v3"

# Build GCC
echo "Starting build of GCC"
mkdir build-gcc
cd build-gcc
../gcc-${GCC_VERSION}/configure --target=${ARCH}-ethereal --prefix=$PREFIX --with-sysroot=$SYSROOT --enable-languages=c,c++ --disable-multilib --enable-threads=posix --disable-multilib --enable-shared --enable-host-shared --with-pic
make -j4 all-gcc all-target-libgcc

# Install GCC
if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
        sudo make DESTDIR=${DESTDIR} install-gcc install-target-libgcc
else
        make DESTDIR=${DESTDIR} install-gcc install-target-libgcc
fi
