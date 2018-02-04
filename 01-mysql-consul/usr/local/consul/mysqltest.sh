#!/bin/bash

mysqladmin -utest -puplooking -h $1 ping | grep "mysqld is alive" &> /dev/null; a=`echo $?`
mysql -utest -puplooking -h $1 -e "show slave status\G" | grep slave &> /dev/null; b=`echo $?`
mysql -utest -puplooking -h $1 -e "show slave status\G" | grep "error reconnecting to master" &> /dev/null ; c=`echo $?`
if [ $a -eq 0 ] && ([ $b -ne 0 ] || [ $c -eq 0 ])
then
	if [ $c -eq 0 ] 
	then
		mysql -utest -puplooking -h $1 -e 'stop slave;reset slave all'
		mysql -utest -puplooking -h $1 -e 'show master status'| awk '{if (NR==2) print $1,$2}' > /usr/local/consul/mysql.txt
	fi
        exit 0
else
        exit 2
fi
