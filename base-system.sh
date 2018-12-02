#!/bin/bash
mkdir -p /sources/slogs
cd /sources

#linux headers
tar -xf /sources/linux-4.18.5.tar.xz
cd linux-4.18.5
make mrproper
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
cd /sources
rm -rf linux-4.18.5
#END-linux headers

#man-pages
tar -xf /sources/man-pages-4.16.tar.xz
cd man-pages-4.16
make install
cd /sources
rm -rf man-pages-4.16
#END-man-pages

#glibc
touch /sources/slogs/001-glibc.log
tar -xf /sources/glibc-2.28.tar.xz
cd glibc-2.28
patch -Np1 -i /sources/glibc-2.28-fhs-1.patch
ln -sfv /tools/lib/gcc /usr/lib
case $(uname -m) in
    i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
            ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac
rm -f /usr/include/limits.h
mkdir -v build
cd       build
CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             libc_cv_slibdir=/lib
unset GCC_INCDIR
make -j8
make check > /sources/slogs/001-glibc.log
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service
make localedata/install-locales
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
cd /sources
mkdir tzdata2018e
cd tzdata2018e
tar -xf /sources/tzdata2018e.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
ln -sfv /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
cd /sources
rm -rf glibc-2.28
#END-glibc

#toolchain setting
touch /sources/slogs/002-toolchain.log
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib' > /sources/slogs/002-toolchain.log
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log >> /sources/slogs/002-toolchain.log
grep -B1 '^ /usr/include' dummy.log >> /sources/slogs/002-toolchain.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g' >> /sources/slogs/002-toolchain.log
grep "/lib.*/libc.so.6 " dummy.log >> /sources/slogs/002-toolchain.log
grep found dummy.log >> /sources/slogs/002-toolchain.log
rm -v dummy.c a.out dummy.log
cd /sources
#END-toolchain setting

#zlib
touch /sources/slogs/003-zlib.log
tar -xf /sources/zlib-1.2.11.tar.xz
cd zlib-1.2.11
./configure --prefix=/usr
make -j8
make check > /sources/slogs/003-zlib.log
make install
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
cd /sources
rm -rf zlib-1.2.11
#END-zlib

#file
touch /sources/slogs/004-file.log
tar -zxvf /sources/file-5.34.tar.gz
cd file-5.34
./configure --prefix=/usr
make -j8
make check > /sources/slogs/004-file.log
make install
cd /sources
rm -rf file-5.34
#END-file

#readline
tar -zxvf /sources/readline-7.0.tar.gz
cd readline-7.0
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-7.0
make SHLIB_LIBS="-L/tools/lib -lncursesw"
make SHLIB_LIBS="-L/tools/lib -lncurses" install
mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0
cd /sources
rm -rf readline-7.0
#END-readline

#m4
touch /sources/slogs/005-m4.log
tar -xf /sources/m4-1.4.18.tar.xz
cd m4-1.4.18
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make -j8
make check > /sources/slogs/005-m4.log
make install
cd /sources
rm -rf m4-1.4.18
#END-m4

#bc
touch /sources/slogs/006-bc.log
tar -zxvf /sources/bc-1.07.1.tar.gz
cd bc-1.07.1
cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
EOF
ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
ln -sfv libncurses.so.6 /usr/lib/libncurses.so
sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure
./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
make -j8
echo "quit" | ./bc/bc -l Test/checklib.b > /sources/slogs/006-bc.log
make install
cd /sources
rm -rf bc-1.07.1
#END-bc

#binutils
touch /sources/slogs/007-binutils.log
tar -xf /sources/binutils-2.31.1.tar.xz
cd binutils-2.31.1
mkdir -v build
cd       build
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib
make tooldir=/usr
make -k check > /sources/slogs/007-binutils.log
make tooldir=/usr install
cd /sources
rm -rf binutils-2.31.1
#END-binutils

#gmp
touch /sources/slogs/008-gmp.log
tar -xf /sources/gmp-6.1.2.tar.xz
cd gmp-6.1.2
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2
make -j8
make html
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log > /sources/slogs/008-gmp.log
make install
make install-html
cd /sources
rm -rf gmp-6.1.2
#END-gmp

#mpfr
touch /sources/slogs/009-mpfr.log
tar -xf /sources/mpfr-4.0.1.tar.xz
cd mpfr-4.0.1
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.1
make -j8
make html
make check > /sources/slogs/009-mpfr.log
make install
make install-html
cd /sources
rm -rf mpfr-4.0.1
#END-mpfr

#mpc
touch /sources/slogs/010-mpc.log
tar -xf /sources/mpc-1.1.0.tar.gz
cd mpc-1.1.0
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0
make -j8
make html
make check > /sources/slogs/010-mpc.log
make install
make install-html
cd /sources
rm -rf mpc-1.1.0
#END-mpc

#shadow
tar -xf /sources/shadow-4.6.tar.xz
cd shadow-4.6
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd
./configure --sysconfdir=/etc --with-group-name-max-length=32
make -j8
make install
mv -v /usr/bin/passwd /bin
pwconv
grpconv
echo "you shoud resetting new password now"
cd /sources
rm -rf shadow-4.6
#END-shadow

#GCC
touch /sources/slogs/011-gcc.log
tar -xf /sources/gcc-8.2.0.tar.xz
cd gcc-8.2.0
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
rm -f /usr/lib/gcc
mkdir -v build
cd       build
SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-libmpx         \
             --with-system-zlib
make -j8
ulimit -s 32768
rm ../gcc/testsuite/g++.dg/pr83239.C
chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check"
../contrib/test_summary | grep -A7 Summ > /sources/slogs/011-gcc.log
make install
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc
install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib' >> /sources/slogs/011-gcc.log
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log >> /sources/slogs/011-gcc.log
grep -B4 '^ /usr/include' dummy.log >> /sources/slogs/011-gcc.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g' >> /sources/slogs/011-gcc.log
grep "/lib.*/libc.so.6 " dummy.log >> /sources/slogs/011-gcc.log
grep found dummy.log >> /sources/slogs/011-gcc.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
cd /sources
rm -rf gcc-8.2.0
#END-GCC

#bzip
tar -zxvf /sources/bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
patch -Np1 -i /sources/bzip2-1.0.6-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
make -f Makefile-libbz2_so
make clean
make -j8
make PREFIX=/usr install
cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
cd /sources
rm -rf bzip2-1.0.6
#END-bzip

#pkg-config
touch /sources/slogs/012-pkg-config.log
tar -zxvf /sources/pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2
make -j8
make check > /sources/slogs/012-pkg-config.log
make install
cd /sources
rm -rf pkg-config-0.29.2
#END-pkg-config

#ncurses
tar -zxvf /sources/ncurses-6.1.tar.gz
cd ncurses-6.1
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec
make -j8
make install
mv -v /usr/lib/libncursesw.so.6* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
mkdir -v       /usr/share/doc/ncurses-6.1
cp -v -R doc/* /usr/share/doc/ncurses-6.1
cd /sources
rm -rf ncurses-6.1
#END-ncurses

#attr
touch /sources/slogs/013-attr.log
tar -zxvf /sources/attr-2.4.48.tar.gz
cd attr-2.4.48
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48
make -j8
make check > /sources/slogs/013-attr.log
make install
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
cd /sources
rm -rf attr-2.4.48
#END-attr

#acl
tar -zxvf /sources/acl-2.2.53.tar.gz
cd acl-2.2.53
./configure --prefix=/usr         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53
make -j8
make install
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
cd /sources
rm -rf acl-2.2.53
#END-acl

#libcap
tar -xf /sources/libcap-2.25.tar.xz
cd libcap-2.25
sed -i '/install.*STALIBNAME/d' libcap/Makefile
make -j8
make RAISE_SETFCAP=no lib=lib prefix=/usr install
chmod -v 755 /usr/lib/libcap.so
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
cd /sources
rm -rf libcap-2.25
#END-libcap

#sed
touch /sources/slogs/014-sed.log
tar -xf /sources/sed-4.5.tar.xz
cd sed-4.5
sed -i 's/usr/tools/'                 build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in
./configure --prefix=/usr --bindir=/bin
make -j8
make html
make check > /sources/slogs/014-sed.log
make install
install -d -m755           /usr/share/doc/sed-4.5
install -m644 doc/sed.html /usr/share/doc/sed-4.5
cd /sources
rm -rf sed-4.5
#END-sed

#psmisc
tar -xf /sources/psmisc-23.1.tar.xz
cd psmisc-23.1
./configure --prefix=/usr
make -j8
make install
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
cd /sources
rm -rf psmisc-23.1
#END-psmisc

#Iana-Etc
tar -jxvf /sources/iana-etc-2.30.tar.bz2
cd iana-etc-2.30
make -j8
make install
cd /sources
rm -rf iana-etc-2.30
#END-Iana-ETC

#bison
tar -xf /sources/bison-3.0.5.tar.xz
cd bison-3.0.5
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.5
make -j8
make install
cd /sources
rm -rf bison-3.0.5
#END-bison

#flex
touch /sources/slogs/015-flex.log
tar -zxvf flex-2.6.4.tar.gz
cd flex-2.6.4
sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4
make -j8
make check > /sources/slogs/015-flex.log
make install
ln -sv flex /usr/bin/lex
cd /sources
rm -rf flex-2.6.4
#END-flex

#grep
touch /sources/slogs/016-grep.log
tar -xf /sources/grep-3.1.tar.xz
cd grep-3.1
./configure --prefix=/usr --bindir=/bin
make -k check > /sources/slogs/016-grep.log
make install
cd /sources
rm -rf grep-3.1
#END-grep

#bash bash-4.4.18.tar.gz
tar -zxvf /sources/bash-4.4.18.tar.gz
cd bash-4.4.18
./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/bash-4.4.18 \
            --without-bash-malloc               \
            --with-installed-readline
make -j8
make install
mv -vf /usr/bin/bash /bin
cd /sources
rm -rf bash-4.4.18
#END-bash
echo "END bash compile"
