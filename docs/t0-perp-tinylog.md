

- sv xxx $mod
  - load配置更新
  - 查看服务日志
- tinylog
  - 运行0.2M
  - 配置 截断/保留/压缩

```bash
#### /etc/perp/xx/rc.log
#!/bin/sh
# rc.log generic perpetrate runscript
# using tinylog_run wrapper configured by /etc/tinylog.conf
# ===

if test ${1} = 'start' ; then
  exec tinylog_run ${2}
fi

exit 0


### runtool> gosu;
# root@x11-ubuntu:/etc/perp# cat /usr/bin/runtool 
#!/bin/bash
shift
shift
exec $@

### conf /etc/tinylog.conf 
export TINYLOG_USER=root #tinylog
export TINYLOG_BASE=/var/log/tinylog #/var/log
export TINYLOG_OPTS="-k2 -s1000"
```



