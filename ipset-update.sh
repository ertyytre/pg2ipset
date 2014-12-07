#!/bin/bash

# ipset-update.sh (C) 2012 Matt Parnell http://www.mattparnell.com
# Licensed under the GNU-GPLv2+

# place to keep our cached blocklists
LISTDIR="/var/cache/blocklists"

# create cache directory for our lists if it isn't there
[ ! -d $LISTDIR ] && mkdir $LISTDIR

lists=(badpeers level1 level2 level3 spyware dshield bogon templist iana-multicast iana-reserved hijacked proxy ads-trackers-and-bad-pr0n)

for list in ${lists[@]}
do
        if [ eval $(curl -s -L http://www.bluetack.co.uk/config/$list.gz -o /tmp/$list.gz) ]; then
                mv /tmp/$list.gz $LISTDIR/$list.gz
        else
                echo "Using cached list for $list."
        fi

        ipset create -exist $list hash:net family inet maxelem 4294967295
        ipset create -exist $list-TMP hash:net family inet maxelem 4294967295
        ipset flush $list-TMP &> /dev/null
        zcat $LISTDIR/$list.gz | pg2ipset - - $list-TMP | ipset restore
        ipset swap $list $list-TMP
        ipset destroy $list-TMP
done

if [ -f $LISTDIR/custom.txt ]; then
	echo "Importing custom blocks..."
	ipset create -exist custom hash:net maxelem 4294967295
	ipset create -exist custom-TMP hash:net maxelem 4294967295
	ipset flush custom-TMP &> /dev/null
	awk '!x[$0]++' $LISTDIR/custom.txt | sed -e 's/^/\-A\ \-exist\ custom\ /' | ipset restore
	ipset swap custom custom-TMP
	ipset destroy custom-TMP
fi