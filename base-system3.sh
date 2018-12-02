#!/bin/bash
cd /sources

#libtool
touch /sources/slogs/017-libtool.log
tar -xf /sources/libtool-2.4.6.tar.xz
cd libtool-2.4.6
./configure --prefix=/usr
make -j8
make check TESTSUITEFLAGS=-j4 > /sources/slogs/017-libtool.log
make install
cd /sources
rm -rf libtool-2.4.6
#END-libtool

#gdbm
touch /sources/slogs/018-gdbm.log
tar -zxvf /sources/gdbm-1.17.tar.gz
cd gdbm-1.17
./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat
make -j8
make check > /sources/slogs/018-gdbm.log
make install
cd /sources
rm -rf gdbm-1.17
#END-gdbm

#gpref
touch /sources/slogs/019-gpref.log
tar -zxvf /sources/gperf-3.1.tar.gz
cd gperf-3.1
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make -j8
make -j1 check > /sources/slogs/019-gpref.log
make install
cd /sources
rm -rf gperf-3.1
#END-gpref

#expat
touch /sources/slogs/020-expat.log
tar -jxvf /sources/expat-2.2.6.tar.bz2
cd expat-2.2.6
sed -i 's|usr/bin/env |bin/|' run.sh.in
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.6
make -j8
make check > /sources/slogs/020-expat.log
make install
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.6
cd /sources
rm -rf expat-2.2.6
#END-expat

#Inetutils
touch /sources/slogs/021-Inetutils.log
tar -xf /sources/inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make -j8
make check > /sources/slogs/021-Inetutils.log
make install
mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
cd /sources
rm -rf inetutils-1.9.4
#END-Inetutils

#perl
touch /sources/slogs/022-perl.log
tar -xf /sources/perl-5.28.0.tar.xz
cd perl-5.28.0
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads
make -j8
make -k test > /sources/slogs/022-perl.log
make install
unset BUILD_ZLIB BUILD_BZIP2
cd /sources
rm -rf perl-5.28.0
#END-perl

#XML::Parser-2.44
touch /sources/slogs/023-XML-Parser.log
tar -zxvf /sources/XML-Parser-2.44.tar.gz
cd XML-Parser-2.44
perl Makefile.PL
make -j8
make test > /sources/slogs/023-XML-Parser.log
make install
cd /sources
rm -rf XML-Parser-2.44
#END-XML::Parser-2.44

#intltool
touch /sources/slogs/024-intltool.log
tar -zxvf /sources/intltool-0.51.0.tar.gz
cd intltool-0.51.0
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr
make -j8
make check > /sources/slogs/024-intltool.log
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
cd /sources
rm -rf intltool-0.51.0
#END-intltool

#autoconf
touch /sources/slogs/025-autoconf.log
tar -xf /sources/autoconf-2.69.tar.xz
cd autoconf-2.69
./configure --prefix=/usr
make -j8
make check > /sources/slogs/025-autoconf.log
make install
cd /sources
rm -rf autoconf-2.69
#END-autoconf

#automake
touch /sources/slogs/026-automake.log
tar -xf /sources/automake-1.16.1.tar.xz
cd automake-1.16.1
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
make -j8
make -j4 check > /sources/slogs/026-automake.log
make install
cd /sources
rm -rf automake-1.16.1
#END-automake

#xz
touch /sources/slogs/027-xz.log
tar -xf /sources/xz-5.2.4.tar.xz
cd xz-5.2.4
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4
make -j8
make check > /sources/slogs/027-xz.log
make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
cd /sources
rm -rf xz-5.2.4
#END-xz

#kmod
tar -xf /sources/kmod-25.tar.xz
cd kmod-25
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make -j8
make install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /sbin/$target
done

ln -sfv kmod /bin/lsmod
cd /sources
rm -rf kmod-25
#END-kmod
echo "now builded kmod"
