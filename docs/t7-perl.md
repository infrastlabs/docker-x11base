
- https://github.com/pjlsergeant/alpine-perl-mini

**bin**

```bash
/opt/perl/bin # cat cpanm  |head -1
#!/usr/bin/env perl
/opt/perl/bin # ls |while read one; do match1=$(cat $one |head -1|grep -v perl); test ! -z "$match1" && echo "==$one" ; done
==perl
==perl5.32.0
/opt/perl/bin # ls -lhS
total 852K   
-rwxr-xr-x    1 root     root      295.7K Dec 18  2020 cpanm
-rwxr-xr-x    1 root     root       59.5K Dec 18  2020 h2xs
-rwxr-xr-x    1 root     root       50.0K Dec 18  2020 zipdetails
-rwxr-xr-x    2 root     root       44.2K Dec 18  2020 perlbug
-rwxr-xr-x    2 root     root       44.2K Dec 18  2020 perlthanks
-rwxr-xr-x    1 root     root       40.8K Dec 18  2020 enc2xs
-rwxr-xr-x    1 root     root       28.5K Dec 18  2020 h2ph
-rwxr-xr-x    2 root     root       20.2K Dec 18  2020 perl
-rwxr-xr-x    2 root     root       20.2K Dec 18  2020 perl5.32.0
-rwxr-xr-x    1 root     root       19.0K Dec 18  2020 splain
-rwxr-xr-x    1 root     root       15.4K Dec 18  2020 libnetcfg
-rwxr-xr-x    1 root     root       14.7K Dec 18  2020 corelist
-rwxr-xr-x    1 root     root       14.7K Dec 18  2020 pod2man
-rwxr-xr-x    1 root     root       13.3K Dec 18  2020 prove
-rwxr-xr-x    1 root     root       10.6K Dec 18  2020 perlivp
-rwxr-xr-x    1 root     root       10.6K Dec 18  2020 pod2text
-rwxr-xr-x    1 root     root        9.8K Dec 18  2020 shasum
-rwxr-xr-x    1 root     root        8.2K Dec 18  2020 cpan
-rwxr-xr-x    1 root     root        8.2K Dec 18  2020 piconv
-rwxr-xr-x    1 root     root        5.4K Dec 18  2020 streamzip
-rwxr-xr-x    1 root     root        5.1K Dec 18  2020 xsubpp
-rwxr-xr-x    1 root     root        4.9K Dec 18  2020 json_pp
-rwxr-xr-x    1 root     root        4.4K Dec 18  2020 pl2pm
-rwxr-xr-x    1 root     root        4.3K Dec 18  2020 ptargrep
-rwxr-xr-x    1 root     root        4.2K Dec 18  2020 instmodsh
-rwxr-xr-x    1 root     root        4.0K Dec 18  2020 pod2html
-rwxr-xr-x    1 root     root        3.9K Dec 18  2020 pod2usage
-rwxr-xr-x    1 root     root        3.6K Dec 18  2020 podchecker
-rwxr-xr-x    1 root     root        3.5K Dec 18  2020 ptar
-rwxr-xr-x    1 root     root        3.0K Dec 18  2020 encguess
-rwxr-xr-x    1 root     root        2.6K Dec 18  2020 ptardiff
-rwxr-xr-x    1 root     root         272 Dec 18  2020 perldoc
/opt/perl/bin # md5sum perl*
17724134e9b8eee8a00ffefae2900a77  perl
17724134e9b8eee8a00ffefae2900a77  perl5.32.0
8ecfb43191fbf27f4e0c07d2eeb2431b  perlbug
45b97406a874b9dd20472488a272e35f  perldoc
71f2b0ce54326126517b4db9d6ef9826  perlivp
8ecfb43191fbf27f4e0c07d2eeb2431b  perlthanks

/opt/perl/bin # ldd perl |sort
	/lib/ld-musl-x86_64.so.1 (0x7ff006fcc000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7ff006fcc000)
	libperl.so => /opt/perl/lib/5.32.0/x86_64-linux-thread-multi/CORE/libperl.so (0x7ff006c38000)

```

**lib**

```bash
/opt/perl/lib # du -sh *
56.2M	5.32.0
12.0K	site_perl
/opt/perl/lib # find site_perl/ |sort
site_perl/
site_perl/5.32.0
site_perl/5.32.0/x86_64-linux-thread-multi
/opt/perl/lib # cd 5.32.0/

/opt/perl/lib/5.32.0 # du -sh * |grep "M\t"
1.1M	ExtUtils #x70
3.6M	Unicode #x97
8.6M	pod #x204 Perl可在模块或脚本中嵌入 POD(Plain Old Documentation) 文档。 POD 是标记型语言(置标语言)。
5.2M	unicore #546
28.1M	x86_64-linux-thread-multi #x239


/opt/perl/lib/5.32.0/x86_64-linux-thread-multi # find . -type f |sort |grep "so$" |wc
       50        50      1359
/opt/perl/lib/5.32.0/x86_64-linux-thread-multi # find . -type f |sort |grep "so$"
./CORE/libperl.so
./auto/B/B.so
./auto/Compress/Raw/Bzip2/Bzip2.so
./auto/Compress/Raw/Zlib/Zlib.so
./auto/Cwd/Cwd.so
./auto/Data/Dumper/Dumper.so
./auto/Devel/Peek/Peek.so
./auto/Digest/MD5/MD5.so
./auto/Digest/SHA/SHA.so
./auto/Encode/Byte/Byte.so
./auto/Encode/CN/CN.so
./auto/Encode/EBCDIC/EBCDIC.so
./auto/Encode/Encode.so
./auto/Encode/JP/JP.so
./auto/Encode/KR/KR.so
./auto/Encode/Symbol/Symbol.so
./auto/Encode/TW/TW.so
./auto/Encode/Unicode/Unicode.so
./auto/Fcntl/Fcntl.so
./auto/File/DosGlob/DosGlob.so
./auto/File/Glob/Glob.so
./auto/Filter/Util/Call/Call.so
./auto/Hash/Util/FieldHash/FieldHash.so
./auto/Hash/Util/Util.so
./auto/I18N/Langinfo/Langinfo.so
./auto/IO/IO.so
./auto/IPC/SysV/SysV.so
./auto/List/Util/Util.so
./auto/MIME/Base64/Base64.so
./auto/Math/BigInt/FastCalc/FastCalc.so
./auto/Opcode/Opcode.so
./auto/POSIX/POSIX.so
./auto/PerlIO/encoding/encoding.so
./auto/PerlIO/mmap/mmap.so
./auto/PerlIO/scalar/scalar.so
./auto/PerlIO/via/via.so
./auto/SDBM_File/SDBM_File.so
./auto/Socket/Socket.so
./auto/Storable/Storable.so
./auto/Sys/Hostname/Hostname.so
./auto/Sys/Syslog/Syslog.so
./auto/Time/HiRes/HiRes.so
./auto/Time/Piece/Piece.so
./auto/Unicode/Collate/Collate.so
./auto/Unicode/Normalize/Normalize.so
./auto/attributes/attributes.so
./auto/mro/mro.so
./auto/re/re.so
./auto/threads/shared/shared.so
./auto/threads/threads.so

/opt/perl/lib/5.32.0/x86_64-linux-thread-multi # find . -type f |sort |egrep -v "so$|pm$|pl$"  |wc
       82        82      1415 ##./CORE/xxx.h
/opt/perl/lib/5.32.0/x86_64-linux-thread-multi # find . -type f |sort |egrep -v "so$|pm$|pl$|\.h$" 
./.packlist
./Config.pod
./POSIX.pod
```
