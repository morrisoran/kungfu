#!/bin/bash

# download sch pls to tmp

source /var/lib/mss/netupdate.conf
# Set some variables
LOCALVERSION=`cat /var/lib/mss/version`
MYSELF=`ssh -p $PORT $USER@$SERVER grep $MYNAME $HOSTLIST | grep -v \^#`

# Get apropriate programm version and full path to it from fileserver
CUTOMER=`echo "$MYSELF" | awk '{print $2}'`
VERSION=`echo "$MYSELF" | awk '{print $3}'`
ROOT=`echo "$MYSELF" | awk '{print $4}'`
UPDATEDIR=$ROOT/$CUTOMER
MYIP=`ssh -p $PORT $USER@$SERVER 'echo $SSH_CLIENT | cut -d " " -f 1'`

rsync -HLavcx -e "ssh -p $PORT" $USER@$SERVER:$UPDATEDIR/"$VERSION"_\*/playlists/ /tmp/playlists
rsync -HLavcx -e "ssh -p $PORT" $USER@$SERVER:$UPDATEDIR/"$VERSION"_\*/schedule.mss /tmp/schedule.mss

# do work

echo "Check version v$VERSION"
sdb="/tmp/smart_db.dat"

echo -n "" > "$sdb"

# read schedule
sch=$(cat /tmp/schedule.mss|sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'|sed -e 's/ [0-9] /%$%/g'|tr -d "%$%"|sed -e 's/\s\{1,\}/\n/g')
echo -n "" > /tmp/smart_db.dat
echo "$sch" | while IFS= read -r line
do
 curfile="/tmp/playlists/$line.m3u"
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


filez=$(find /var/lib/mss/|grep ."mp3")
nel=1
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
  if (( nel == 1 ))
  then
   echo ""
  fi
  echo -n "NOT ::: $dumbfile"
  rm -f "$dumbfile"
  nel=0
 else
  if (( nel == 0 ))
  then
   echo ""
  fi
  echo -n "."
  nel=1
 fi
done

# clean it

rm -f "$sdb"
rm -f "/tmp/schedule.mss"
rm -rf "/tmp/playlists/"
find /var/lib/mss/ -type d -empty -delete