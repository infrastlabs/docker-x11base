

- thunar
  - exo
    - libxfce4ui
      - xfconf
        - libxfce4util


**default env**

```bash
# root@tenvm2:~# cat /mnt/thunar412-hist1.txt 
    1  cd /mnt2/_misc2-2/_xfce4/
    3  cd _deps/
    # libxfce4util
    7  cd libxfce4util/
    9  ./autogen.sh 
   10  apk add xfce4-dev-tools
   11  ./autogen.sh 
   12  env |grep FLAGS
   13  make 
   15  find |grep util
   16  find |grep util |grep "\.a$"
   17  ./configure --enable-static
   18  make 
   19  find |grep util |grep "\.a$"
   22  git branch
   # xfconf
   33  cd ../xfconf/
   34  ls
   35  ./autogen.sh 
   36  git branch 
   37  ls
   38  ./autogen.sh 
   39  apk add dbus
   40  apk add dbus-dev
   41  apk add dbus-static
   42  find /usr/lib |grep dbus
   43  ./autogen.sh 
   44  apk add dbus-glib
   45  apk add dbus-glib-dev
   46  ./autogen.sh 
   47  make
   48  ls
   49  find |grep xfconfd
   50* ldd xfconfd/xfconf
   51  find |grep xfconf |grep "\.a$"
   52  find |grep xfconf |grep "\.so$"
   53  ./configure --enable-static
   54  make
   55  find |grep xfconf |grep "\.a$"
   56  make clean
   57  make
   58  find |grep xfconf |grep "\.a$"
   59  make install
   # libxfce4ui
   60  cd ../libxfce4ui/
   63  ./autogen.sh 
   64  make
   65  find |grep ui |grep "\.so$"
   66  find |grep ui |grep "\.a$"
   67  ./configure --enable-static
   68  make
   69  find |grep ui |grep "\.a$"
   70  make install
   73  find |grep ui
   # exo
   76  cd ../exo/
   78  ./autogen.sh 
   79  git branch 
   81  git checkout exo-0.10.0
   83  ./autogen.sh 
   84  make
   87  find |grep exo$
   89  ls exo
   91  find |grep exo |grep "\.so$"
   92  find |grep exo |grep "\.a$"
   93  ./configure --enable-static
   95  make
   96  find |grep exo |grep "\.a$"
   97  make install
   99  find /usr/local/lib |grep exo
   #thunar
  103  cd ../thunar/
  105  ./autogen.sh 
  107  make
  109  find |grep thunar$
  110  ls -lh ./thunar/thunar
  111  ldd ./thunar/thunar
  112  ./thunar/thunar -h
  113  ./thunar/thunar -V
  115  ./configure --enable-static
  118  env |grep FLAGS
  122  make clean
  123  make
  124  ls -lh ./thunar/thunar
  125  make install
  127  which thunar
  128  ls -lh /usr/local/bin/thunar
  132  ls -lh ./thunar/thunar
  129  ldd /usr/local/bin/thunar
  131  ldd /usr/local/bin/thunar |wc
  134  ldd /usr/local/bin/thunar |sort

# thunar
bash-5.1# ls -lh /usr/local/bin/thunar
-rwxr-xr-x    1 root     root        4.1M Dec 27 15:39 /usr/local/bin/thunar
bash-5.1# ldd /usr/local/bin/thunar |wc
       58       230      3589
bash-5.1# ls -lh ./thunar/thunar
-rwxr-xr-x    1 root     root       11.7K Dec 27 15:39 ./thunar/thunar
```

**FLAGS**

```bash
# STATIC
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++


bash-5.1# history |tail -8
  145  export CC=xx-clang
  146  export CXX=xx-clang++
  147  ls
  148  pwd
  149  ./autogen.sh 
  150  make
  151  find /usr/local/lib/libexo*
# make
2 warnings generated.
  CCLD     thunar
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object '/usr/local/lib/libexo-1.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:1083: thunar] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[2]: *** [Makefile:998: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[1]: *** [Makefile:761: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar'
make: *** [Makefile:574: all] Error 2
# bash-5.1# find /usr/local/lib/libexo*
/usr/local/lib/libexo-1.a
/usr/local/lib/libexo-1.la
/usr/local/lib/libexo-1.so
/usr/local/lib/libexo-1.so.0
/usr/local/lib/libexo-1.so.0.1.0


bash-5.1# mv /usr/local/lib/libexo-1.so /usr/local/lib/libexo-1.so-ex
# make
make[3]: Entering directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
  CCLD     thunar
clang-12: error: no such file or directory: '/usr/local/lib/libexo-1.so' ##runtime .so call?
make[3]: *** [Makefile:1083: thunar] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[2]: *** [Makefile:998: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[1]: *** [Makefile:761: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar'
make: *** [Makefile:574: all] Error 2


bash-5.1# ./configure --enable-static --disable-shared
# make
2 warnings generated.
  CCLD     thunar
clang-12: error: no such file or directory: '/usr/local/lib/libexo-1.so'
make[3]: *** [Makefile:1083: thunar] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[2]: *** [Makefile:998: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[1]: *** [Makefile:761: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar'
make: *** [Makefile:574: all] Error 2
```

