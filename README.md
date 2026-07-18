# Ethereal-Toolchain

Toolchain for developing with the Ethereal Operating System.

## Current versions

- GCC 14.2.0
- Binutils 2.42

## Preparations

**WARNING:** The following commands install the toolchain to your system. If you would like to avoid doing this, simply change DESTDIR.

First setup your environs:
```
export SYSROOT=<SYSROOT>
export ARCH=<ETHEREAL ARCH>
export DESTDIR=<DESTDIR>
```

Prepare a system root by cloning Ethereal. You can then use the `make install-headers` target to install the system headers.\
Once you have done this, your `SYSROOT` will be in `<ethereal root>/build-output/sysroot/`.

## Building (automatic)

Automatic building is easy. There are two scripts: `build.sh` and `build_stage2.sh`

Run `build.sh` and it will compile and install the first part of the toolchain.\
You need to have an Ethereal installation that has already ran `make install-headers`.

Then, go back to Ethereal and run `make all` to compile the OS.

Now that you have done that, you can run `build_stage2.sh` and compile the libstdc++-v3 runtime.\
This isn't necessary to build the OS but is necessary to build all the ports.

## Building (manual)

Install binutils to your host computer with the following commands:

```
mkdir build-binutils
cd build-binutils
../binutils-2.42/configure --target=$ARCH-ethereal --prefix="/usr" --with-sysroot=$SYSROOT --disable-werror --enable-default-execstack=no
make -j4
sudo make DESTDIR=$DESTDIR install
```

**You must have $DESTDIR/usr/bin/ in your path before compiling GCC!**

Install GCC to your host computer with the following commands:

```
mkdir build-gcc
cd build-gcc
../gcc-12.2.0/configure --target=$ARCH-ethereal --prefix=/usr --with-sysroot=$SYSROOT  --enable-languages=c,c++ --disable-multilib --enable-threads=posix --disable-multilib --enable-shared --enable-host-shared --with-pic
make -j4 all-gcc all-target-libgcc
sudo make DESTDIR=$DESTDIR install-gcc install-target-libgcc
```

Now you can compile Ethereal! Do that by running `make all`

After you have installed the mlibc runtime, build libstdc++ with the following commands:

```
cd build-gcc
make -j4 all-target-libstdc++-v3
sudo make DESTDIR=$DESTDIR install-target-libstdc++-v3
```
