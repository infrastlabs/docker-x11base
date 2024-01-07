
## xrdp-v0.9.16

相同src包 [ubt2004常规编译版]， alpine_clang下:`sesman/verify_user.c`需注释putpwent一行

- 8号docker-headless:latest 11081容器内调试
  - `./sbin/xrdp -n` ubt2004版，带libvnc.so文件则正常(xrdp.ini:去除lib=libvnc.so则也不行)
  - alpine静编译版: 移除了./lib/xrdp; 补回>> 也无libxvnc.so/只有libxvnc.a静态文件
    - 手动调参/tenVM2手动编，去除LDFLAGS="-static">> 还是无libvnc.so (`export LDFLAGS="-Wl,--as-needed --static -static ..`导致)
    - xrdp.ini: 去除chansrv及lib=libvnc.so也不行


```bash
# ref de-static-xrdp.md: 早期非静态编，查看有so文件;
root@VM-12-9-ubuntu:/mnt/xrdp-repo-v0.9.23-02# find |grep libvnc
./vnc/.libs/libvnc.soT
./vnc/.libs/libvnc.a
./vnc/.libs/libvnc.lai
./vnc/.libs/libvnc.la
./vnc/.libs/libvnc.so
./vnc/libvnc.la

# ldd libvnc.so(有基础库依赖)
root@VM-12-9-ubuntu:/mnt/xrdp-repo-v0.9.23-02# ldd ./vnc/.libs/libvnc.so |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007fd03de58000)
	libc.musl-x86_64.so.1 => not found ###not-found [build@buidler_tmux2]
	libcommon.so.0 => not found
	libcrypto.so.1.1 => /lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007fd03dad9000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fd03d8c2000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fd03d8bc000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fd03dab6000)
	libssl.so.1.1 => /lib/x86_64-linux-gnu/libssl.so.1.1 (0x00007fd03ddaf000)
	linux-vdso.so.1 (0x00007ffeefb11000)

# 01: 如何生成libvnc.so 且不带基础库依赖??
# 02: xrdp.ini lib=libvnc.so代码引用关系/可否免配??
# conf_xrdp_help.txt

```

- 再次转动态编译

```bash
# 注释
# export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

/mnt2/docker-x11base/compile/src # find /tmp/xrdp |grep libvnc
/tmp/xrdp/vnc/.libs/libvnc.soT
/tmp/xrdp/vnc/.libs/libvnc.lai
/tmp/xrdp/vnc/.libs/libvnc.la
/tmp/xrdp/vnc/.libs/libvnc.so
/tmp/xrdp/vnc/libvnc.la
/mnt2/docker-x11base/compile/src # ldd /tmp/xrdp/vnc/.libs/libvnc.so
        /lib/ld-musl-x86_64.so.1 (0x7fd2d7100000)
        libcommon.so.0 => /tmp/xrdp/common/.libs/libcommon.so.0 (0x7fd2d70dc000)
        libssl.so.1.1 => /lib/libssl.so.1.1 (0x7fd2d705b000)
        libcrypto.so.1.1 => /lib/libcrypto.so.1.1 (0x7fd2d6dd8000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fd2d7100000)
```

- try a> so库

```bash
# try a> so库
# https://blog.csdn.net/wh617053508/article/details/133396789 ##cmd@PIC
# ar -crv libharfbuzz.a libharfbuzz.so #动转静态库
# gcc -shared -o libfoo.so libfoo.a #生成动态库


# CLANG
/tmp/xrdp/vnc/.libs # clang -shared -o ss.so libvnc.a 
/tmp/xrdp/vnc/.libs # ls -lh
total 108K   
-rw-r--r--    1 root     root       43.5K Nov  8 17:38 libvnc.a
lrwxrwxrwx    1 root     root          12 Nov  8 17:38 libvnc.la -> ../libvnc.la
-rw-r--r--    1 root     root         951 Nov  8 17:38 libvnc.lai
-rwxr-xr-x    1 root     root       15.7K Nov  8 17:43 ss.so
-rw-r--r--    1 root     root       42.9K Nov  8 17:38 vnc.o
# validate
/tmp/xrdp/vnc/.libs # ldd ss.so 
        /lib/ld-musl-x86_64.so.1 (0x7f158ecb4000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f158ecb4000)
root@VM-12-9-ubuntu:~# ldd /mnt/ss.so 
	linux-vdso.so.1 (0x00007ffdd9694000)
	libc.musl-x86_64.so.1 => not found

# GCC
/tmp/xrdp/vnc/.libs # gcc -shared -o ss.so libvnc.a 
/tmp/xrdp/vnc/.libs # ls -lh
total 108K   
-rw-r--r--    1 root     root       43.5K Nov  8 17:38 libvnc.a
-rwxr-xr-x    1 root     root       15.7K Nov  8 17:41 ss.so
-rw-r--r--    1 root     root       42.9K Nov  8 17:38 vnc.o
# validate
/tmp/xrdp/vnc/.libs # ldd ss.so 
        /lib/ld-musl-x86_64.so.1 (0x7f3638c6b000)
/tmp/xrdp/vnc/.libs # \cp ss.so /mnt2/
root@VM-12-9-ubuntu:~# ldd /mnt/ss.so 
	statically linked  ### statical!!

```

- 验证，headless下conn加载so库做调试（基于`static版xrdp` + 替换so）
  - a转so版`libvnc.so`：不可用 （`error loading libvnc.so`）
  - tigervnc's `extentions/.../libvnc.so`: 不可用
  - headless内`/usr/local/xrdp/lib/xrdp/libvnc.so`: 不可用


```bash
DBG:
# x11-base:fluxbox-dbg>> 启动xrdp -n:无port[certs未生成?]>> --dump-xxy.. >./sesman.log日志; (未打到console)
# ubt2004-headless下，手动cp alpine-rootfs/files/usr/local/static/xrdp; 再运行./xrdp -n> (tail -f /var/log/xrdp.log)

ERR:
# error loading libvnc.so specified in xrdp.ini
# tigervnc's; local/xorg's gcc[a>so]'s: x3 都load出错;

ISSUE: [error loading in:title,body]
# (err-with: 0.9.22)
# https://github.com/neutrinolabs/xrdp/discussions/2678#discussioncomment-5937960

# my-ask
# https://github.com/neutrinolabs/xrdp/discussions/2850
```

