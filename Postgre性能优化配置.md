# Postgre 性能优化配置

### 硬件和系统环境：
以201为例：
>1. 查看CPU个数：cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l
>2. 查看CPU核数：cat /proc/cpuinfo| grep "cpu cores"| uniq
>3. 逻辑CPU个数：cat /proc/cpuinfo| grep "processor"| wc -l
>4. 查看CPU信息：cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
>5. 查看内存信息：cat /proc/meminfo
>6. 查看系统信息：uname -a
>7. 查看版本信息：cat /etc/issue


|:----:|:----|----:|
|操作系统|Ubuntu 16.04.2|
|系统位数||
|CPU|Intel(R) Xeon(R) CPU E5506  @ 2.13GHz|
|内存|8G|
|硬盘||
|PostgreSQL版本|10.11|

|:----:|:----|----:|
|测试工具|
|工具名称	|pgbench
|数据量	|200w
|模拟客户端数|	4
|线程数	|4
|测试时间|	60s

<a style="color: red"><b>
准备命令：pgbench -i -s 20 mb_dev_v3.5--初始化选项 （使用pgbench需要先初始化选项 建表过程）</br>
测试命令：pgbench -r -j4 -c4 -T60 mb_dev_v3.5  --基准选项

查询pgbench执行情况：</br>
SELECT sa.* FROM pg_catalog.pg_stat_activity sa  where application_name = 'pgbench'；
查询数据库容量前十的表：</br>
SELECT relname, relpages FROM pg_class WHERE relkind IN ('r', 't', 'f') ORDER BY relpages DESC LIMIT 10;
查询当前数据库配置信息：</br>
show all ;


说明：
初始化选项参数：</br>
-s scale_factor </br>
--scale=scale_factor </br>
将生成的行数乘以比例因子。例如，-s 100将在pgbench_accounts表中创建 10,000,000 行。默认为 1。当比例为 20,000 或更高时，用来保存账号标识符的列（aid列）将切换到使用更大的整数（bigint），这样才能足以保存账号标识符。</br>
基准选项参数：</br>
-r </br>
--report-latencies </br>
在基准结束后，报告平均的每个命令的每语句等待时间（从客户端的角度来说是执行时间）。</br>详见下文。</br>
-j threads </br>
--jobs=threads </br>
pgbench中的工作者线程数量。在多 CPU 机器上使用多于一个线程会有用。客户端会尽可能均匀地分布到可用的线程上。默认为 1。</br>
-c clients </br> 
--client=clients </br>
模拟的客户端数量，也就是并发数据库会话数量。默认为 1。</br>

详见：http://www.postgres.cn/docs/10/pgbench.html</br>
主要选项</br>


