FROM debian:9.13

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
 && apt-get install -y build-essential git curl texinfo vim-nox \
 && mkdir /build

WORKDIR /build/

ENV TARGET=arm-none-eabi
ENV PREFIX=/build/sysroot
ENV PATH="$PATH:$PREFIX/bin"
ENV common_flags="-mtune=cortex-m0plus -mcpu=cortex-m0plus -mno-unaligned-access -mthumb -mlong-calls"
ENV CFLAGS_FOR_TARGET=$common_flags
ENV CXXFLAGS_FOR_TARGET=$common_flags
ENV LDFLAGS_FOR_TARGET=$common_flags
ENV THREADS=20

# Binutils
RUN curl -O https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz \
 && tar -xvf binutils-2.35.tar.xz \
 && mkdir build-binutils \
 && cd build-binutils \
 && ../binutils-2.35/configure --target=$TARGET --prefix=$PREFIX \
 && make -j$THREADS all \
 && make -j$THREADS install

# GCC stage 1
RUN curl -O https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz \
 && tar -xvf gcc-10.2.0.tar.xz \
 && cd ./gcc-10.2.0 \
 && ./contrib/download_prerequisites \
 && mkdir ../build-gcc-stage1 \
 && cd ../build-gcc-stage1 \
 && ../gcc-10.2.0/configure --target=$TARGET --prefix=$PREFIX \
      --without-headers --with-newlib --with-gnu-as --with-gnu-ld \
      --disable-multilib \
 && make -j$THREADS all-gcc \
 && make -j$THREADS install-gcc

# Newlib
ENV LDFLAGS_FOR_TARGET="$common_flags --specs=nospecs.sys"
RUN git clone git://sourceware.org/git/newlib-cygwin.git /build/newlib \
 && mkdir build-newlib \
 && cd build-newlib \
 && ../newlib/configure --target=$TARGET --prefix=$PREFIX --disable-multilib \
                        --enable-target-optspace --disable-newlib-supplied-syscalls \
 && make -j$THREADS all \
 && make -j$THREADS install

# GCC stage 2
RUN mkdir build-gcc-stage2 \
 && cd build-gcc-stage2 \
 && ../gcc-10.2.0/configure --target=$TARGET --prefix=$PREFIX --with-newlib \
                          --with-gnu-as --with-gnu-ld --disable-shared \
                          --disable-libssp --disable-multilib \
			  --enable-languages=c,c++ \
 && make -j$THREADS all \
 && make -j$THREADS install

# GDB
RUN curl -O https://ftp.gnu.org/gnu/gdb/gdb-9.2.tar.xz \
 && tar -xvf gdb-9.2.tar.xz \
 && mkdir build-gdb \
 && cd build-gdb \
 && ../gdb-9.2/configure --target=$TARGET --prefix=$PREFIX \
 && make -j$THREADS all \
 && make -j$THREADS install

ADD BoxLock_Firmware .
