#!/bin/bash

cmd=$1
shift
args=$@

# http://b0llix.net/perp/site.cgi?page=perpctl.8
case "$cmd" in
status)
    if [ "" == "$args" ]; then
      perpls
    else
      perpstat $args
    fi
    ;;
start|stop)
    if [ "start" == "$cmd" ]; then
      perpctl up $args
    else
      perpctl down $args
    fi
    # D (meta-Down) # U (meta-Up)
    #   When  given  in  upper-case,  the  d  (down) and u (up) commands
    #   described above are applied to both the main and log services.
    ;;
enable|disable)
    if [ "enable" == "$cmd" ]; then
      perpctl A $args
    else
      perpctl X $args
    fi
    ;;
help)
    echo "example: sv status, sv start/stop xxx, sv enable/disable xxx, sv pause/continue xxx"
    ;;
    # a (alarm)
    # h (hup)
    # i (interrupt)
    # k (kill)
    # q (quit)
    # t (term)
    # w (winch)
    # 1 (usr1)
    # 2 (usr2)
    #     Send the service a corresponding signal: SIGALRM,  SIGHUP,  SIG-INT
    #     , SIGKILL, SIGQUIT, SIGTERM, SIGWINCH, SIGUSR1 or SIGUSR2.

*)
    perpctl $cmd $args
    ;;
esac
