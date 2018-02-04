# 脚本使用说明

```shell

#卸载
for i in `ps -ef|grep redi[s]|awk '{print $2}'`;do kill -9 $i;done
cp /etc/resolv.conf.bac /etc/resolv.conf 
rpm -e --nodeps bind
rpm -e --nodeps bind-chroot
rm -rf /etc/sysconfig/named.rpmsave
rm -rf /etc/named.conf.rpmsave
rm -rf /alidata/


#安装
将脚本传到 /root/家目录下
bash RedisInstall.sh 
#启动redis服务
./redisctl start 6379
./redisctl start 6380
#启动sentinel服务
./redisctl sentinel 26379
./redisctl sentinel 26380
#查看进程
ps -ef|grep redi[s]
#启动consul服务
nohup /bin/consul agent -dev  -config-dir=/alidata/consul/conf &> /alidata/consul/consul.log &
#查看consul进程
ps -ef|grep consul
# 测试
dig redis.service.consul

# 测试整体架构
redis-cli -h redis.service.consul -p 6379 -a zyadmin info replication
```