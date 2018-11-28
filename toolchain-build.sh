#!/bin/bash
mkdir -v build
cd build

#binutils
echo binutils-2.31.1
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
echo END binutils-2.31.1
#END-binutils

#GCC
echo GCC
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
#END-GCC

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
mkdir -b build
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

