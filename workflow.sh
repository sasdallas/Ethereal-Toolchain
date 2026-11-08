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

mkdir -p "${WORKSPACE}"
cd "${WORKSPACE}"

# clone Ethereal
git clone https://github.com/sasdallas/Ethereal "${WORKSPACE}/Ethereal"
pushd "${WORKSPACE}/Ethereal"
git submodule update --init --recursive
sed -i "s/USE_ACPICA = 1/USE_ACPICA = 0/" conf/build/${ARCH}.mk || true 
bash -c "buildscripts/install-headers.sh"
popd

export SYSROOT="${WORKSPACE}/Ethereal/build-output/sysroot/"
export DESTDIR="${WORKSPACE}/toolchain/"
export TOOLCHAIN_SYSROOT="/usr/${ARCH}-ethereal/sys-root"
mkdir -p "${DESTDIR}"

# Build it!
pushd "${SCRIPT_DIR}"
pwd
./build.sh -f
popd

# Compile ethereal
export PATH="${DESTDIR}/usr/bin/:${PATH}"
"${ARCH}-ethereal-gcc" --version

cd "${WORKSPACE}/Ethereal"
make build

# Compile stage 2
pushd "${SCRIPT_DIR}"
pwd
./build_stage2.sh -f
popd

echo Done

