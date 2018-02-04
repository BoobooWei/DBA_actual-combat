# Redis 主从高可用实施文档

| 实施时间       | 实施人    |
| ---------- | ------ |
| 2017-07-12 | Booboo |

[TOC]



# 1. 架构概览

## 1.1. 服务内容和监听端口概览

| 服务器   | ip          | Redis port  | Sentinel port | Consul port | Bind port |
| ----- | ----------- | ----------- | ------------- | ----------- | --------- |
| app01 | 192.168.3.1 | Master:6379 |               | 8600        | 53        |
| app02 | 192.168.3.2 | Slave:6379  | 26379         |             |           |

## 1.2. 服务安装目录概览

**Redis&sentinel**

| Redis | App01路径             | App02路径             |
| ----- | ------------------- | ------------------- |
| 家目录   | /alidata/redis      | /alidata/redis      |
| 配置文件  | /alidata/redis/conf | /alidata/redis/conf |
| 数据文件  | /alidata/redis/data | /alidata/redis/data |
| 日志文件  | /alidata/redis/log  | /alidata/redis/log  |

**Consul**

| consul | App01路径                    | App02路径                    |
| ------ | -------------------------- | -------------------------- |
| 家目录    | /alidata/consul            | /alidata/consul            |
| 配置文件   | /alidata/consul/conf       | /alidata/consul/conf       |
| 数据文件   | /alidata/consul/data       | /alidata/consul/data       |
| 日志文件   | /alidata/consul/consul.log | /alidata/consul/consul.log |



## 1.3. reids搭建概述

1. redis 主从 —— app01 redis-master app02 redis-slave :实现冗余；读写功能为：主读写，从只读；
2. redis sentinel——实现故障后的主从架构恢复，具体为：app01 redis服务宕掉， app02 redis服务自动从slave升为master，app01的redis服务手动恢复后，系统能够自动将app01重新加入redis主动架构中成为slave；
3. consul——自动发现服务，能够解析redis.service.consul为当前的主redis节点，实现自动故障转移；
4. 前端应用程序连接redis，需使用redis.service.consul域名访问。



## 1.4. 高可用描述

非硬件故障的情况下，高可用情况为：

1. Reids master 宕机后，需要30 秒左右的事件进行故障自动转移；
2. 恢复宕掉的节点，重新加入主从架构大概在10 秒左右。
3. sentinel和consul都有单点故障的风险，需要重点监控。



## 1.5. 常用命令

Redis的启动

\# /root/redisctl start 6379

sentinel的启动

\# /root/redisctl sentinel 26379

consul的启动

\# nohup /bin/consul agent -dev  -config-dir=/alidata/consul/conf &> /alidata/consul/consul.log &

服务的关闭可以查看进程号后使用kill -9 pid

 

## 1.6. 其他建议

将来redis的数据量多了建议迁移出来，会非常吃内存。

 

 

# 2. 高可用测试

## 2.1. 测试

1. app01上的redis主服务宕机后的自动故障转移

2. app01 redis以从机的身份重新加入主从架构

3. app02 上的redis主服务宕机后的自动故障转移

4. app02 redis以从机的身份重新加入主从架构

```shell
1. 测试app01故障转移
# 查看当前redis的状态
[root@erge-app-01 ~]# ps -ef|grep redi[s]
root     10996     1  0 12:32 ?        00:00:00 /alidata/redis/src/redis-server 192.168.3.1:6379
[root@erge-app-01 ~]# ps -ef|grep consul
root      3389  3202  1 11:01 pts/3    00:01:15 /bin/consul agent -dev -config-dir=/alidata/consul/conf
root     11337  5659  0 12:36 pts/6    00:00:00 grep --color=auto consul


[root@erge-app-02 ~]# ps -ef|grep redi[s]
root     10603     1  0 12:17 ?        00:00:01 /alidata/redis/src/redis-server 192.168.3.2:6379
root     10786     1  0 12:33 ?        00:00:00 /alidata/redis/src/redis-sentinel *:26379 [sentinel]

[zyadmin@erge-app-02 ~]$ tail -f /alidata/redis/log/sentinel26379.log
 |`-._`-._    `-.__.-'    _.-'_.-'|                                  
 |    `-._`-._        _.-'_.-'    |                                  
  `-._    `-._`-.__.-'_.-'    _.-'                                   
      `-._    `-.__.-'    _.-'                                       
          `-._        _.-'                                           
              `-.__.-'                                               

10786:X 12 Jul 12:33:46.874 # Sentinel ID is 5d46c21fea3cf9779c51a26d555bf003994c3aad
10786:X 12 Jul 12:33:46.875 # +monitor master mymaster 192.168.3.1 6379 quorum 2
10786:X 12 Jul 12:33:46.876 * +slave slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379

[root@erge-app-01 ~]# tail -f /alidata/consul/consul.log 
    2017/07/12 12:37:22 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: role:master
    2017/07/12 12:37:22 [DEBUG] agent: Check 'service:redisnode1' is passing
    2017/07/12 12:37:23 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:37:23 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:37:27 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: role:master
    2017/07/12 12:37:27 [DEBUG] agent: Check 'service:redisnode1' is passing
    2017/07/12 12:37:28 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:37:28 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:37:32 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: role:master
    2017/07/12 12:37:32 [DEBUG] agent: Check 'service:redisnode1' is passing
    2017/07/12 12:37:33 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:37:33 [WARN] agent: Check 'service:redisnode2' is now critical
	
	
[root@erge-app-01 ~]# ping -c 2 redis.service.consul
PING redis.service.consul (192.168.3.1) 56(84) bytes of data.
64 bytes from erge-app-01 (192.168.3.1): icmp_seq=1 ttl=64 time=0.025 ms
64 bytes from erge-app-01 (192.168.3.1): icmp_seq=2 ttl=64 time=0.036 ms

--- redis.service.consul ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.025/0.030/0.036/0.007 ms

# 关闭app01 redis服务
[root@erge-app-01 ~]# redis-cli shutdown

[root@erge-app-02 ~]# tail -f /alidata/redis/log/sentinel26379.log 
 |`-._`-._    `-.__.-'    _.-'_.-'|                                  
 |    `-._`-._        _.-'_.-'    |                                  
  `-._    `-._`-.__.-'_.-'    _.-'                                   
      `-._    `-.__.-'    _.-'                                       
          `-._        _.-'                                           
              `-.__.-'                                               

10913:X 12 Jul 12:43:21.316 # Sentinel ID is 86cc9ef992e888e694821d6969a656a253ba8f63
10913:X 12 Jul 12:43:21.316 # +monitor master mymaster 192.168.3.1 6379 quorum 1
10913:X 12 Jul 12:43:21.317 * +slave slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.617 # +sdown master mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.617 # +odown master mymaster 192.168.3.1 6379 #quorum 1/1
10913:X 12 Jul 12:44:07.617 # +new-epoch 1
10913:X 12 Jul 12:44:07.617 # +try-failover master mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.620 # +vote-for-leader 86cc9ef992e888e694821d6969a656a253ba8f63 1
10913:X 12 Jul 12:44:07.620 # +elected-leader master mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.620 # +failover-state-select-slave master mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.672 # +selected-slave slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.672 * +failover-state-send-slaveof-noone slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:07.727 * +failover-state-wait-promotion slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:08.142 # +promoted-slave slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:08.142 # +failover-state-reconf-slaves master mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:08.201 # +failover-end master mymaster 192.168.3.1 6379
10913:X 12 Jul 12:44:08.201 # +switch-master mymaster 192.168.3.1 6379 192.168.3.2 6379
10913:X 12 Jul 12:44:08.201 * +slave slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379
10913:X 12 Jul 12:44:38.241 # +sdown slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379

# consul的日志显示整个切换过程从12:43:37到12:44:08，一共个耗时31s

    2017/07/12 12:43:37 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:43:37 [DEBUG] agent: Service 'consul' in sync
    2017/07/12 12:43:37 [DEBUG] agent: Service 'redisnode1' in sync
    2017/07/12 12:43:37 [DEBUG] agent: Service 'redisnode2' in sync
    2017/07/12 12:43:37 [INFO] agent: Synced check 'service:redisnode1'
    2017/07/12 12:43:37 [DEBUG] agent: Check 'service:redisnode2' in sync
    2017/07/12 12:43:37 [DEBUG] agent: Node info in sync
    2017/07/12 12:43:38 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:43:38 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:43:42 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.1:6379: Connection refused
    2017/07/12 12:43:42 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:43:43 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:43:43 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:43:45 [DEBUG] manager: Rebalanced 1 servers, next active server is erge-app-01.dc1 (Addr: tcp/127.0.0.1:8300) (DC: dc1)
    2017/07/12 12:43:47 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.1:6379: Connection refused
    2017/07/12 12:43:47 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:43:48 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:43:48 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:43:52 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.1:6379: Connection refused
    2017/07/12 12:43:52 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:43:53 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:43:53 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:43:57 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.1:6379: Connection refused
    2017/07/12 12:43:57 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:43:58 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:43:58 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:44:02 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.1:6379: Connection refused
    2017/07/12 12:44:02 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:44:03 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: 
    2017/07/12 12:44:03 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:44:07 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.1:6379: Connection refused
    2017/07/12 12:44:07 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:44:08 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: role:master
    2017/07/12 12:44:08 [DEBUG] agent: Check 'service:redisnode2' is passing
	
# 域名已经自动解析为app02
[root@erge-app-01 ~]# ping -c 2 redis.service.consul
PING redis.service.consul (192.168.3.2) 56(84) bytes of data.
64 bytes from 192.168.3.2 (192.168.3.2): icmp_seq=1 ttl=64 time=0.325 ms
64 bytes from 192.168.3.2 (192.168.3.2): icmp_seq=2 ttl=64 time=0.244 ms

--- redis.service.consul ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.244/0.284/0.325/0.043 ms

[root@erge-app-01 ~]# redis-cli -h redis.service.consul info replication
# Replication
role:master
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
[root@erge-app-01 ~]# redis-cli -h redis.service.consul set test zy
OK
[root@erge-app-01 ~]# redis-cli -h redis.service.consul get test
"zy"

# 恢复故障节点app01
[root@erge-app-01 ~]# ./redisctl start 6379

# 查看sentinel日志

10913:X 12 Jul 12:48:05.567 # -sdown slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379
10913:X 12 Jul 12:48:15.519 * +convert-to-slave slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379

[root@erge-app-01 ~]# redis-cli info replication
# Replication
role:slave
master_host:192.168.3.2
master_port:6379
master_link_status:up
master_last_io_seconds_ago:2
master_sync_in_progress:0
slave_repl_offset:586
slave_priority:100
slave_read_only:1
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0

[root@erge-app-01 ~]# redis-cli -h redis.service.consul info replication
# Replication
role:master
connected_slaves:1
slave0:ip=192.168.3.1,port=6379,state=online,offset=8988,lag=0
master_repl_offset:8988
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:8987

故障转移成功！
===================================================
# 继续模拟app02故障
[root@erge-app-02 ~]# redis-cli shutdown

sentinel日志：
10913:X 12 Jul 12:51:24.102 # +sdown master mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.102 # +odown master mymaster 192.168.3.2 6379 #quorum 1/1
10913:X 12 Jul 12:51:24.102 # +new-epoch 2
10913:X 12 Jul 12:51:24.102 # +try-failover master mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.105 # +vote-for-leader 86cc9ef992e888e694821d6969a656a253ba8f63 2
10913:X 12 Jul 12:51:24.105 # +elected-leader master mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.105 # +failover-state-select-slave master mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.189 # +selected-slave slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.189 * +failover-state-send-slaveof-noone slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.251 * +failover-state-wait-promotion slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.408 # +promoted-slave slave 192.168.3.1:6379 192.168.3.1 6379 @ mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.408 # +failover-state-reconf-slaves master mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.496 # +failover-end master mymaster 192.168.3.2 6379
10913:X 12 Jul 12:51:24.496 # +switch-master mymaster 192.168.3.2 6379 192.168.3.1 6379
10913:X 12 Jul 12:51:24.496 * +slave slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:51:54.505 # +sdown slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379


consul日志 12:50:54~12:51:28 耗时32s

	2017/07/12 12:50:54 [WARN] agent: Check 'service:redisnode2' is now critical
......
    2017/07/12 12:51:23 [WARN] agent: Check 'service:redisnode1' is now critical
    2017/07/12 12:51:24 [DEBUG] agent: Check 'service:redisnode2' script 'redis-cli -h 192.168.3.2 -p 6379 info | grep role:master || exit 2' output: Could not connect to Redis at 192.168.3.2:6379: Connection refused
    2017/07/12 12:51:24 [WARN] agent: Check 'service:redisnode2' is now critical
    2017/07/12 12:51:28 [DEBUG] agent: Check 'service:redisnode1' script 'redis-cli -h 192.168.3.1 -p 6379 info | grep role:master || exit 2' output: role:master
    2017/07/12 12:51:28 [DEBUG] agent: Check 'service:redisnode1' is passing


[root@erge-app-01 ~]# redis-cli -h redis.service.consul info replication
# Replication
role:master
connected_slaves:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
[root@erge-app-01 ~]# ping -c 2 redis.service.consul
PING redis.service.consul (192.168.3.1) 56(84) bytes of data.
64 bytes from erge-app-01 (192.168.3.1): icmp_seq=1 ttl=64 time=0.018 ms
64 bytes from erge-app-01 (192.168.3.1): icmp_seq=2 ttl=64 time=0.035 ms

--- redis.service.consul ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.018/0.026/0.035/0.009 ms

# 手动恢复故障节点app02
[root@erge-app-02 ~]# ./redisctl start 6379

sentinel日志 耗时10s将其加入主从架构中
10913:X 12 Jul 12:58:22.653 # -sdown slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379
10913:X 12 Jul 12:58:32.604 * +convert-to-slave slave 192.168.3.2:6379 192.168.3.2 6379 @ mymaster 192.168.3.1 6379

[root@erge-app-01 ~]# redis-cli -h redis.service.consul info replication
# Replication
role:master
connected_slaves:1
slave0:ip=192.168.3.2,port=6379,state=online,offset=449,lag=0
master_repl_offset:449
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:448
```



 

## 2.2. 总结

非硬件故障的情况下，高可用情况为：

* Reids master 宕机后，需要30 秒左右的事件进行故障自动转移；
* 恢复宕掉的节点，重新加入主从架构大概在10 秒左右。