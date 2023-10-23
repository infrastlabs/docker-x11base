

- pango
- libxrandr
- fontconfig #split@Dockerfile
- 
- **openbox**

```bash
 107 cd ../fk-docker-baseimage-gui/src/openbox/
 108 ls
 109 bash build.sh 
 110 ls -lh

#  115 ls
 116 cd /tmp/openbox
 117 ls
 118 cd -
 119 cd /tmp/openbox-install/
 120 ls
 121 find
 123 ./usr/bin/openbox --help
 126 xx-verify --static      /tmp/openbox-install/usr/bin/openbox #OK
 127 echo $? #0
```


- **fluxbox** @C++
  - blackbox> fluxbox; github资料不如openbox
  - 相比openbox: 配置项简洁; 自带panel;

```bash
# how build?

# hand
./autogen.sh
./configure 
# ./configure  --enable-static --prefix=/usr/local/static/dropbear
make

/mnt2/fluxbox # make
cmp: ./src/defaults.cc: No such file or directory
make  all-recursive
make[1]: Entering directory '/mnt2/fluxbox'
Making all in nls/C
make[2]: Entering directory '/mnt2/fluxbox/nls/C'
/bin/sh: fluxbox.cat: not found
make[2]: *** [Makefile:484: fluxbox.cat] Error 127
make[2]: Leaving directory '/mnt2/fluxbox/nls/C'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox'
make: *** [Makefile:1760: all] Error 2
```

