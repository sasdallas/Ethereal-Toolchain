#!/usr/bin/env bash
# packages into dpkg and tar.zst

set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "usage: $0 WORKSPACE ARCH VERSION OUTPUT_DIR" >&2
    exit 2
fi

WORKDIR=$1
ARCH=$2
VERSION=$3
OUTDIR=$4
TARGET="${ARCH}-ethereal"
STAGE="${WORKDIR}/toolchain"
SYSROOT="${WORKDIR}/Ethereal/build-output/sysroot"
SDK="${STAGE}/usr/${TARGET}/sys-root"

for path in usr/include usr/lib lib usr/share/pkgconfig; do
    if [[ -d "${SYSROOT}/${path}" ]]; then
        mkdir -p "${SDK}/${path}"
        cp -a "${SYSROOT}/${path}/." "${SDK}/${path}/"
    fi
done

# make our pkg-config
cat > "${STAGE}/usr/bin/${TARGET}-pkg-config" <<EOF
#!/bin/sh
SYSROOT=\${ETHEREAL_SYSROOT:-/usr/${TARGET}/sys-root}
export PKG_CONFIG_SYSROOT_DIR="\$SYSROOT"
export PKG_CONFIG_LIBDIR="\$SYSROOT/usr/lib/pkgconfig:\$SYSROOT/usr/share/pkgconfig"
unset PKG_CONFIG_PATH
exec pkg-config "\$@"
EOF
chmod 755 "${STAGE}/usr/bin/${TARGET}-pkg-config"

# build some docs
doc="${STAGE}/usr/share/doc/ethereal-toolchain-${ARCH//_/-}"
mkdir -p "$doc" "${STAGE}/DEBIAN" "$OUTDIR"
git -C "${WORKDIR}/Ethereal" rev-parse HEAD > "${doc}/ethereal-commit"

cat > "${STAGE}/DEBIAN/control" <<EOF
Package: ethereal-toolchain-${ARCH//_/-}
VERSION: ${VERSION}
ARCHitecture: amd64
Maintainer: Ethereal Toolchain contributors <noreply@github.com>
Depends: libc6, libstdc++6, libgmp10, libmpfr6, libmpc3, zlib1g, pkg-config
Description: Cross compiler and SDK for Ethereal ${ARCH}
EOF

stem="ethereal-toolchain-${TARGET}-linux-amd64_${VERSION}"
dpkg-deb --build --root-owner-group "$STAGE" "${OUTDIR}/${stem}.deb"
tar --zstd -cf "${OUTDIR}/${stem}.tar.zst" -C "$STAGE" usr
(
    cd "$OUTDIR"
    sha256sum "${stem}.deb" "${stem}.tar.zst" > SHA256SUMS
)
