#!/bin/ksh

do_summary()
{
TMPDIR=.
MEMFILE=$TMPDIR/jfs2mem.kdb
NAMFILE=$TMPDIR/jfs2mem.name
echo pile | kdb  > pile.out
grep -v "(0)" pile.out | awk '{
a=1
while (status=getline >0)
{
        if ( a == 1 )
        {
                if   (substr($0,0,7) != "ADDRESS" )
                        continue;
                else
                {
                        a = 0;
                        continue;
                }
        }


        split ($0,temp)
        printf("%16s  %16d\n",temp[2],temp[3]);

}
}' > $MEMFILE
awk '{print $1}' $MEMFILE|sort -u > $NAMFILE

sumkbytes=0
while read name; do
        sumpages=0
        grep -w $name $MEMFILE | awk '{print $2}'| while read pages; do
                let sumpages=sumpages+pages
        done
        let kbytes=sumpages*4
        printf "%16s  %16d kbytes\n" $name $kbytes
        let sumkbytes=sumkbytes+kbytes
done < $NAMFILE
echo "========================================"
echo "TOTAL JFS2 kernel heap usage: $sumkbytes kbytes"
/bin/rm $MEMFILE
/bin/rm $NAMFILE

}


do_detail()
{
echo pile | kdb >  pile.out
grep -v "(0)" pile.out | awk '{
a=1
sumpages=0
while (status=getline >0)
{
        if ( a == 1 )
        {
                if   (substr($0,0,7) != "ADDRESS" )
                        continue;
                else
                {
                        a = 0;
                        continue;
                }
        }


        split ($0,temp)
        printf("%16s  %16d kbytes\n",temp[2],temp[3]*4);
        sumpages = sumpages + temp[3];

}
        printf("========================================\n");
        printf("TOTAL JFS2 kernel heap usage:  %d kbytes\n", sumpages*4);
}'

}


if [ "$1" = "-s" ]; then
	do_summary
else
	do_detail
fi
