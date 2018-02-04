# MySQL和Redis高可用架构搭建

[TOC]

## 项目实施进度

| 日期         | 实施进度 | 备注                                       |
| ---------- | ---- | ---------------------------------------- |
| 2017-07-06 | 进行中  | redis高可用测试                               |
| 2017-07-07 | 进行中  | redis自动配置脚本                              |
| 2017-07-11 | 进行中  | 线上测试[redis自动部署脚本](case/01-redis-consul/redisScripts/) |
| 2017-07-12 | 进行中  | 完成[安装](01-redis-consul/01redis实施过程记录.md)并提交文档[Redis主从高可用实施文档](case/01-redis-consul/02Redis主从高可用实施文档.md) |



## 项目总结

1.  内部总结文档[Redis-sentinel-consul高可用](01-redis-consul/case/Redis-sentinel-consul高可用.md)
2.  [redis高可用自动化脚本](case/01-redis-consul/redisScripts/)的实现
3.  设置计划任务实现consul日志轮询和自动清理


```shell
cat > consullogrotate.sh << ENDF
find /dir -type f -mtime 7 -exec rm -rf {} \;
ENDF

crontab -e 
0 0  * * * /bin/bash consullogrotate.sh
```

