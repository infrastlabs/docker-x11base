
- ldd -v

```bash
headless @ barge in .../lib/xrdp |08:35:55  
$ ldd -v libvnc.so  
	linux-vdso.so.1 (0x00007ffd805cf000)
	libcommon.so.0 => /usr/local/xrdp/lib/xrdp/libcommon.so.0 (0x00007f91cb3dd000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f91cb1e1000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f91cb1be000)
	libssl.so.1.1 => /lib/x86_64-linux-gnu/libssl.so.1.1 (0x00007f91cb12b000)
	libcrypto.so.1.1 => /lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007f91cae55000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f91cae4f000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f91cb406000)

	Version information:
	./libvnc.so:
		libc.so.6 (GLIBC_2.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libc.so.6
	/usr/local/xrdp/lib/xrdp/libcommon.so.0:
		libdl.so.2 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libdl.so.2
		libssl.so.1.1 (OPENSSL_1_1_0) => /lib/x86_64-linux-gnu/libssl.so.1.1
		libpthread.so.0 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libpthread.so.0
		libcrypto.so.1.1 (OPENSSL_1_1_0) => /lib/x86_64-linux-gnu/libcrypto.so.1.1
		libc.so.6 (GLIBC_2.15) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.14) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libc.so.6
	/lib/x86_64-linux-gnu/libc.so.6:
		ld-linux-x86-64.so.2 (GLIBC_2.3) => /lib64/ld-linux-x86-64.so.2
		ld-linux-x86-64.so.2 (GLIBC_PRIVATE) => /lib64/ld-linux-x86-64.so.2
	/lib/x86_64-linux-gnu/libpthread.so.0:
		ld-linux-x86-64.so.2 (GLIBC_2.2.5) => /lib64/ld-linux-x86-64.so.2
		ld-linux-x86-64.so.2 (GLIBC_PRIVATE) => /lib64/ld-linux-x86-64.so.2
		libc.so.6 (GLIBC_2.7) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.14) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3.2) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_PRIVATE) => /lib/x86_64-linux-gnu/libc.so.6
	/lib/x86_64-linux-gnu/libssl.so.1.1:
		libpthread.so.0 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libpthread.so.0
		libc.so.6 (GLIBC_2.14) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libc.so.6
		libcrypto.so.1.1 (OPENSSL_1_1_0d) => /lib/x86_64-linux-gnu/libcrypto.so.1.1
		libcrypto.so.1.1 (OPENSSL_1_1_0i) => /lib/x86_64-linux-gnu/libcrypto.so.1.1
		libcrypto.so.1.1 (OPENSSL_1_1_0f) => /lib/x86_64-linux-gnu/libcrypto.so.1.1
		libcrypto.so.1.1 (OPENSSL_1_1_1) => /lib/x86_64-linux-gnu/libcrypto.so.1.1
		libcrypto.so.1.1 (OPENSSL_1_1_0) => /lib/x86_64-linux-gnu/libcrypto.so.1.1
	/lib/x86_64-linux-gnu/libcrypto.so.1.1:
		libdl.so.2 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libdl.so.2
		libpthread.so.0 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libpthread.so.0
		libc.so.6 (GLIBC_2.15) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.14) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.25) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3.2) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.7) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.3.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.17) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.16) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libc.so.6
	/lib/x86_64-linux-gnu/libdl.so.2:
		ld-linux-x86-64.so.2 (GLIBC_PRIVATE) => /lib64/ld-linux-x86-64.so.2
		libc.so.6 (GLIBC_PRIVATE) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.4) => /lib/x86_64-linux-gnu/libc.so.6
		libc.so.6 (GLIBC_2.2.5) => /lib/x86_64-linux-gnu/libc.so.6
```

- each

```bash
e in .../lib/xrdp |08:10:47  
$ ldd li
libcommon.a          libscp.so            libxrdpapi.so.0
libcommon.la         libscp.so.0          libxrdpapi.so.0.0.0
libcommon.so         libscp.so.0.0.0      libxrdp.la
libcommon.so.0       libvnc.a             libxrdp.so
libcommon.so.0.0.0   libvnc.la            libxrdp.so.0
libmc.a              libvnc.so            libxrdp.so.0.0.0
libmc.la             libxrdp.a            libxup.a
libmc.so             libxrdpapi.a         libxup.la
libscp.a             libxrdpapi.la        libxup.so
libscp.la            libxrdpapi.so        
# headless @ barge in .../lib/xrdp |08:10:53  
$ ldd libvnc.so  |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007fa83b313000)
	libcommon.so.0 => /usr/local/xrdp/lib/xrdp/libcommon.so.0 (0x00007fa83b2ea000)
	libcrypto.so.1.1 => /lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007fa83ad62000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fa83b0ee000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fa83ad5c000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fa83b0cb000)
	libssl.so.1.1 => /lib/x86_64-linux-gnu/libssl.so.1.1 (0x00007fa83b038000)
	linux-vdso.so.1 (0x00007fff79f8d000)
headless @ barge in .../lib/xrdp |08:11:19  
$ ldd /lib64/ld-linux-x86-64.so.2
	statically linked
headless @ barge in .../lib/xrdp |08:11:33  
$ ldd /usr/local/xrdp/lib/xrdp/libcommon.so.0
	linux-vdso.so.1 (0x00007ffc4e3fb000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007ff82670e000)
	libssl.so.1.1 => /lib/x86_64-linux-gnu/libssl.so.1.1 (0x00007ff82667b000)
	libcrypto.so.1.1 => /lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007ff8263a5000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007ff82639f000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ff8261ad000)
	/lib64/ld-linux-x86-64.so.2 (0x00007ff826758000)
headless @ barge in .../lib/xrdp |08:11:53  
$ ldd /lib/x86_64-linux-gnu/libcrypto.so.1.1
	linux-vdso.so.1 (0x00007ffdc09fc000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fb282077000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fb282054000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb281e62000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fb28235f000)
headless @ barge in .../lib/xrdp |08:12:20  
$ ldd /lib/x86_64-linux-gnu/libc.so.6
	/lib64/ld-linux-x86-64.so.2 (0x00007f377a96f000)
	linux-vdso.so.1 (0x00007ffda8b74000)
headless @ barge in .../lib/xrdp |08:12:43  
$ ldd /lib/x86_64-linux-gnu/libdl.so.2
	linux-vdso.so.1 (0x00007fff68c4f000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f9728c33000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f9728e37000)
headless @ barge in .../lib/xrdp |08:13:04  
$ ldd /lib64/ld-linux-x86-64.so.2
	statically linked


# 
headless @ barge in .../lib/xrdp |08:15:56  
$ ldd /lib/x86_64-linux-gnu/libpthread.so.0
	linux-vdso.so.1 (0x00007ffe22972000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f4d1aea5000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f4d1b0c6000)
headless @ barge in .../lib/xrdp |08:16:14  
$ ldd /lib/x86_64-linux-gnu/libssl.so.1.1
	linux-vdso.so.1 (0x00007fff729f9000)
	libcrypto.so.1.1 => /lib/x86_64-linux-gnu/libcrypto.so.1.1 (0x00007fb4b175f000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fb4b173c000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb4b154a000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fb4b1544000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fb4b1ad4000)
headless @ barge in .../lib/xrdp |08:16:26  
$ find /usr/lib |grep vdso

```