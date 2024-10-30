#!/bin/bash

# link-bin,sbin
  echo -e "\n[link] /usr/sbin/"
  find /usr/local/static -type f |grep "/sbin/" |sort | \
    while read one; do ls -lh $one; ln -s $one /usr/sbin/; done; \

  echo -e "\n[link] /usr/bin/"
  find /usr/local/static -type f |grep "/bin/" |sort | \
    while read one; do ls -lh $one; ln -s $one /usr/bin/; done;
