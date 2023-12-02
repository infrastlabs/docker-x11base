
## bins

- xlunch
- xcompmgr
- pcmanfm
- 
- pulseaudio
- geany
- perp


```bash
# root@tenvm2:/mnt/_statics# ll -h
total 42M
drwxr-xr-x 2 root root 4.0K Nov 30 00:07 ./
drwxr-xr-x 6 root root 4.0K Nov 30 00:06 ../
-rwxr-xr-x 1 root root  38M Nov 30 00:06 pcmanfm*
-rwxr-xr-x 1 root root 1.1M Nov 30 00:07 xcompmgr*
-rwxr-xr-x 1 root root 3.5M Nov 30 00:07 xlunch*


# root@tenvm2:/mnt/_statics# ./xlunch  -h
./xlunch: option requires an argument: h
See --help for usage documentation
# root@tenvm2:/mnt/_statics# ./xcompmgr  -h
./xcompmgr: unrecognized option: h
./xcompmgr v1.1.6
usage: ./xcompmgr [options]
Options:
   -d display
      Specifies which display should be managed.
   -r radius
      Specifies the blur radius for client-side shadows. (default 12)
   -o opacity
      Specifies the translucency for client-side shadows. (default .75)
   -l left-offset
      Specifies the left offset for client-side shadows. (default -15)
   -t top-offset
      Specifies the top offset for clinet-side shadows. (default -15)
   -I fade-in-step
      Specifies the opacity change between steps while fading in. (default 0.028)
   -O fade-out-step
      Specifies the opacity change between steps while fading out. (default 0.03)
   -D fade-delta-time
      Specifies the time between steps in a fade in milliseconds. (default 10)
   -a
      Use automatic server-side compositing. Faster, but no special effects.
   -c
      Draw client-side shadows with fuzzy edges.
   -C
      Avoid drawing shadows on dock/panel windows.
   -f
      Fade windows in/out when opening/closing.
   -F
      Fade windows during opacity changes.
   -n
      Normal client-side compositing with transparency support
   -s
      Draw server-side shadows with sharp edges.
   -S
      Enable synchronous operation (for debugging).

# root@tenvm2:/mnt/_statics# ./pcmanfm  -h
(pcmanfm:301467): GModule-CRITICAL **: 00:08:29.947: g_module_symbol: assertion 'module != NULL' failed
(pcmanfm:301467): GModule-CRITICAL **: 00:08:29.947: g_module_close: assertion 'module != NULL' failed
Usage:
  pcmanfm [OPTION…] [FILE1, FILE2,...]  
Help Options:
  -h, --help                   Show help options
  --help-all                   Show all help options
  --help-gtk                   Show GTK+ Options

Application Options:
  -p, --profile=PROFILE        Name of configuration profile
  -d, --daemon-mode            Run PCManFM as a daemon
  --no-desktop                 No function. Just to be compatible with nautilus
  --desktop                    Launch desktop manager
  --desktop-off                Turn off desktop manager if it\'s running
  --desktop-pref               Open desktop preference dialog
  --one-screen                 Use --desktop option only for one screen
  -w, --set-wallpaper=FILE     Set desktop wallpaper from image FILE
  --wallpaper-mode=MODE        Set mode of desktop wallpaper. MODE=(color|stretch|fit|crop|center|tile|screen)
  --show-pref=N                Open Preferences dialog on the page N
  -n, --new-win                Open new window
  -f, --find-files             Open a Find Files window
  --role=ROLE                  Window role for usage by window manager
  --display=DISPLAY            X display to use
```