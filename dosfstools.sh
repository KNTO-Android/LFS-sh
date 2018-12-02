#!/bin/bash

cd /sources

#dosfstools
touch /sources/slogs/038-dosfstools.log
tar -xf /sources/dosfstools-4.1.tar.xz
cd dosfstools-4.1
./configure --prefix=/               \
            --enable-compat-symlinks \
            --mandir=/usr/share/man  \
            --docdir=/usr/share/doc/dosfstools-4.1 &&
make -j8 > /sources/slogs/038-dosfstools.log
make install
cd /sources
rm -rf dosfstools-4.1
#END-dosfstools

#less
tar -zxvf /sources/less-530.tar.gz
cd less-530
./configure --prefix=/usr --sysconfdir=/etc
make -j8
make install
cd /sources
rm -rf less-530
#END-less

#gzip
touch /sources/slogs/039-gzip.log
tar -xf /sources/gzip-1.9.tar.xz
cd gzip-1.9
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
./configure --prefix=/usr
make -j8
make check > /sources/slogs/039-gzip.log
make install
mv -v /usr/bin/gzip /bin
cd /sources
rm -rf gzip-1.9
#END-gzip

#iproute2
tar -xf /sources/iproute2-4.18.0.tar.xz
cd iproute2-4.18.0
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
sed -i 's/.m_ipt.o//' tc/Makefile
make -j8
make DOCDIR=/usr/share/doc/iproute2-4.18.0 install
cd /sources
rm -rf iproute2-4.18.0
#END-iproute2

#kbd
touch /sources/slogs/040-kdb.log
tar -xf /sources/kbd-2.0.4.tar.xz
cd kbd-2.0.4
patch -Np1 -i /sources/kbd-2.0.4-backspace-1.patch
sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make -j8
make check > /sources/slogs/040-kdb.log
make install
mkdir -v       /usr/share/doc/kbd-2.0.4
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4
cd /sources
rm -rf kbd-2.0.4
#END-kdb

#libpipeline
touch /sources/slogs/041-libpipeline.log
tar -zxvf /sources/libpipeline-1.5.0.tar.gz
cd libpipeline-1.5.0
./configure --prefix=/usr
make -j8
make check > /sources/slogs/041-libpipeline.log
make install
cd /sources
rm -rf libpipeline-1.5.0
#END-libpipeline

#make
touch /sources/slogs/042-make.log
tar -jxvf /sources/make-4.2.1.tar.bz2
cd make-4.2.1
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/usr
make -j8
make PERL5LIB=$PWD/tests/ check > /sources/slogs/042-make.log
make install
cd /sources
rm -rf make-4.2.1
#END-make

#patch
touch /sources/slogs/043-patch.log
tar -xf /sources/patch-2.7.6.tar.xz
cd patch-2.7.6
./configure --prefix=/usr
make -j8
make check > /sources/slogs/043-patch.log
make install
cd /sources
rm -rf patch-2.7.6
#END-patch

#D-bus
tar -zxvf /sources/dbus-1.12.10.tar.gz
cd dbus-1.12.10
./configure --prefix=/usr                       \
              --sysconfdir=/etc                   \
              --localstatedir=/var                \
              --disable-static                    \
              --disable-doxygen-docs              \
              --disable-xml-docs                  \
              --docdir=/usr/share/doc/dbus-1.12.10 \
              --with-console-auth-dir=/run/console
make -j8
make install
mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so
ln -sfv /etc/machine-id /var/lib/dbus
cd /sources
rm -rf dbus-1.12.10
#END-D-Bus

#utils-linux
tar -xf /sources/util-linux-2.32.1.tar.xz
cd util-linux-2.32.1
mkdir -pv /var/lib/hwclock
rm -vf /usr/include/{blkid,libmount,uuid}
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.32.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python
make -j8
make install
cd /sources
rm -rf util-linux-2.32.1
#END-util-linux

#man-db
touch /sources/slogs/044-man-db.log
tar -xf /sources/man-db-2.8.4.tar.xz
cd man-db-2.8.4
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.4 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap
make -j8
make check > /sources/slogs/044-man-db.log
make install
cd /sources
rm -rf man-db-2.8.4
#END-man-db

#tar
touch /sources/slogs/045-tar.log
tar -xf /sources/tar-1.30.tar.xz
cd tar-1.30
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make -j8
make check > /sources/slogs/045-tar.log
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.30
cd /sources
rm -rf tar-1.30
#END-tar

#texinfo
touch /sources/slogs/046-texinfo.log
tar -xf /sources/texinfo-6.5.tar.xz
cd texinfo-6.5
sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm
./configure --prefix=/usr --disable-static
make -j8
make check > /sources/slogs/046-texinfo.log
make install
make TEXMF=/usr/share/texmf install-tex
pushd /usr/share/info
rm -v dir
for f in *
  do install-info $f dir 2>/dev/null
done
popd
cd /sources
rm -rf texinfo-6.5
#END-texinfo

#nano
tar -xf /sources/nano-2.9.8.tar.xz
cd nano-2.9.8
./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --enable-utf8     \
            --docdir=/usr/share/doc/nano-2.9.8 &&
make -j8
make install &&
install -v -m644 doc/{nano.html,sample.nanorc} /usr/share/doc/nano-2.9.8
cat > /etc/nanorc << "EOF"
set autoindent
set constantshow
set fill 72
set historylog
set multibuffer
set nohelp
set nowrap
set positionlog
set quickblank 
set regexp
set smooth
set suspend
EOF
cd /sources
rm -rf nano-2.9.8

