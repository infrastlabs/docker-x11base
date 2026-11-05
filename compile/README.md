

- buildx
  - ubt-builder
  - deb-builder
  - builder `Dockerfile.builder`
  - gtk224 `Dockerfile.builder.gtk224> u-gtk/build.sh b_deps`
    - openbox/build.sh apkdeps
    - openbox/build.sh pango & ##`needed by gtk`
    - openbox/build.sh libxrandr & #`same: x-xrdp/build.sh`
    - xcompmgr/build.sh Xdamage &
    - `--`
    - `apkdeps`
    - atk & #`needed by gtk`
    - gdk-pixbuf & #`needed by gtk`
    - `--`
    - gtk  
  - compile

**Dockerfile** `Line:374`

> part1: core + wm

- fluxbox
  - x-xrdp/build.sh libxrandr
  - _ex/fontconfig/build.sh
  - `apk add libxml2-dev expat-static  fribidi-static libxpm-dev`
  - fluxbox `@build.sh.xft.sh`
- openbox
  - `apkdeps; apk add fontconfig-dev fontconfig-static`
  - libxrandr &
  - pango
  - openbox
- suckless
  - `apk add fontconfig-dev fontconfig-static  libxcursor-dev util-linux-dev `
  - st
  - dwm
  - dmenu
- x-tigervnc
  - libxfont2 &
  - libfontenc &
  - libtasn1 &
  - libxshmfence &
  - `--`
  - tigervnc &
  - xkb &
  - xkbcomp &
  - +xdpyprobe
- x-pulseaudio
    - libogg &
    - `--`
    - libopus &
    - libflac &
    - libvorbis &
    - `--`
    - libsndfile
    - pulseaudio
- x-xrdp
  - libxrandr `===`
  - fdkaac
  - xrdp
- x-dropbear
  - dropbear
- xcompmgr
  - Xdamage `===`
  - xcompmgr
- xperp
  - perp


> part2: imlib2 gtk2

- u-gtk
  - deps
    - pango libxrandr Xdamage
    - `-lrsvg-2 -lcroco-0.6` @v-tint2
  - atk
  - gdk-pixbuf
  - gtk
- u-misc
  - su_exec
  - lrzsz
  - n2n
  - tinc
- v-xlunch
  - imlib2 `===`
  - xlunch
- v-feh
  - v-xlunch/build.sh imlib2
  - v-tint2/build.sh xcbutil & ##need?
  - v-tint2/build.sh libxi &
  - feh
- v-tint2 `cmake`
  - `apk add xorg-server-dev;`
  - v-xlunch/build.sh imlib2
  - libcroco #`libcroco >deps: imlib2`
  - librsvg & #`librsvg> libcroco >deps: imlib2`
  - xcbutil &
  - libxi &
  - tint2
- v-lxde `gtk224`
  - lxappearance
  - lxtask
- v-pcmanfm `gtk224`
  - `apkdeps`
  - libfm
  - menu-cache
  - pcmanfm
- v-geany `gtk224`
  - copy.tpl


```bash
# openbox
function apkdeps(){ #avoid mutli-build apk lock
  log "Installing required Alpine packages..."
  apk --no-cache add \
    curl \
    build-base \
    clang \
    meson \
    pkgconfig \
    patch \
    glib-dev
  xx-apk --no-cache --no-scripts add \
    g++ \
    glib-dev \
    glib-static \
    fribidi-dev \
    fribidi-static \
    harfbuzz-dev \
    harfbuzz-static \
    cairo-dev \
    cairo-static \
    libxft-dev \
    libxml2-dev \
    libx11-dev \
    libx11-static \
    libxcb-static \
    libxdmcp-dev \
    libxau-dev \
    freetype-static \
    expat-static \
    libpng-dev \
    libpng-static \
    zlib-static \
    bzip2-static \
    pcre-dev \
    libxrender-dev \
    graphite2-static \
    libffi-dev \
    xz-dev \
    brotli-static

  apk add expat-static #fontconfig
}

# u-gtk
function apkdeps(){
  apk update; 
  apk add gtk-doc shared-mime-info \
    gobject-introspection-dev \
    \
    gtk-doc intltool vala \
      gtk+2.0-dev \
    \
    fontconfig-static libxcomposite-dev #pcmanfm
}

# pcmanfm
function apkdeps(){
  apk update; 
  apk add gtk-doc shared-mime-info \
    gobject-introspection-dev \
    \
    gtk-doc intltool vala \
      menu-cache-dev gtk+2.0-dev menu-cache-dev \
    \
    fontconfig-static libxcomposite-dev #pcmanfm
}

```