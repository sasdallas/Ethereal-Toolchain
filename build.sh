#!/bin/sh

set -e

if [[ -z "${SYSROOT}" ]]; then
	echo "ERROR: Please set \$SYSROOT before running this script."
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
	export BINUTILS_VERSION=2.39
fi

if [[ -z "${DESTDIR}" ]]; then
	echo "WARNING: Assuming destination directory is /"
	export DESTDIR=/
	NEED_AUTH_INSTALL=1
else
	NEED_AUTH_INSTALL=0
fi


echo "SYSTEM ROOT: ${SYSROOT}"
echo "ARCHITECTURE: ${ARCH}"
echo "PREFIX: ${PREFIX}"
echo "INSTALL DIR: ${DESTDIR}"
echo "GCC TARGET VERSION: ${GCC_VERSION}"
echo "BINUTILS TARGET VERSION: ${BINUTILS_VERSION}"

if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
        echo "AUTH: Required"
else
        echo "AUTH: Unnecessary"
fi

echo "=============================================================="

read -p "Does everything above look good? [Y/N] " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 1
fi


echo -e "\nOkay, everything looks good - building now.\n\n"

if test -d "build-binutils"; then
	echo "Clearing old build data (binutils)"
	rm binutils-${BINUTILS_VERSION}.tar.gz
	rm -rf binutils-${BINUTILS_VERSION}
	rm -rf build-binutils
fi

if test -d "build-gcc"; then
	echo "Clearing old build data (GCC)"
	rm -rf gcc-${GCC_VERSION}.tar.gz
	rm -rf gcc-${GCC_VERSION}
	rm -rf build-gcc
fi

# First, do binutils
echo "Downloading binutils"
wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz
tar -xf binutils-${BINUTILS_VERSION}.tar.gz
cd binutils-${BINUTILS_VERSION}

echo "Applying patch"
patch -p1 < ../binutils-${BINUTILS_VERSION}.patch
cd ..


# Build binutils
echo "Starting build of binutils"
mkdir build-binutils
cd build-binutils

../binutils-${BINUTILS_VERSION}/configure --target=${ARCH}-ethereal --prefix=$PREFIX --disable-werror --with-sysroot=$SYSROOT
make -j4 all

if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
	sudo make DESTDIR=${DESTDIR} install
else
	make DESTDIR=${DESTDIR} install
fi

echo "Binutils built and installed successfully"

# Do GCC
echo "Downloading GCC"
wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}.tar.gz
tar -xf gcc-${GCC_VERSION}.tar.gz

# Apply patch
echo "Applying GCC patch"
cd gcc-${GCC_VERSION}
patch -p1 < ../gcc-${GCC_VERSION}.patch
cd ..
echo "Patch applied successfully

# Build GCC
echo "Starting build of GCC"
mkdir build-gcc
cd build-gcc
../gcc-${GCC_VERSION}/configure --target=${ARCH}-ethereal --prefix=${PREFIX} --with-sysroot=$SYSROOT --disable-multilib --enable-languages=c
make -j4 all-gcc all-target-libgcc

# Install GCC
if [[ "$NEED_AUTH_INSTALL" -eq 1 ]]; then
        sudo make DESTDIR=${DESTDIR} install-gcc install-target-libgcc
else
        make DESTDIR=${DESTDIR} install-gcc install-target-libgcc
fi
