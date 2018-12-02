#!/bin/bash
cd /sources

#gettext
touch /sources/slogs/028-gettext.log
tar -xf /sources/gettext-0.19.8.1.tar.xz
cd gettext-0.19.8.1
sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in
sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' \
    -i gettext-tools/its/appdata.loc
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1
make -j8
make check > /sources/slogs/028-gettext.log
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
cd /sources
rm -rf gettext-0.19.8.1
#END-gettext

#libelf
touch /sources/slogs/029-libelf.log
tar -jxvf /sources/elfutils-0.173.tar.bz2
cd elfutils-0.173
./configure --prefix=/usr
make -j8
make check > /sources/slogs/029-libelf.log
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
cd /sources
rm -rf elfutils-0.173
#END-libelf

#libffi
touch /sources/slogs/030-libffi.log
tar -zxvf /sources/libffi-3.2.1.tar.gz
cd libffi-3.2.1
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in
./configure --prefix=/usr --disable-static --with-gcc-arch=native
make -j8
make check > /sources/slogs/030-libffi.log
make install
cd /sources
rm -rf libffi-3.2.1
#END-libffi

#openssl
touch /sources/slogs/031-openssl.log
tar -zxvf /sources/openssl-1.1.0i.tar.gz
cd openssl-1.1.0i
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make -j8
make test > /sources/slogs/031-openssl.log
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.0i
cp -vfr doc/* /usr/share/doc/openssl-1.1.0i
cd /sources
rm -rf openssl-1.1.0i
#END-openssl

#python3
tar -xf /sources/Python-3.7.0.tar.xz
cd Python-3.7.0
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes
make -j8
make install
chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so
install -v -dm755 /usr/share/doc/python-3.7.0/html
tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.7.0/html \
    -xvf ../python-3.7.0-docs-html.tar.bz2
cd /sources
rm -rf Python-3.7.0
#END-python3

#ninja
tar -zxvf /sources/ninja-1.8.2.tar.gz
cd ninja-1.8.2
export NINJAJOBS=8
patch -Np1 -i /sources/ninja-1.8.2-add_NINJAJOBS_var-1.patch
python3 configure.py --bootstrap
python3 configure.py
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
cd /sources
rm -rf ninja-1.8.2
#END-ninja

#meson
tar -zxvf /sources/meson-0.47.1.tar.gz
cd meson-0.47.1
python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /
cd /sources
rm -rf meson-0.47.1
#END-meson

#systemd
tar -zxvf /sources/systemd-239.tar.gz
cd systemd-239
ln -sf /tools/bin/true /usr/bin/xsltproc
tar -xf ../systemd-man-pages-239.tar.xz
sed '166,$ d' -i src/resolve/meson.build
patch -Np1 -i /sources/systemd-239-glibc_statx_fix-1.patch
sed -i 's/GROUP="render", //' rules/50-udev-default.rules.in
mkdir -p build
cd       build

LANG=en_US.UTF-8                   \
meson --prefix=/usr                \
      --sysconfdir=/etc            \
      --localstatedir=/var         \
      -Dblkid=true                 \
      -Dbuildtype=release          \
      -Ddefault-dnssec=no          \
      -Dfirstboot=false            \
      -Dinstall-tests=false        \
      -Dkill-path=/bin/kill        \
      -Dkmod-path=/bin/kmod        \
      -Dldconfig=false             \
      -Dmount-path=/bin/mount      \
      -Drootprefix=                \
      -Drootlibdir=/lib            \
      -Dsplit-usr=true             \
      -Dsulogin-path=/sbin/sulogin \
      -Dsysusers=false             \
      -Dumount-path=/bin/umount    \
      -Db_lto=false                \
      ..
LANG=en_US.UTF-8 ninja
LANG=en_US.UTF-8 ninja install
rm -rfv /usr/lib/rpm
rm -f /usr/bin/xsltproc
systemd-machine-id-setup
cat > /lib/systemd/systemd-user-sessions << "EOF"
#!/bin/bash
rm -f /run/nologin
EOF
chmod 755 /lib/systemd/systemd-user-sessions
cd /sources
rm -rf systemd-239
#END-systemd

#procps-ng
touch /sources/slogs/032-procps-ng.log
tar -xf /sources/procps-ng-3.3.15.tar.xz
cd procps-ng-3.3.15
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd
make -j8
sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
rm testsuite/pgrep.test/pgrep.exp
make check > /sources/slogs/032-procps-ng.log
make install
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
cd /sources
rm -rf procps-ng-3.3.15
#END-procps-ng

#E2fsprogs
touch /sources/slogs/033-E2fsprogs.log
tar -zxvf /sources/e2fsprogs-1.44.3.tar.gz
cd e2fsprogs-1.44.3
mkdir -v build
cd build
../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make -j8
ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
make LD_LIBRARY_PATH=/tools/lib check > /sources/slogs/033-E2fsprogs.log
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
cd /sources
rm -rf e2fsprogs-1.44.3
#END-E2fsprogs

#coreutils
tar -xf /sources/coreutils-8.30.tar.xz
cd coreutils-8.30
patch -Np1 -i /sources/coreutils-8.30-i18n-1.patch
sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
FORCE_UNSAFE_CONFIGURE=1 make
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
mv -v /usr/bin/{head,sleep,nice} /bin
cd /sources
rm -rf coreutils-8.30
#END-coreutils

#check
touch /sources/slogs/034-check.log
tar -zxvf /sources/check-0.12.0.tar.gz
cd check-0.12.0
./configure --prefix=/usr
make -j8
make check > /sources/slogs/034-check.log
make install
sed -i '1 s/tools/usr/' /usr/bin/checkmk
cd /sources
rm -rf check-0.12.0
#END-check

#diffutils
touch /sources/slogs/035-diffutils.log
tar -xf /sources/diffutils-3.6.tar.xz
cd diffutils-3.6
./configure --prefix=/usr
make -j8
make check > /sources/slogs/035-diffutils.log
make install
cd /sources
rm -rf diffutils-3.6
#END-diffutils

#gawk
touch /sources/slogs/036-gawk.log
tar -xf /sources/gawk-4.2.1.tar.xz
cd gawk-4.2.1
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make -j8
make check > /sources/slogs/036-gawk.log
make install
mkdir -v /usr/share/doc/gawk-4.2.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.2.1
cd /sources
rm -rf gawk-4.2.1
#END-gawk

#findutils
touch /sources/slogs/037-findutils.log
tar -zxvf /sources/findutils-4.6.0.tar.gz
cd findutils-4.6.0
sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
./configure --prefix=/usr --localstatedir=/var/lib/locate
make -j8
make check > /sources/slogs/037-findutils.log
make install
mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
cd /sources
rm -rf findutils-4.6.0
#END-findutils

#groff
tar -zxvf /sources/groff-1.22.3.tar.gz
cd groff-1.22.3
PAGE=A4 ./configure --prefix=/usr
make -j1
make install
cd /sources
rm -rf groff-1.22.3
#END-groff
echo "END groff. next you build GRUB"
