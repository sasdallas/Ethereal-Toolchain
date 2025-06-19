# Ethereal-Toolchain
Toolchain for developing apps with Ethereal

## Building
**WARNING:** The following commands install the toolchain to your system. You can use `DESTDIR` to change install dir.

Install binutils to your host computer with the following commands:
```
mkdir build-binutils
cd build-binutils
../binutils-2.39/configure --target=<ARCH>-ethereal --prefix="/usr" --with-sysroot=<SYSROOT> --disable-werror
make -j4
sudo make install
```

Install GCC to your host computer with the following commands:
```
mkdir build-gcc
cd build-gcc
../build-gcc/configure --target=<ARCH>-ethereal --prefix="/usr" --with-sysroot=<SYSROOT> --enable-languages=c --disable-multilib
make all-gcc all-target-libgcc
sudo make install-gcc install-target-libgcc
```
