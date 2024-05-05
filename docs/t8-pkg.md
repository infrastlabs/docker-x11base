

**apk**

```bash
# apk list -I; 

# apk info
/home/headless # apk info
...
xterm
xvidcore
xz-libs
zlib
zstd-libs
/home/headless # apk info |wc
    280     280    2870
apk info  --no-cache 
apk info  --no-network --no-progress
# Info options:
  -a, --all             List all information known about the package
  -d, --description     Print the package description
  -e, --installed       Check package installed status
  -L, --contents        List files included in the package
  -P, --provides        List what the package provides
  -r, --rdepends        List reverse dependencies (all other packages which depend on the package)
  -R, --depends         List the dependencies of the package
  -s, --size            Print the package\'s installed size
  -w, --webpage         Print the URL for the package\'s upstream webpage
  -W, --who-owns        Print the package which owns the specified file
  --install-if          List the package\'s install_if rule
  --license             Print the package SPDX license identifier
  --replaces            List the other packages for which this package is marked as a replacement
  --rinstall-if         List other packages whose install_if rules refer to this package
  --triggers            Print active triggers for the package

# apk info -X xxx;
/home/headless # apk info -s zstd-libs
zstd-libs-1.5.5-r8 installed size:
712 KiB

/home/headless # apk info -R zstd-libs
zstd-libs-1.5.5-r8 depends on:
so:libc.musl-x86_64.so.1

/home/headless # apk info  -s xset xterm
xset-1.2.5-r1 installed size:
44 KiB
xterm-388-r0 installed size:
796 KiB

# try2
  95 pkgs=$(apk info  --no-network --no-progress)
  96 apk info  -s $pkgs
/home/headless # apk info  -s $pkgs |sed ":a;N;s/:\n/: /g;ta" |grep  -v "^$"
xfwm4-4.18.0-r2 installed size: 3876 KiB
xkeyboard-config-2.40-r0 installed size: 4044 KiB
xprop-1.2.7-r0 installed size: 56 KiB
xrdb-1.2.2-r0 installed size: 44 KiB
xset-1.2.5-r1 installed size: 44 KiB
xterm-388-r0 installed size: 796 KiB
xvidcore-1.3.7-r2 installed size: 372 KiB
xz-libs-5.4.5-r0 installed size: 232 KiB
zlib-1.3.1-r0 installed size: 108 KiB
zstd-libs-1.5.5-r8 installed size: 712 KiB

/home/headless # apk info  -s $pkgs |sed ":a;N;s/ installed size:\n/|/g;ta" |grep  -v "^$" #|awk '{print $2" "$1}'
zstd-libs-1.5.5-r8|712 KiB
```