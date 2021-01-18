#!/bin/bash

set -e
mkdir -p /build/sysroot

apt-get install -y curl
export TARGET=arm-none-eabi
export PREFIX=/build/sysroot
export PATH=$PATH:$PREFIX/bin
export CFLAGS_FOR_TARGET="-mtune=cortex-m0plus -mno-unaligned-access"
export CXXFLAGS_FOR_TARGET="-mtune=cortex-m0plus -mno-unaligned-acces"
export LDFLAGS_FOR_TARGET="-mtune=cortex-m0plus -mno-unaligned-access"

THREADS=${THREADS:-$(lscpu | sed -rne 's/^CPU\(s\):\s*([0-9]+)/\1/p;')}

curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz
tar -xvf binutils-2.35.tar.xz
mkdir build-binutils
pushd build-binutils
../binutils-2.35/configure --target=$TARGET --prefix=$PREFIX
make -j$THREADS all
make -j$THREADS install
popd

curl -O https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz
tar -xvf gcc-10.2.0.tar.xz
./gcc-10.2.0/contrib/download_prerequisites
mkdir build-gcc-stage1
pushd build-gcc-stage1
../gcc-10.2.0/configure --target=$TARGET --prefix=$PREFIX --without-headers \
                        --with-newlib --with-gnu-as --with-gnu-ld \
                        --disable-multilib
make -j$THREADS all-gcc
make -j$THREADS install-gcc
popd


git clone git://sourceware.org/git/newlib-cygwin.git /build/newlib
mkdir build-newlib
pushd build-newlib
../newlib/configure --target=$TARGET --prefix=$PREFIX --disable-multilib \
                    --enable-target-optspace
make -j$THREADS all
make -j$THREADS install
popd

mkdir build-gcc-stage2
pushd build-gcc-stage2
../gcc-10.2.0/configure --target=$TARGET --prefix=$PREFIX --with-newlib \
                        --with-gnu-as --with-gnu-ld --disable-shared \
                        --disable-libssp --disable-multilib
make -j$THREADS all
make -j$THREADS install
popd

curl -O https://ftp.gnu.org/gnu/gdb/gdb-9.2.tar.xz
tar -xvf gdb-9.2.tar.xz
mkdir build-gdb
pushd build-gdb
../gdb-9.2/configure --target=$TARGET --prefix=$PREFIX
make -j$THREADS all
make -j$THREADS install
popd
