mysql consul 高可用

> Consul是用于分布式系统中服务发现和配置，如果mysql主从架构中，主服务器器当机，Consul就不会再将请求发送到这台机器，这里用作MySQL的自动故障转移工具。

[TOC]

# 整体架构图

| 主机名         | ip地址           | 监听端口 | 其他        |
| ----------- | -------------- | ---- | --------- |
| mastera     | 172.25.0.11    | 3306 | mysql服务器  |
| masterb     | 172.25.0.12    | 3306 | mysql服务器  |
| foundation0 | 172.25.254.250 | 8600 | consul服务器 |



![](pic/2.png)


# MySQL AB 复制

## 单主从步骤



```shell
	# 主服务器
	1）修改配置文件重启服务
    server-id=1
	log-bin=/var/lib/mysql-log/mastera
	log-slave-update
	2）授权从机	
	grant replication slave to slave@172.25.0.12 identified by 'uplooking';
	flush privileges;
	3）初始化数据一致	
	mysqldump -u -p -A --master-data=2 > /data/mysql.all.sql 
	传输给从机器

	# 从服务
	1）install
	2）修改配置文件	
	server-id=2
	log-bin=/var/lib/mysql-log/masterb 
	log-slave-update
	3）初始化数据一致	导入全备数据
	4）> change master master_host='172.25.0.11'
			master_user='slave'
			master_password='uplooking'
			master_log_file=''
			master_log_pos=''
	5)> start slave;
	6)> show slave status\G;
```



## 详细配置



```shell
## 主服务器

[root@mastera0 mysql]# vim /etc/my.cnf
[root@mastera0 mysql]# grep -v '^#' /etc/my.cnf|grep -v '^$'
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0
server-id=1
log-bin=/var/lib/mysql-log/mastera
log-slave-update
[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid
!includedir /etc/my.cnf.d

[root@mastera0 mysql]# systemctl restart mariadb
[root@mastera0 mysql]# mysql -uroot -puplooking
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 2
Server version: 5.5.44-MariaDB-log MariaDB Server

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> grant replication slave on *.* to slave@'172.25.0.12' identified by 'uplooking';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> \q
Bye
[root@mastera0 mysql]# mysqldump -uroot -puplooking -A --single-transaction --master-data=2 --flush-logs > /tmp/mysql.91.sql
[root@mastera0 mysql]# scp /tmp/mysql.91.sql root@172.25.0.12:/tmp
The authenticity of host \'172.25.0.12 (172.25.0.12)\' can\'t be established.
ECDSA key fingerprint is 91:2b:bd:df:0e:17:da:a0:f6:01:ff:5b:09:50:e8:ad.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.25.0.12' (ECDSA) to the list of known hosts.
root@172.25.0.12\'s password:
mysql.91.sql                                                      100%  505KB 504.7KB/s   00:00    

## 从服务器
[root@masterb0 ~]# yum install -y mariadb-server
[root@masterb0 ~]# vi /etc/my.cnf
	server-id=2
	log-bin=/var/lib/mysql-log/masterb 
	log-slave-update
[root@masterb0 ~]# systemctl start mariadb
[root@masterb0 ~]# mysql < /tmp/mysql.91.sql
[root@masterb0 ~]# mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 5.5.44-MariaDB MariaDB Server

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> \q
Bye
[root@masterb0 ~]# mysql
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
[root@masterb0 ~]# mysql -uroot -puplooking
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 5
Server version: 5.5.44-MariaDB MariaDB Server

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>


MariaDB [(none)]> change master to master_host='172.25.0.11',master_user='slave',master_password='uplooking',master_log_file='mastera.000028',MASTER_LOG_POS=245;
Query OK, 0 rows affected (0.21 sec)

MariaDB [(none)]> start slave;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.25.0.11
                  Master_User: slave
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mastera.000028
          Read_Master_Log_Pos: 245
               Relay_Log_File: mariadb-relay-bin.000002
                Relay_Log_Pos: 527
        Relay_Master_Log_File: mastera.000028
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 245
              Relay_Log_Space: 823
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
1 row in set (0.00 sec)

ERROR: No query specified

MariaDB [(none)]>
MariaDB [(none)]> select * from db1.t1;
+-----+
| id  |
+-----+
|   3 |
|   4 |
|   5 |
|   6 |
|   7 |
|   8 |
|   9 |
|  10 |
|  11 |
|  12 |
|  13 |
|  14 |
| 100 |
| 101 |
| 102 |
| 103 |
| 777 |
+-----+
17 rows in set (0.00 sec)

MariaDB [(none)]> \q
Bye
```

至此单主从配置完毕。

# consul 配置高可用

虽然利用mysql ab+keepalived能实现mysql高可用的方案，但是由于keepalived的应用场景有限，比如它的核心协议VRRP只能工作在局域网内，不能工作在局域网外（网间、广域网），而且在网络不受自己控制时基本不能用，除非设定好的VIP是供局域网使用。因此特别是在云计算环境中，使用云主机（例如阿里云ECS等）就不能用keepalived，因此只能寻找一个可替代keepalived的解决方案来替代它。**Consul作为服务注册、服务发现的最佳选择，无疑可以很好的替代keepalived。**利用consul的DNS Interface为上层应用提供MySQL（master的IP或者master宕机后slave的IP）。

## 安装consul

```shell
# install consul
[root@ToBeRoot ~]# mkdir /usr/local/consul/data -p
[root@ToBeRoot ~]# mkdir /usr/local/consul/config
[root@ToBeRoot ~]# ls
consul_0.8.5_linux_386.zip  dx_1.txt  dx_2.txt  foo  foo.sh  test
[root@ToBeRoot ~]# unzip consul_0.8.5_linux_386.zip 
Archive:  consul_0.8.5_linux_386.zip
  inflating: consul                  
[root@ToBeRoot ~]# ls
consul  consul_0.8.5_linux_386.zip  dx_1.txt  dx_2.txt  foo  foo.sh  test
[root@ToBeRoot ~]# mv consul /bin
```

## 修改配置文件

mysql.json配置如下

```shell
{
    "services": [
        {
	    "id":"mysqlnode1",
            "name": "mysql",
            "tags": [
                "master"
            ],
            "address": "172.25.0.11",
            "port": 3306,
    	    "checks": [
            {  
              "script": "bash /usr/local/consul/mysqltest.sh 172.25.0.11",
              "interval": "5s"
            }
          ]
        },
        {
	    "id":"mysqlnode2",
            "name": "mysql",
            "tags": [
                "master"
            ],
            "address": "172.25.0.12",
            "port": 3306,
    	    "checks": [
            {  
              "script": "bash /usr/local/consul/mysqltest.sh 172.25.0.12",
              "interval": "5s"
            }
          ]
        }
    ]
}
```

**json脚本的含义：**

1. `name`是consul为mysql服务提供的域名为`mysql.service.consul`；
2. `id`是节点名称；
3. `address`是节点对应的ip地址；
4. `port`是节点服务监听端口号；
5. `checks`是校验脚本，会按照脚本中指定的`interval`的值去执行，例如这里设定每5秒执行一次；
6. `script`脚本，consul判断脚本如果退出值为2则检测不通过，退出值为0则通过检测，通过检测的节点会被输出ip和监听端口；
7. `bash /usr/local/consul/mysqltest.sh 172.25.0.12` 具体解释如下。

其中调用的mysqltest.sh脚本如下

```shell
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
```

**脚本解释：**

1. 判断A：节点的mysqld进程是否alive，如果alive则，变量a=0，否则a!=0；

2. 判断B：节点的mysql是否是slave，如果是slave则，变量b=0，否则b!=0；

3. 判断C：节点是否是slave并且master已经宕掉，如果是则，变量c=0，否则c!=0；

4. 如果节点满足 条件A，并且 条件B和条件C 任意满足一个，则

   - 1）判断是否满足条件C；
     - 如果是则当前的情况为主服务器已宕机，我们需要停止从服务器去同步主的数据`stop slave`，清空从机的slave配置`reset slave all`；并记录从机器当前的日志号和position号，为重建主从做准备；
   - 2）退出值为0，让该节点被consul检测通过；

   否则，退出值为2，让其不被consul检测通过。





## 启动consul服务

指定consul的配置文件所在目录，并将标准输出重定向到指定的文件中，作为日志记录。

```shell
nohup consul agent -dev  -config-dir=/usr/local/consul/config &> /usr/local/consul/consul.log &
```



# DNS 转发

consul默认使用8600端口进行解析，如果向让consul是53号端口，需要使用bind、dnsmasq或者iptables来绑定consul。具体操作参考[官方文档](https://www.consul.io/docs/guides/forwarding.html)

以下用dnsmasq实现。

*注意开启dnsmasq时需要注意当前是否有进程占用53号端口。*

```shell
[root@foundation0 ~]# echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/10-consul 

[root@foundation0 ~]# systemctl start dnsmasq
[root@foundation0 ~]# systemctl status dnsmasq
● dnsmasq.service - DNS caching server.
   Loaded: loaded (/usr/lib/systemd/system/dnsmasq.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2017-07-06 17:51:56 CST; 5s ago
 Main PID: 28114 (dnsmasq)
   CGroup: /system.slice/dnsmasq.service
           └─28114 /usr/sbin/dnsmasq -k

Jul 06 17:51:56 foundation0.ilt.example.com systemd[1]: Started DNS caching server..
Jul 06 17:51:56 foundation0.ilt.example.com systemd[1]: Starting DNS caching server....
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: started, version 2.66 cachesize 150
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: compile time options: IPv6 GNU-getopt DBus no-i18n IDN DHCP DHCPv6 no-Lua TFT...t auth
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: using nameserver 127.0.0.1#8600 for domain consul
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: reading /etc/resolv.conf
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: ignoring nameserver 127.0.0.1 - local interface
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: using nameserver 127.0.0.1#8600 for domain consul
Jul 06 17:51:56 foundation0.ilt.example.com dnsmasq[28114]: read /etc/hosts - 2 addresses
Hint: Some lines were ellipsized, use -l to show in full.

[root@foundation0 ~]# echo "nameserver 127.0.0.1" > /etc/resolv.conf 

[root@foundation0 ~]# dig mysql.service.consul.

; <<>> DiG 9.9.4-RedHat-9.9.4-29.el7 <<>> mysql.service.consul.
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14261
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;mysql.service.consul.		IN	A

;; ANSWER SECTION:
mysql.service.consul.	0	IN	A	172.25.0.12

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Thu Jul 06 17:53:19 CST 2017
;; MSG SIZE  rcvd: 65

[root@foundation0 ~]# ping mysql.service.consul
PING mysql.service.consul (172.25.0.12) 56(84) bytes of data.
64 bytes from 172.25.0.12: icmp_seq=1 ttl=64 time=0.197 ms
64 bytes from 172.25.0.12: icmp_seq=2 ttl=64 time=0.287 ms
^C
--- mysql.service.consul ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1054ms
rtt min/avg/max/mdev = 0.197/0.242/0.287/0.045 ms
[root@foundation0 ~]# mysql -utest -puplooking -h mysql.service.consul
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 1346
Server version: 5.5.44-MariaDB-log MariaDB Server

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> select @@hostname;
+------------+
| @@hostname |
+------------+
| slave      |
+------------+
1 row in set (0.00 sec)

MariaDB [(none)]> exit
Bye
```

# 测试

1. 域名解析`dig mysql.service.consul.`
2. mysql客户端连接数据库服务器 `mysql -utest -puplooking -h mysql.service.consul `，连接的是mysqlnode1
3. mysqlnode1宕机后，consul会将解析改为mysqlnode2 ，并清除从机的配置为修复做准备
4. 手动完成主从修复，mysqlnode2为master，mysqlnode1为slave
5. mysqlnode2宕机后，consul会将解析改为mysqlnode1，并清除从机的配置为修复做准备
6. 手动完成主从修复，mysqlnode1为master，mysqlnode2为slave