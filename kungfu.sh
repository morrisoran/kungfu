#!/bin/bash
cat /var/lib/mss/version
sdb="/tmp/smart_db.dat"

echo -n "" > "$sdb"

# read schedule
sch=$(cat /var/lib/mss/schedule.mss|sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'|sed -e 's/ [0-9] /%$%/g'|tr -d "%$%"|sed -e 's/\s\{1,\}/\n/g')
echo -n "" > /tmp/smart_db.dat
echo "$sch" | while IFS= read -r line
do
 curfile="/var/lib/mss/playlists/$line.m3u"
 if [ -f $curfile ];
 then
  while read trackline
  do
   if [[ $trackline == *".mp3" ]];
   then
    echo "/var/lib/mss/$trackline" >> "$sdb"
    if [ ! -f "/var/lib/mss/$trackline" ];
    then
     echo -n "MIS ::: "
     echo "/var/lib/mss/$trackline"
    fi
   fi
  done < $curfile
 else
  if [[ $line == *".mp3" ]];
  then
   echo "/var/lib/mss/$line" >> "$sdb"
   if [ ! -f "/var/lib/mss/$line" ];
   then
    echo -n "MIS ::: "
    echo "/var/lib/mss/$line"
   fi
  fi
 fi
done


filez=$(find /var/lib/mss/|grep .mp3)
echo "$filez" | while IFS= read -r dumbfile
do
 ex=0
 if [[ $dumbfile == *"/tishina.mp3" ]]
 then
  continue
 fi
 while read dumbtrack
 do
  # echo "#$dumbfile#"
  # echo "%$dumbtrack%"
  if [ "$dumbfile" = "$dumbtrack" ]
  then
   ex=1
   break
  fi
 done < $sdb
 if (( ex == 0 ))
 then
  echo "NOT ::: $dumbfile"
  rm -f "$dumbfile"
 fi
done
rm -f "$sdb"
find /var/lib/mss/ -type d -empty -delete