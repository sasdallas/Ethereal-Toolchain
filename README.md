# Ethereal-Toolchain
Toolchain for developing apps with Ethereal

## Building
**WARNING:** The following commands install the toolchain to your system. If you would like to avoid doing this, simply change DESTDIR.

First setup your environs:
```
export SYSROOT=<SYSROOT>
export ARCH=<ETHEREAL ARCH>
export DESTDIR=<DESTDIR>
```

Install binutils to your host computer with the following commands:
```
mkdir build-binutils
cd build-binutils
../binutils-2.39/configure --target=$ARCH-ethereal --prefix="/usr" --with-sysroot=$SYSROOT --disable-werror
make -j4
sudo make DESTDIR=$DESTDIR install
```

Install GCC to your host computer with the following commands:
```
mkdir build-gcc
cd build-gcc
../build-gcc/configure --target=$ARCH-ethereal --prefix="/usr" --with-sysroot=$SYSROOT --enable-languages=c --disable-multilib
make -j4 all-gcc all-target-libgcc
sudo make DESTDIR=$DESTDIR install-gcc install-target-libgcc
```
