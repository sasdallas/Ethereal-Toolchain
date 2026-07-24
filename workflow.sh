#!/usr/bin/bash

# workflow.sh is a script for the github workflow

set -eu

echo "DO NOT USE THIS IF YOU ARENT THE WORKFLOW!!"
if [ "$#" -ne 2 ]; then
    echo "You arent the workflow!!"
    exit 1
fi

export WORKSPACE=$1
export ARCH=$2
export JOBS=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"


echo "Workspace is ${WORKSPACE}"
echo "Architecture is ${ARCH}"
echo "Building with ${JOBS}"
echo "Script dir is ${SCRIPT_DIR}, repo root is ${REPO_ROOT}"

HOST_PREFIX=${WORKSPACE}/host/
mkdir -p ${HOST_PREFIX}

cd ${WORKSPACE}

# build autoconf and automake
curl -fsSL --retry 3 "https://ftpmirror.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz" -o "autoconf-2.69.tar.gz"
tar -xf autoconf-2.69.tar.gz
rm autoconf-2.69.tar.gz

pushd autoconf-2.69
./configure --prefix=${HOST_PREFIX}
make -j${JOBS}
make install
popd

curl -fsSL --retry 3 "https://ftpmirror.gnu.org/gnu/automake/automake-1.15.1.tar.gz" -o "automake-1.15.1.tar.gz"
tar -xf automake-1.15.1.tar.gz
rm automake-1.15.1.tar.gz

pushd automake-1.15.1
./configure --prefix=${HOST_PREFIX}
make -j${JOBS}
make install
popd

# cleanup
rm -rf automake-1.15.1
rm -rf autoconf-2.69

# done
export PATH=${HOST_PREFIX}/bin:$PATH

# prepare some environs
export AUTOCONF="${HOST_PREFIX}/bin/autoconf"
export AUTOMAKE="${HOST_PREFIX}/bin/automake"
export AUTOM4TE="${HOST_PREFIX}/bin/autom4te"
export PERL5LIB=${HOST_PREFIX}/share/automake-1.15/
export AUTOMAKE_LIBDIR=${HOST_PREFIX}/share/automake-1.15/

# clone Ethereal
git clone https://github.com/sasdallas/Ethereal ${WORKSPACE}/Ethereal
pushd ${WORKSPACE}/Ethereal
git submodule update --init --recursive
sed -i "s/USE_ACPICA = 1/USE_ACPICA = 0/" conf/build/${ARCH}.mk || true 
bash -c "buildscripts/install-headers.sh"
popd

export SYSROOT="${WORKSPACE}/Ethereal/build-output/sysroot/"
export DESTDIR="${WORKSPACE}/toolchain/"
mkdir -p ${DESTDIR}

# Build it!
pushd ${SCRIPT_DIR}
pwd
./build.sh -f
popd

# Compile ethereal
export PATH=${DESTDIR}/usr/bin/:$PATH
x86_64-ethereal-gcc --version

cd ${WORKSPACE}/Ethereal
make all

# Compile stage 2
pushd ${SCRIPT_DIR}
pwd
./build_stage2.sh
popd

# Done
echo Done

# Package into a tarball
tar -cJvf ethereal-${ARCH}-toolchain.tar.gz -C ${WORKSPACE} toolchain

