
## headless's cmds

```bash
# ./_static_pulse/pactl ==> headless's pid.pulseaudio OK;
# headless @ tenvm2 in .../usr-local-static/_static_pulse |09:43:09  
$ pactl info
Server String: /tmp/pulse-9JaJ8gGF7xoi/native
Library Protocol Version: 33
Server Protocol Version: 33
Is Local: yes
Client Index: 10
Tile Size: 65472
User Name: headless
Host Name: tenvm2
Server Name: pulseaudio
Server Version: 13.99.1
Default Sample Specification: s16le 2ch 44100Hz
Default Channel Map: front-left,front-right
Default Sink: xrdp-sink
Default Source: xrdp-source
Cookie: 12d0:48d6
# headless @ tenvm2 in .../usr-local-static/_static_pulse |09:43:14  
# $ ls
# pacat  pacmd  pactl  pasuspender  pulseaudio
# headless @ tenvm2 in .../usr-local-static/_static_pulse |09:43:16  
$ ./pactl info
Server String: /tmp/pulse-9JaJ8gGF7xoi/native
Library Protocol Version: 34
Server Protocol Version: 33
Is Local: yes
Client Index: 11
Tile Size: 65472
User Name: headless
Host Name: tenvm2
Server Name: pulseaudio
Server Version: 13.99.1
Default Sample Specification: s16le 2ch 44100Hz
Default Channel Map: front-left,front-right
Default Sink: xrdp-sink
Default Source: xrdp-source
Cookie: 12d0:48d6

```

**pulse.pa modules**

- module-native-protocol-unix
- module-augment-properties
- module-always-sink
- module-x11-publish
- 
- /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
- /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so

```bash
# /tmp
headless @ tenvm2 in .../usr-local-static/_static_pulse |09:43:21  
$ find /tmp/ |grep pulse
/tmp/pulse-9JaJ8gGF7xoi
/tmp/pulse-9JaJ8gGF7xoi/pid
/tmp/pulse-9JaJ8gGF7xoi/native
/tmp/.headless/pulse-4711.pa

# $ cat /tmp/.headless/pulse-4711.pa
# https://hub.fastgit.org/jessfraz/dockerfiles/blob/master/pulseaudio/default.pa
.fail
  # Accept clients -- very important
  load-module module-native-protocol-unix
  #static 4711: can only with one VNC_LIMIT.
  #load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;192.168.0.0/24 auth-anonymous=1 port=4711

.nofail
  load-module module-augment-properties
  load-module module-always-sink
  # Publish to X11 so the clients know how to connect to Pulse. Will clear itself on unload.
  .ifexists module-x11-publish.so
      load-module module-x11-publish
  .endif

  # xrdp-sink/source
  .ifexists /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
      load-module /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
  .endif
  .ifexists /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so
      load-module /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so
  .endif


# $ find /usr/lib |grep module-x11-publish
/usr/lib/pulse-13.99.1/modules/module-x11-publish.so
```


## static's dbg

- cmd01

```bash
# /mnt2/_misc2/fk-pulseaudio $ /usr/local/static/pulseaudio/bin/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1
W: [pulseaudio] caps.c: Normally all extra capabilities would be dropped now, but that\'s impossible because PulseAudio was built without capabilities support.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:284 set_one_rlimit()] setrlimit(RLIMIT_NICE, (31, 31)) failed: Operation not permitted
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:284 set_one_rlimit()] setrlimit(RLIMIT_RTPRIO, (9, 9)) failed: Operation not permitted
(   0.000|   0.000) D: [pulseaudio][pulsecore/core-rtclock.c:164 pa_rtclock_hrtimer_enable()] Timer slack is set to 50 us.
(   0.000|   0.000) I: [pulseaudio][pulsecore/core-util.c:751 pa_raise_priority()] Failed to acquire high-priority scheduling: Permission denied
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:919 main()] This is PulseAudio 13.99.3-45-gdb40e
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:920 main()] Compilation host: x86_64-pc-linux-musl
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:921 main()] Compilation CFLAGS: -Os -fomit-frame-pointer -Wall -W -Wextra -pipe -Wno-long-long -Wno-overlength-strings -Wundef -Wformat=2 -Wsign-compare -Wformat-security -Wmissing-include-dirs -Wformat-nonliteral -Wold-style-definition -Wpointer-arith -Winit-self -Wdeclaration-after-statement -Wfloat-equal -Wmissing-prototypes -Wstrict-prototypes -Wredundant-decls -Wmissing-declarations -Wmissing-noreturn -Wshadow -Wendif-labels -Wcast-align -Wstrict-aliasing -Wwrite-strings -Wno-unused-parameter -fno-common -fdiagnostics-show-option -fdiagnostics-color=auto
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:928 main()] Running on host: Linux x86_64 5.4.0-163-generic #180-Ubuntu SMP Tue Sep 5 13:21:23 UTC 2023
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:931 main()] Found 2 CPUs.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:933 main()] Page size is 4096 bytes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:938 main()] Compiled with Valgrind support: no
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:941 main()] Running in valgrind mode: no
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:943 main()] Running in VM: yes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:946 main()] Running from build tree: no
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:952 main()] Optimized build: yes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:960 main()] FASTPATH defined, only fast path asserts disabled.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:969 main()] Machine ID is 9cb4d46fe30d.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:979 main()] Using runtime directory /home/sam/.config/pulse/9cb4d46fe30d-runtime.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:984 main()] Using state directory /home/sam/.config/pulse.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:987 main()] Using modules directory /usr/local/static/pulseaudio/lib/pulse-13.99/modules.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:989 main()] Running in system mode: no
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:1019 main()] System supports high resolution timers
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:1033 main()] A01
(   0.000|   0.000) D: [pulseaudio][pulsecore/memblock.c:859 pa_mempool_new()] Using shared memfd memory pool with 1024 slots of size 64.0 KiB each, total size is 64.0 MiB, maximum usable slot size is 65472
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1072 main()] A02
(   0.002|   0.001) I: [pulseaudio][pulsecore/cpu-x86.c:108 pa_cpu_get_x86_flags()] CPU flags: CMOV MMX SSE SSE2 SSE3 SSSE3 SSE4_1 SSE4_2 
(   0.002|   0.000) I: [pulseaudio][pulsecore/svolume_mmx.c:246 pa_volume_func_init_mmx()] Initialising MMX optimized volume functions.
(   0.002|   0.000) I: [pulseaudio][pulsecore/remap_mmx.c:149 pa_remap_func_init_mmx()] Initialising MMX optimized remappers.
(   0.002|   0.000) I: [pulseaudio][pulsecore/svolume_sse.c:257 pa_volume_func_init_sse()] Initialising SSE2 optimized volume functions.
(   0.002|   0.000) I: [pulseaudio][pulsecore/remap_sse.c:148 pa_remap_func_init_sse()] Initialising SSE2 optimized remappers.
(   0.002|   0.000) I: [pulseaudio][pulsecore/sconv_sse.c:167 pa_convert_func_init_sse()] Initialising SSE2 optimized conversions.
(   0.002|   0.000) I: [pulseaudio][daemon/main.c:1092 main()] A03
(   0.002|   0.000) I: [pulseaudio][daemon/main.c:1108 main()] A032
(   0.002|   0.000) I: [pulseaudio][daemon/main.c:1150 main()] A04
(   0.002|   0.000) I: [pulseaudio][daemon/main.c:1177 main()] Daemon startup complete.
(   0.002|   0.000) I: [pulseaudio][daemon/main.c:1182 main()] A05


# /mnt2/_misc2/fk-pulseaudio $ ./src//pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1
W: [pulseaudio] caps.c: Normally all extra capabilities would be dropped now, but that\'s impossible because PulseAudio was built without capabilities support.
N: [pulseaudio] daemon-conf.c: Detected that we are run from the build tree, fixing search path.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:284 set_one_rlimit()] setrlimit(RLIMIT_NICE, (31, 31)) failed: Operation not permitted
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:284 set_one_rlimit()] setrlimit(RLIMIT_RTPRIO, (9, 9)) failed: Operation not permitted
(   0.000|   0.000) D: [pulseaudio][pulsecore/core-rtclock.c:164 pa_rtclock_hrtimer_enable()] Timer slack is set to 50 us.
(   0.000|   0.000) I: [pulseaudio][pulsecore/core-util.c:751 pa_raise_priority()] Failed to acquire high-priority scheduling: Permission denied
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:919 main()] This is PulseAudio 13.99.3-45-gdb40e
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:920 main()] Compilation host: x86_64-pc-linux-musl
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:921 main()] Compilation CFLAGS: -Os -fomit-frame-pointer -Wall -W -Wextra -pipe -Wno-long-long -Wno-overlength-strings -Wundef -Wformat=2 -Wsign-compare -Wformat-security -Wmissing-include-dirs -Wformat-nonliteral -Wold-style-definition -Wpointer-arith -Winit-self -Wdeclaration-after-statement -Wfloat-equal -Wmissing-prototypes -Wstrict-prototypes -Wredundant-decls -Wmissing-declarations -Wmissing-noreturn -Wshadow -Wendif-labels -Wcast-align -Wstrict-aliasing -Wwrite-strings -Wno-unused-parameter -fno-common -fdiagnostics-show-option -fdiagnostics-color=auto
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:928 main()] Running on host: Linux x86_64 5.4.0-163-generic #180-Ubuntu SMP Tue Sep 5 13:21:23 UTC 2023
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:931 main()] Found 2 CPUs.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:933 main()] Page size is 4096 bytes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:938 main()] Compiled with Valgrind support: no
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:941 main()] Running in valgrind mode: no
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:943 main()] Running in VM: yes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:946 main()] Running from build tree: yes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:952 main()] Optimized build: yes
(   0.000|   0.000) D: [pulseaudio][daemon/main.c:960 main()] FASTPATH defined, only fast path asserts disabled.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:969 main()] Machine ID is 9cb4d46fe30d.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:979 main()] Using runtime directory /home/sam/.config/pulse/9cb4d46fe30d-runtime.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:984 main()] Using state directory /home/sam/.config/pulse.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:987 main()] Using modules directory /mnt2/_misc2/fk-pulseaudio/src.
(   0.000|   0.000) I: [pulseaudio][daemon/main.c:989 main()] Running in system mode: no
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1019 main()] System supports high resolution timers
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1033 main()] A01
(   0.002|   0.001) D: [pulseaudio][pulsecore/memblock.c:859 pa_mempool_new()] Using shared memfd memory pool with 1024 slots of size 64.0 KiB each, total size is 64.0 MiB, maximum usable slot size is 65472
(   0.014|   0.011) I: [pulseaudio][daemon/main.c:1072 main()] A02
(   0.016|   0.001) I: [pulseaudio][pulsecore/cpu-x86.c:108 pa_cpu_get_x86_flags()] CPU flags: CMOV MMX SSE SSE2 SSE3 SSSE3 SSE4_1 SSE4_2 
(   0.016|   0.000) I: [pulseaudio][pulsecore/svolume_mmx.c:246 pa_volume_func_init_mmx()] Initialising MMX optimized volume functions.
(   0.016|   0.000) I: [pulseaudio][pulsecore/remap_mmx.c:149 pa_remap_func_init_mmx()] Initialising MMX optimized remappers.
(   0.016|   0.000) I: [pulseaudio][pulsecore/svolume_sse.c:257 pa_volume_func_init_sse()] Initialising SSE2 optimized volume functions.
(   0.016|   0.000) I: [pulseaudio][pulsecore/remap_sse.c:148 pa_remap_func_init_sse()] Initialising SSE2 optimized remappers.
(   0.016|   0.000) I: [pulseaudio][pulsecore/sconv_sse.c:167 pa_convert_func_init_sse()] Initialising SSE2 optimized conversions.
(   0.016|   0.000) I: [pulseaudio][daemon/main.c:1092 main()] A03
(   0.016|   0.000) I: [pulseaudio][daemon/main.c:1108 main()] A032
(   0.016|   0.000) I: [pulseaudio][daemon/main.c:1150 main()] A04
(   0.016|   0.000) I: [pulseaudio][daemon/main.c:1177 main()] Daemon startup complete.
(   0.016|   0.000) I: [pulseaudio][daemon/main.c:1182 main()] A05
```

- cmd02 dbg

```bash
# 
# /mnt2/_misc2/fk-pulseaudio $ ./src//pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -nF ./_t1/pulse.pa
(   0.001|   0.000) I: [pulseaudio][pulsecore/sconv_sse.c:167 pa_convert_func_init_sse()] Initialising SSE2 optimized conversions.
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1092 main()] A03
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1108 main()] A032
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1119 main()] A033 ##A032解析文件过了;
(   0.001|   0.000) D: [pulseaudio][pulsecore/cli-command.c:2211 pa_cli_command_execute_file()] Parsing script '/mnt2/_misc2/fk-pulseaudio/./_t1/pulse.pa'
Segmentation fault (core dumped)

# /mnt2/_misc2/fk-pulseaudio $ ./src/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -nF ./_t1/pulse.pa 
(   0.004|   0.000) I: [pulseaudio][daemon/main.c:1092 main()] A03
(   0.004|   0.000) I: [pulseaudio][daemon/main.c:1108 main()] A032
(   0.004|   0.000) I: [pulseaudio][daemon/main.c:1119 main()] A033
(   0.004|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2239 pa_cli_command_execute()] .include /mnt2/_misc2/fk-pulseaudio/./_t1/pulse.pa
(   0.005|   0.001) D: [pulseaudio][pulsecore/cli-command.c:2213 pa_cli_command_execute_file()] Parsing script '/mnt2/_misc2/fk-pulseaudio/./_t1/pulse.pa'
(   0.005|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2182 pa_cli_command_execute_file_stream()] .fail
(   0.005|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2182 pa_cli_command_execute_file_stream()]   # Accept clients -- very important
(   0.005|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2182 pa_cli_command_execute_file_stream()]   load-module module-native-protocol-unix
Segmentation fault (core dumped)


# fixed: module.c//pa_module_load() ==> //新注释: m->init(m)
# /mnt2/_misc2/fk-pulseaudio $ ./src/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -nF ./_t1/pulse.pa
(   0.005|   0.000) I: [pulseaudio][daemon/main.c:1092 main()] A03
(   0.005|   0.000) I: [pulseaudio][daemon/main.c:1108 main()] A032
(   0.005|   0.000) I: [pulseaudio][daemon/main.c:1119 main()] A033
(   0.005|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2240 pa_cli_command_execute()] .include /mnt2/_misc2/fk-pulseaudio/./_t1/pulse.pa
(   0.006|   0.001) D: [pulseaudio][pulsecore/cli-command.c:2214 pa_cli_command_execute_file()] Parsing script '/mnt2/_misc2/fk-pulseaudio/./_t1/pulse.pa'
(   0.007|   0.001) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()] .fail
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   # Accept clients -- very important
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   load-module module-native-protocol-unix
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:437 pa_cli_command_load()] module-native-protocol-unix
(   0.007|   0.000) I: [pulseaudio][pulsecore/module.c:205 pa_module_load()] Loaded "module-native-protocol-unix" (index: #0; argument: "").
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   #static 4711: can only with one VNC_LIMIT.
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   #load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;192.168.0.0/24 auth-anonymous=1 port=4711
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()] .nofail
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   load-module module-augment-properties
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:437 pa_cli_command_load()] module-augment-properties
(   0.007|   0.000) I: [pulseaudio][pulsecore/module.c:205 pa_module_load()] Loaded "module-augment-properties" (index: #1; argument: "").
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   load-module module-always-sink
(   0.007|   0.000) I: [pulseaudio][pulsecore/cli-command.c:437 pa_cli_command_load()] module-always-sink
(   0.008|   0.000) I: [pulseaudio][pulsecore/module.c:205 pa_module_load()] Loaded "module-always-sink" (index: #2; argument: "").
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   # Publish to X11 so the clients know how to connect to Pulse. Will clear itself on unload.
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .ifexists module-x11-publish.so
(   0.008|   0.000) D: [pulseaudio][pulsecore/log.c:450 pa_log_levelv_meta()] Invalid UTF-8 string following below:
(   0.008|   0.000) D: [pulseaudio][pulsecore/module.c:93 pa_module_exists()] Checking for existence of 'p/.libs/module-x11-publish.so': failure
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]       load-module module-x11-publish
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .endif
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   # xrdp-sink/source
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .ifexists /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
(   0.008|   0.000) D: [pulseaudio][pulsecore/module.c:58 pa_module_exists()] Checking for existence of '/var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so': failure
(   0.008|   0.000) D: [pulseaudio][pulsecore/log.c:450 pa_log_levelv_meta()] Invalid UTF-8 string following below:
(   0.008|   0.000) D: [pulseaudio][pulsecore/module.c:93 pa_module_exists()] Checking for existence of 'p/.libs//var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so': failure
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]       load-module /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .endif
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .ifexists /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so
(   0.008|   0.000) D: [pulseaudio][pulsecore/module.c:58 pa_module_exists()] Checking for existence of '/var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so': failure
(   0.008|   0.000) D: [pulseaudio][pulsecore/log.c:450 pa_log_levelv_meta()] Invalid UTF-8 string following below:
(   0.008|   0.000) D: [pulseaudio][pulsecore/module.c:93 pa_module_exists()] Checking for existence of 'p/.libs//var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so': failure
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]       load-module /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so
(   0.008|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .endif
(   0.008|   0.000) I: [pulseaudio][daemon/main.c:1125 main()] A034
(   0.008|   0.000) I: [pulseaudio][daemon/main.c:1129 main()] A035
(   0.008|   0.000) I: [pulseaudio][daemon/main.c:1135 main()] A036
(   0.008|   0.000) I: [pulseaudio][daemon/main.c:1150 main()] A04
(   0.008|   0.000) I: [pulseaudio][daemon/main.c:1177 main()] Daemon startup complete.
(   0.008|   0.000) I: [pulseaudio][daemon/main.c:1182 main()] A05
^C(  18.304|  18.296) I: [pulseaudio][daemon/main.c:126 signal_callback()] Got signal SIGINT.
(  18.304|   0.000) I: [pulseaudio][daemon/main.c:153 signal_callback()] Exiting.
(  18.304|   0.000) I: [pulseaudio][daemon/main.c:1188 main()] Daemon shutdown initiated.
(  18.304|   0.000) I: [pulseaudio][pulsecore/module.c:265 pa_module_free()] Unloading "module-always-sink" (index: #2).
(  18.304|   0.000) I: [pulseaudio][pulsecore/module.c:291 pa_module_free()] Unloaded "module-always-sink" (index: #2).
(  18.304|   0.000) I: [pulseaudio][pulsecore/module.c:265 pa_module_free()] Unloading "module-augment-properties" (index: #1).
(  18.304|   0.000) I: [pulseaudio][pulsecore/module.c:291 pa_module_free()] Unloaded "module-augment-properties" (index: #1).
(  18.304|   0.000) I: [pulseaudio][pulsecore/module.c:265 pa_module_free()] Unloading "module-native-protocol-unix" (index: #0).
Segmentation fault (core dumped)

# 
```

**module deps**

- module-native-protocol-unix
- module-augment-properties
- module-always-sink
- module-x11-publish

```bash
headless @ tenvm2 in ~ |13:54:33  
# $ ldd  /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
	linux-vdso.so.1 (0x00007ffe8c3f9000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2d3e3c3000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f2d3e5c7000)
# $ ldd  /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so
	linux-vdso.so.1 (0x00007ffe059c9000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe14fb28000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fe14fd2c000)

headless @ tenvm2 in ~ |13:56:08  
# $ ldd /usr/lib/pulse-13.99.1/modules/module-x11-publish.so |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007fec5768d000)
	libFLAC.so.8 => /lib/x86_64-linux-gnu/libFLAC.so.8 (0x00007fec56ac8000)
	libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007fec572d8000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007fec5719b000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007fec56b0e000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007fec56b06000)
	libapparmor.so.1 => /lib/x86_64-linux-gnu/libapparmor.so.1 (0x00007fec56b26000)
	libasyncns.so.0 => /lib/x86_64-linux-gnu/libasyncns.so.0 (0x00007fec56b3b000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007fec567e1000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fec572dd000)
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007fec56fe7000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fec56b16000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007fec56836000)
	libgomp.so.1 => /lib/x86_64-linux-gnu/libgomp.so.1 (0x00007fec5699e000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007fec567be000)
	libltdl.so.7 => /lib/x86_64-linux-gnu/libltdl.so.7 (0x00007fec57190000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007fec56954000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fec56975000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fec56dfe000)
	libnsl.so.1 => /lib/x86_64-linux-gnu/libnsl.so.1 (0x00007fec56819000)
	libogg.so.0 => /lib/x86_64-linux-gnu/libogg.so.0 (0x00007fec56abb000)
	liborc-0.4.so.0 => /lib/x86_64-linux-gnu/liborc-0.4.so.0 (0x00007fec57038000)
	libprotocol-native.so => /usr/lib/pulse-13.99.1/modules/libprotocol-native.so (0x00007fec57527000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fec574d1000)
	libpulse.so.0 => /lib/x86_64-linux-gnu/libpulse.so.0 (0x00007fec570bd000)
	libpulsecommon-13.99.so => /usr/lib/x86_64-linux-gnu/pulseaudio/libpulsecommon-13.99.so (0x00007fec57550000)
	libpulsecore-13.99.so => /usr/lib/x86_64-linux-gnu/pulseaudio/libpulsecore-13.99.so (0x00007fec575d2000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007fec567fb000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fec56b1c000)
	libsndfile.so.1 => /lib/x86_64-linux-gnu/libsndfile.so.1 (0x00007fec57112000)
	libsoxr.so.0 => /lib/x86_64-linux-gnu/libsoxr.so.0 (0x00007fec56f4d000)
	libspeexdsp.so.1 => /lib/x86_64-linux-gnu/libspeexdsp.so.1 (0x00007fec56fb8000)
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007fec56d4d000)
	libtdb.so.1 => /lib/x86_64-linux-gnu/libtdb.so.1 (0x00007fec56fcd000)
	libvorbis.so.0 => /lib/x86_64-linux-gnu/libvorbis.so.0 (0x00007fec56a8d000)
	libvorbisenc.so.2 => /lib/x86_64-linux-gnu/libvorbisenc.so.2 (0x00007fec569e2000)
	libwrap.so.0 => /lib/x86_64-linux-gnu/libwrap.so.0 (0x00007fec56d41000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007fec574f4000)
	linux-vdso.so.1 (0x00007ffda45d6000)

# x4 cnt:
$ ldd /usr/lib/pulse-13.99.1/modules/module-x11-publish.so |sort |wc
     39     152    2944
$ ldd /usr/lib/pulse-13.99.1/modules/module-native-protocol-unix.so |sort |wc
     39     152    2944
$ ldd /usr/lib/pulse-13.99.1/modules/module-augment-properties.so |sort |wc
     38     148    2844
$ ldd /usr/lib/pulse-13.99.1/modules/module-always-sink.so |sort |wc
     38     148    2844

# protocol
# $ find /usr/lib |grep pulse |grep protoc |sort
/usr/lib/pulse-13.99.1/modules/libprotocol-cli.so
/usr/lib/pulse-13.99.1/modules/libprotocol-http.so
/usr/lib/pulse-13.99.1/modules/libprotocol-native.so
/usr/lib/pulse-13.99.1/modules/libprotocol-simple.so
/usr/lib/pulse-13.99.1/modules/module-cli-protocol-tcp.so
/usr/lib/pulse-13.99.1/modules/module-cli-protocol-unix.so
/usr/lib/pulse-13.99.1/modules/module-dbus-protocol.so
/usr/lib/pulse-13.99.1/modules/module-http-protocol-tcp.so
/usr/lib/pulse-13.99.1/modules/module-http-protocol-unix.so
/usr/lib/pulse-13.99.1/modules/module-native-protocol-fd.so
/usr/lib/pulse-13.99.1/modules/module-native-protocol-tcp.so
/usr/lib/pulse-13.99.1/modules/module-native-protocol-unix.so
/usr/lib/pulse-13.99.1/modules/module-simple-protocol-tcp.so
/usr/lib/pulse-13.99.1/modules/module-simple-protocol-unix.so
```



