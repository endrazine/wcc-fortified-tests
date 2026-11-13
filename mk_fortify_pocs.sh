#!/bin/bash

# Study all _FORTIFY_SOURCE functions
# Generates PoCs across 5 log tiers:
#   /tmp/witchcraft-pocs.log     SIGSEGV WRITE/EXEC (exploitable)
#   /tmp/witchcraft-abrt.log     SIGABRT (fortify/heap/stack check)
#   /tmp/witchcraft-reads.log    SIGSEGV READ (DoS / info leak)
#   /tmp/witchcraft-misc.log     SIGBUS/SIGILL/SIGFPE (other crashes)
#   /tmp/witchcraft-globals.log  Global variable writes (thread-safety)

# Clear previous logs
> /tmp/witchcraft-pocs.log
> /tmp/witchcraft-abrt.log
> /tmp/witchcraft-reads.log
> /tmp/witchcraft-misc.log
> /tmp/witchcraft-globals.log
> ./learnwitch.log

nm /usr/lib/x86_64-linux-gnu/libc.so.6 -D|grep chk|awk '{print $3}'|sed s#"@.*"##gi|sed s#"^_*"##|sed s#"_chk$"##| grep -vw read|while read fname
do
	echo " [+] Testing: $fname"
	echo "testfunc($fname, 10000); exit(0);" > /tmp/mkpocs.sh
	timeout -k 10s 10s wsh -s 1024 < /tmp/mkpocs.sh
	timeout -k 10s 10s wsh -s 42 < /tmp/mkpocs.sh
	timeout -k 10s 10s wsh -s 681749 < /tmp/mkpocs.sh
	timeout -k 10s 10s wsh -s 63 < /tmp/mkpocs.sh
	timeout -k 10s 10s wsh -s 9284 < /tmp/mkpocs.sh
	timeout -k 10s 10s wsh -s 17942 < /tmp/mkpocs.sh

done

echo ""
echo "=== Results ==="
echo "WRITE/EXEC PoCs : $(wc -l < /tmp/witchcraft-pocs.log) entries"
echo "SIGABRT crashes : $(wc -l < /tmp/witchcraft-abrt.log) entries"
echo "READ crashes    : $(wc -l < /tmp/witchcraft-reads.log) entries"
echo "SIGBUS/ILL/FPE  : $(wc -l < /tmp/witchcraft-misc.log) entries"
echo "Global writes   : $(wc -l < /tmp/witchcraft-globals.log) entries"
echo ""

# Unique functions per tier
echo "Unique functions with WRITE/EXEC PoCs:"
grep -oP '^\w+' /tmp/witchcraft-pocs.log 2>/dev/null | sort -u
echo ""
echo "Unique functions with SIGABRT:"
grep -oP '^\w+' /tmp/witchcraft-abrt.log 2>/dev/null | sort -u
echo ""
echo "=== learnwitch.log signal summary ==="
echo "Total SIG records : $(grep -c '^SIG ' ./learnwitch.log 2>/dev/null || echo 0)"
echo "Unique signals    : $(awk '/^SIG /{print $3}' ./learnwitch.log 2>/dev/null | sort -u | tr '\n' ' ')"
echo "CONTROLLED crashes: $(grep -c 'CONTROLLED' ./learnwitch.log 2>/dev/null || echo 0)"
echo ""

