

- lxappearance `dyn:ok` @Lxde
- gpicview `dyn:ok` @Lxde
- lxtask `dyn:ok` @Lxde
- jgmenu `dyn:ok`
- 
- tint2 `imlib2`
- rofi `xcb-ewmh/icccm/cursor`
- sakura `SAKURA_2_3_7:vte`

## Lxde Misc

```bash
# bash-5.1# history |tail -40
    1  cd /mnt2/_misc2-2/
    2  ls
  #  3  cd gpicview/
    4  ls
    5  ./autogen.sh 
    6  ./configure 
    7  ls
    8  make
    9  ls -lh
   10  ls src/
   11  ldd src/gpicview
   12  cd ..
   13  ls
   #14  cd jgmenu/
   15  ls
   16  ./configure 
   17  apk add librsvg
   18  apk add librsvg-dev
   19  ./configure 
   20  make
   21  ls
   22  ls -lh jgmenu
   23  ldd jgmenu

# bash-5.1# history |tail -30
   #29  cd lxappearance/
   30  ls
   31  ./autogen.sh 
   32  ls
   33  ./configure 
   34  make
   35  ls
   36  ls src/
   37  ldd src/lxappearance
   #38  cd ../lxtask/
   39  ls
   40  ./autogen.sh 
   41  ls
   42  ./configure 
   43  make
   44  ls
   45  ls src/
   46  ./src/lxtask 
   47  ldd ./src/lxtask 
```

- rofi

```bash
# rofi #autoreconf -v --install
bash-5.1# history |tail -50
   91  cd rofi/
   93  autoreconf -v --install
  100  cp .gitmodules  .gitmodules-bk1
  101  sed -i "s^github.com^hub.njuu.cf^g" .gitmodules
  102  cat .gitmodules
  104  git submodule update
  106  ls subprojects/libgwater/
  107  ls subprojects/libnkutils/
  109  autoreconf -v --install
  111  ./configure
  112  apk add bison-dev
  113  apk add bison
  115  apk add flex
  116  apk add flex-dev
  117  ./configure
  118  apk add xkbcommon ##no pkg
  122  apk add libxkbcommon
  123  apk add libxkbcommon-dev
Package 'xcb-ewmh', required by 'virtual:world', not found
Package 'xcb-icccm', required by 'virtual:world', not found
Package 'xcb-cursor', required by 'virtual:world', not found

# tint2 https://github.com/o9000/tint2/tree/v16.1
# --   Package 'imlib2', required by 'virtual:world', not found
bash-5.1# history |tail -10
  135  cd tint2/
  137  git checkout 16.1
  139  mkdir build
  140  cd build
  141  cmake ..
# make -j4

# sakura https://github.com/dabisu/sakura/tree/SAKURA_2_3_7
master 940 # --   Package 'gtk+-3.0', required by 'virtual:world', not found
SAKURA_3_5_0 758 @2017.7.14 # -- Checking for module 'gtk+-3.0>=3.12' ERR
SAKURA_3_2_1 630 @2015.7.24 #'glib-2.0>=2.20'ok; #--   Package 'gtk+-3.0', required by 'virtual:world', not found
SAKURA_3_0_2 476 @2012.3.7 #--   Package 'gtk+-3.0', required by 'virtual:world', not found
SAKURA_2_3_7 315 @2010.3.4 #'gtk+-2.0>=2.10'ok; --   Package 'vte', required by 'virtual:world', not found
```
