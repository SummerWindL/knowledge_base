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

|  基础   | 信息  |
|  :----  | :----  |
| 操作系统  |Ubuntu 16.04.2 |
| 系统位数  ||
|CPU|Intel(R) Xeon(R) CPU E5506  @ 2.13GHz|
|内存|8G|
|硬盘||
|PostgreSQL版本|10.11|


|  基础   | 信息  |
|:----:|:----|
|测试工具 ||
|工具名称|pgbench|
|数据量|200w|
|模拟客户端数|	4|
|线程数|4|
|测试时间|60s|

<a style="color: red"><b>
准备命令：pgbench -i -s 20 mb_dev_v3.5--初始化选项 （使用pgbench需要先初始化选项 建表过程）</br>
测试命令：pgbench -r -j4 -c4 -T60 mb_dev_v3.5  --基准选项

查询pgbench执行情况：</br>
SELECT sa.* FROM pg_catalog.pg_stat_activity sa  where application_name = 'pgbench'；
查询数据库容量前十的表：</br>
SELECT relname, relpages FROM pg_class WHERE relkind IN ('r', 't', 'f') ORDER BY relpages DESC LIMIT 10;
查询当前数据库配置信息：</br>
show all ;</a>


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
|  选项   | 默认值  | 说明| 是否优化|原因|
|:----:|:----|:----|:----|:----|
|max_connections|	100|	允许客户端连接的最大数目|	否|	因为在测试的过程中，100个连接已经足够|
|fsync|	on|	强制把数据同步更新到磁盘|	是|	因为系统的IO压力很大，为了更好的测试其他配置的影响，把改参数改为off|
|shared_buffers|	24MB|	决定有多少内存可以被PostgreSQL用于缓存数据（推荐内存的1/4)|	是	|在IO压力很大的情况下，提高该值可以减少IO|
|work_mem|	1MB|	使内部排序和一些复杂的查询都在这个buffer中完成|	是|	有助提高排序等操作的速度，并且减低IO|
|effective_cache_size|	128MB|	优化器假设一个查询可以用的最大内存，和shared_buffers无关（推荐内存的1/2)|	是|	设置稍大，优化器更倾向使用索引扫描而不是顺序扫描|
|maintenance_work_mem|	16MB|	这里定义的内存只是被VACUUM等耗费资源较多的命令调用时使用|	是|	把该值调大，能加快命令的执行|
|wal_buffer|	768kB|	日志缓存区的大小|	是|	可以降低IO，如果遇上比较多的并发短事务，应该和commit_delay一起用|
|checkpoint_segments|	3	|设置wal log的最大数量数（一个log的大小为16M）|	是|	默认的48M的缓存是一个严重的瓶颈，基本上都要设置为10以上|
|checkpoint_completion_target|	0.5|	表示checkpoint的完成时间要在两个checkpoint间隔时间的N%内完成|	是|	能降低平均写入的开销|
|commit_delay|	0|	事务提交后，日志写到wal log上到wal_buffer写入到磁盘的时间间隔。需要配合commit_sibling|	是|	能够一次写入多个事务，减少IO，提高性能|
|commit_siblings|	5	|设置触发commit_delay的并发事务数，根据并发事务多少来配置	是	减少IO，提高性能|
|autovacuum_analyze_threshold|	50|	与autovacuum_analyze_scale_factor配合使用，来决定是否analyze|	是|	使analyze的频率符合实际|
|autovacuum_analyze_scale_factor|	0.1|	当update，insert，delete的tuples数量超过autovacuum_analyze_scale_factor*table_size+autovacuum_analyze_threshold时，进行analyze。	|是	|使analyze的频率符合实际|


1.WITH AN SQL COMMAND
If you have a superuser credentials you can just execute the pg_reload_conf() function. This will apply any changes that have been made to the postgresql.conf.
> postgres=# SELECT pg_reload_conf();
> pg_reload_conf
> ----------------
> t
> (1 row)


2.WITH THE TERMINAL
It is possible to load changes done to the postgresql.conf file via the terminal. You will need to login as the postgres user or su into it if you have root access. Then execute the pg_ctl command with the reload parameter.

> [root@home ~]# su - postgres
> [postgres@home ~]# /usr/bin/pg_ctl reload
> server signaled



If your data folder is not in the default location, pg_ctl will complain

>	[root@home ~]# su - postgres
> [postgres@home ~]# /usr/bin/pg_ctl reload

pg_ctl: no database directory specified and environment variable PGDATA unset
Try "pg_ctl --help" for more information.

In that case you will need to give it the location. That is done by passing the -D flag followed b the location of the data folder

>	[root@home ~]# su - postgres
> [postgres@home ~]# /usr/bin/pg_ctl -D /var/lib/pgsql/9.3/data/
> server signaled

The current version of PostgreSQL I am using is 9.3.5. Not all versions of PostgreSQL offer the same settings, they may change over version numbers. Also not all settings are available to be changed on the fly. Some require that PostgreSQL be restarted to take effect. There are not many of these settings, but they are settings that you usually only set once. For example the ip and port number.
Below are all the settings available for PostgreSQL v9.3.5 on Centos 6.5 as returned by the SHOW ALL command. I have marked the ones that require a restart to take effect. All other can modified and applied either via the pg_reload_conf() function or the pg_ctlcommand.


下面介绍几个我认为重要的：
1、增加maintenance_work_mem参数大小
增加这个参数可以提升CREATE INDEX和ALTER TABLE ADD FOREIGN KEY的执行效率。
2、增加checkpoint_segments参数的大小
增加这个参数可以提升大量数据导入时候的速度。
3、设置archive_mode无效
这个参数设置为无效的时候，能够提升以下的操作的速度
?CREATE TABLE AS SELECT
?CREATE INDEX
?ALTER TABLE SET TABLESPACE
?CLUSTER等。
4、autovacuum相关参数
autovacuum：默认为on，表示是否开起autovacuum。默认开起。特别的，当需要冻结xid时，尽管此值为off，PG也会进行vacuum。
autovacuum_naptime：下一次vacuum的时间，默认1min。 这个naptime会被vacuum launcher分配到每个DB上。autovacuum_naptime/num of db。
log_autovacuum_min_duration：记录autovacuum动作到日志文件，当vacuum动作超过此值时。 “-1”表示不记录。“0”表示每次都记录。
autovacuum_max_workers：最大同时运行的worker数量，不包含launcher本身。
autovacuum_work_mem ：每个worker可使用的最大内存数。
autovacuum_vacuum_threshold ：默认50。与autovacuum_vacuum_scale_factor配合使用， autovacuum_vacuum_scale_factor默认值为20%。当update,delete的tuples数量超过autovacuum_vacuum_scale_factor
*table_size+autovacuum_vacuum_threshold时，进行vacuum。如果要使vacuum工作勤奋点，则将此值改小。
autovacuum_analyze_threshold ：默认50。与autovacuum_analyze_scale_factor配合使用。
autovacuum_analyze_scale_factor ：默认10%。当update,insert,delete的tuples数量超过autovacuum_analyze_scale_factor
*table_size+autovacuum_analyze_threshold时，进行analyze。
autovacuum_freeze_max_age：200 million。离下一次进行xid冻结的最大事务数。
autovacuum_multixact_freeze_max_age：400 million。离下一次进行xid冻结的最大事务数。
autovacuum_vacuum_cost_delay ：如果为-1，取vacuum_cost_delay值。
autovacuum_vacuum_cost_limit ：如果为-1，到vacuum_cost_limit的值，这个值是所有worker的累加值。





以下是测试结果：</br>
采用优化配置前，输出结果如下，</br>
transaction type: <builtin: TPC-B (sort of)></br>
scaling factor: 20</br>
query mode: simple</br>
number of clients: 4</br>
number of threads: 4</br>
duration: 60 s</br>
number of transactions actually processed: 12567</br>
latency average = 19.102 ms</br>
tps = 209.405592 (including connections establishing)</br>
tps = 209.416835 (excluding connections establishing)</br>
script statistics:</br>
 - statement latencies in milliseconds:</br>
         0.003  \set aid random(1, 100000 * :scale)</br>
         0.001  \set bid random(1, 1 * :scale)</br>
         0.001  \set tid random(1, 10 * :scale)</br>
         0.001  \set delta random(-5000, 5000)</br>
         0.106  BEGIN;</br>
         0.336  UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;</br>
         0.277  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;</br>
         0.445  UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;</br>
         1.608  UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;</br>
         0.241  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);</br>
        16.088  END;</br>

使用优化配置后，输出结果如下：</br>
transaction type: <builtin: TPC-B (sort of)></br>
scaling factor: 20</br>
query mode: simple</br>
number of clients: 4</br>
number of threads: 4</br>
duration: 60 s</br>
number of transactions actually processed: 199648</br>
latency average = 1.202 ms</br>
tps = 3327.414585 (including connections establishing)</br>
tps = 3327.633275 (excluding connections establishing)</br>
script statistics:</br>
 - statement latencies in milliseconds:</br>
         0.002  \set aid random(1, 100000 * :scale)</br>
         0.000  \set bid random(1, 1 * :scale)</br>
         0.000  \set tid random(1, 10 * :scale)</br>
         0.000  \set delta random(-5000, 5000)</br>
         0.059  BEGIN;</br>
         0.245  UPDATE pgbench_accounts SET abalance = abalance + :delta WHERE aid = :aid;</br>
         0.166  SELECT abalance FROM pgbench_accounts WHERE aid = :aid;</br>
         0.207  UPDATE pgbench_tellers SET tbalance = tbalance + :delta WHERE tid = :tid;</br>
         0.187  UPDATE pgbench_branches SET bbalance = bbalance + :delta WHERE bid = :bid;</br>
         0.140  INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (:tid, :bid, :aid, :delta, CURRENT_TIMESTAMP);</br>
         0.195  END;</br>


