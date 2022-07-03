
#!/bin/bash

#---------------------Truncating Tables of Sql Database and Hive Database everyday except External Table(partitioned Table)-------------------
mysql -uroot -pWelcome@123 -e "
truncate table project1.project1_sql_tbl;
truncate table project1.project1_tbl;"

hive -e "truncate table project1_db.project1_tbl_mng;"
hive -e "truncate table project1_db.project1_tbl_inter;"

#--------------------Deleting directory from HDFS if exists---------------------
hdfs dfs -rm -r HFS/project1

#---------------------Loading Data into SQl Database Table with currentTime------------
mysql --local-infile=1 -uroot -pWelcome@123 -e "set global local_infile=1;
load data local infile '/home/saif/Desktop/cohort_f11/datasets/Day_$1.csv' into table project1.project1_tbl fields terminated by ',';
update project1.project1_tbl set curr_time = CURRENT_TIMESTAMP() + 1 where curr_time IS NULL;
"

#----------------------Importing Table from RDBMS to HDFS--------------------
sqoop import --connect jdbc:mysql://localhost:3306/project1?useSSL=False --username root --password Welcome@123 --query 'select custid,username,quote_count,ip,entry_time,prp_1,prp_2,prp_3,ms,http_type,purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time from project1_tbl where $CONDITIONS' --split-by custid --target-dir HFS/project1;

#-------------------Loading Data from HDFS to Hive Table-------------------
hive -e "load data inpath 'HFS/project1' into table project1_db.project1_tbl_mng;"

#-------------------Implementing SCD-1 Logic--------------------------
hive -e "set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table project1_db.project1_tbl_par partition (year, month) select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year,
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project1_db.project1_tbl_mng a
join
project1_db.project1_tbl_par b
on a.custid=b.custid
union
select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year,
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project1_db.project1_tbl_mng a
left join
project1_db.project1_tbl_par b
on a.custid=b.custid
where b.custid is null
union
select b.custid,b.username,b.quote_count,b.ip,b.prp_1,b.prp_2,b.prp_3,b.ms,b.http_type,
b.purchase_category,b.total_count,b.purchase_sub_category,b.http_info,b.status_code,b.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year,
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project1_db.project1_tbl_mng a
right join
project1_db.project1_tbl_par b
on a.custid=b.custid
where a.custid is null
;

insert into table project1_db.project1_tbl_inter select * from project1_db.project1_tbl_par t1 join (select max(curr_time) as max_date_time from project1_db.project1_tbl_par) tt1 on tt1.max_date_time = t1.curr_time;"

#-------------------------------Exporting Table to SQL Database-----------------------
sqoop export \
--connect jdbc:mysql://localhost:3306/project1?useSSL=False \
--table project1_sql_tbl \
--username root --password Welcome@123 \
--export-dir "/user/hive/warehouse/project1_db.db/project1_tbl_inter" \
--m 1 \
-- driver com.mysql.jdbc.Driver \
--input-fields-terminated-by ','
