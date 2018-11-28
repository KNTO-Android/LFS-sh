#!/bin/bash
mkdir -v build
cd build

#binutils 1
xz -dc  $LFS/sources/binutils-2.31.1.tar.xz | tar xfv -
cd binutils-2.31.1
mkdir -v build
cd build
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make -j6
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
make install
#END-binutils 1

#GCC 1
cd ../../
tar -xf $LFS/sources/gcc-8.2.0.tar.xz
cd gcc-8.2.0
tar -xf $LFS/sources/mpfr-4.0.1.tar.xz
mv -v mpfr-4.0.1 mpfr
tar -xf $LFS/sources/gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf $LFS/sources/mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc
for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
mkdir -v build
cd       build
../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
make -j6
make install
#END-GCC 1

#kernel headers install
cd ../../
tar -xf $LFS/sources/linux-4.18.5.tar.xz
cd linux-4.18.5
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include
#END-kernel headers install

#glibc
cd ../
tar -xf $LFS/sources/glibc-2.28.tar.xz
cd glibc-2.28
mkdir -v build
cd build
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2             \
      --with-headers=/tools/include      \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes
make -j6
make install

echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
rm -v dummy.c a.out
#END-glibc

#Libstdc++
cd ../../
cd gcc-8.2.0
rm -rf build
mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0
make -j6
make install
#END-Libstdc++

#binutils 2
cd ../../
cd binutils-2.31.1
rm -rf build
mkdir -v build
cd       build
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make -j6
make install
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin
#END-binutils 2

#GCC 2
cd ../../
cd gcc-8.2.0
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
rm -rf build
mkdir -v build
cd       build
CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
make -j6
make install
ln -sv gcc /tools/bin/cc
echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
rm -v dummy.c a.out
#END-GCC 2

#tcl
cd ../../
tar -zxvf $LFS/sources/tcl8.6.8-src.tar.gz
cd tcl8.6.8
cd unix
./configure --prefix=/tools
make -j6
TZ=UTC make test
make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh
#END-tcl8

#Expect
cd ../../
tar -jxvf $LFS/sources/expat-2.2.6.tar.bz2
cd expat-2.2.6
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make -j6
make test
make SCRIPTS="" install
#END-Expect

#DejaGNU
cd ../
tar -zxvf $LFS/sources/dejagnu-1.6.1.tar.gz
cd dejagnu-1.6.1
./configure --prefix=/tools
make install
make check
#END-DejaGNU

#m4
cd ../
tar -xf $LFS/sources/m4-1.4.18.tar.xz
cd m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/tools
make -j6
make check
make install
#END-m4

#Ncurses
cd ../
tar -zxvf $LFS/sources/ncurses-6.1.tar.gz
cd ncurses-6.1
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make -j6
make install
#END-Ncurses

#bash
cd ../
tar -zxvf $LFS/sources/bash-4.4.18.tar.gz
cd bash-4.4.18
./configure --prefix=/tools --without-bash-malloc
make -j6
make tests
make install
ln -sv bash /tools/bin/sh
#END-bash

#bison
cd ../
tar -zxvf $LFS/sources/bash-4.4.18.tar.gz
cd bash-4.4.18
./configure --prefix=/tools
make -j6
make check
make install
#END-bison

#bzip2
cd ../
tar -zxvf $LFS/sources/bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
make -j6
make PREFIX=/tools install
#END-bzip2

#coreutils
cd ../
tar tar -xf $LFS/sources/coreutils-8.30.tar.xz
cd coreutils-8.30
./configure --prefix=/tools --enable-install-program=hostname
make -j6
make RUN_EXPENSIVE_TESTS=yes check
make install
#END-coreutils

#diffutils
cd ../
tar tar -xf $LFS/sources/diffutils-3.6.tar.xz
cd diffutils-3.6
./configure --prefix=/tools
make -j6
make install
#END-diffutils

#file
cd ../
tar -zxvf $LFS/sources/file-5.34.tar.gz
cd file-5.34
./configure --prefix=/tools
make -j6
make install
#END-file

#findutils
cd ../
tar -zxvf $LFS/sources/findutils-4.6.0.tar.gz
cd findutils-4.6.0
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
./configure --prefix=/tools
make -j6
make install
#END-findutils

#gawk
cd ../
tar tar -xf $LFS/sources/gawk-4.2.1.tar.xz
cd gawk-4.2.1
./configure --prefix=/tools
make -j6
make install
#END-gawk

#gettext
cd ../
tar tar -xf $LFS/sources/gettext-0.19.8.1.tar.xz
cd gettext-0.19.8.1
cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
#END-gettext

#grep
cd ../../
tar tar -xf $LFS/sources/grep-3.1.tar.xz
cd grep-3.1
./configure --prefix=/tools
make -j6
make install
#END-grep

#gzip
cd ../
tar tar -xf $LFS/sources/gzip-1.9.tar.xz
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/tools
make -j6
make install
#END-gzip
