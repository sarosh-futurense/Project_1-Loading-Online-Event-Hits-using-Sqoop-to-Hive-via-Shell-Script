#-------------Shebang Statement--------------
#!/bin/bash

#--------------Loging into MysQl and creating table------------------

mysql -uroot -pWelcome@123 -e "create table project1.project1_tbl(custid integer(10) primary key not null,username varchar(30),quote_count varchar(30),ip varchar(30),entry_time varchar(30),prp_1 varchar(30),prp_2 varchar(30),prp_3 varchar(30),ms varchar(30),http_type varchar(30),purchase_category varchar(30),total_count varchar(30),purchase_sub_category varchar(30),http_info varchar(30),status_code integer(10),curr_time bigint);"

#------------------Loading Data from Edgenode to Sql Database and Update current time column----------------------

mysql --local-infile=1 -uroot -pWelcome@123 -e "set global local_infile=1;
load data local infile '/home/saif/Desktop/cohort_f11/datasets/Day_1.csv' into table project1.project1_tbl fields terminated by ',';
update project1.project1_tbl set curr_time = CURRENT_TIMESTAMP() + 1 where curr_time IS NULL;
"

#---------------------------Loading Data To HDFS from SQL using Sqoop--------------------------------------

sqoop import --connect jdbc:mysql://localhost:3306/project1?useSSL=False --username root --password Welcome@123 --query 'select custid,username,quote_count,ip,entry_time,prp_1,prp_2,prp_3,ms,http_type,purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time from project1_tbl where $CONDITIONS' --split-by custid --target-dir HFS/project1;

#------------------Creating Managed table in Hive---------------------------

hive -e "
create table project1_db.project1_tbl_mng (
custid int,
username string,
quote_count string,
ip string,
entry_time string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
curr_time BIGINT
)
row format delimited fields terminated by ',';"

#-------------------Loading Data from HDFS to Hive Managed Table-------------------------
hive -e "load data inpath 'HFS/project1' into table project1_db.project1_tbl_mng;"

#-----------------Creating Partition Table----------------------
hive -e "create external table project1_db.project1_tbl_par(
custid int,
username string,
quote_count string,
ip string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
curr_time BIGINT
)
partitioned by(year string,month string)
row format delimited fields terminated by ',';"

#-----------------Loading Data from Managed to Partition Table ----------------------

hive -e "set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table project1_db.project1_tbl_par partition (year, month) select custid,username,quote_count,ip,prp_1,prp_2,prp_3,ms,http_type,
purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year,
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project1_db.project1_tbl_mng;

create table project1_db.project1_tbl_inter (
custid int,
username string,
quote_count string,
ip string,
entry_time string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
year string,
month string,
curr_time BIGINT
)
row format delimited fields terminated by ',';
insert into table project1_db.project1_tbl_inter select * from project1_db.project1_tbl_par t1 join (select max(curr_time) as max_date_time from project1_db.project1_tbl_par) tt1 on tt1.max_date_time = t1.curr_time;"

#-----------------------------------Creating Table for Data Reconcilation in Sql DB--------------------------

mysql -uroot -pWelcome@123 -e "create table project1.project1_sql_tbl (custid integer(10),username varchar(30),quote_count varchar(30),ip varchar(30),entry_time varchar(30),prp_1 varchar(30),prp_2 varchar(30),prp_3 varchar(30),ms varchar(30),http_type varchar(30),purchase_category varchar(30),total_count varchar(30),purchase_sub_category varchar(30),http_info varchar(30),status_code integer(10),year varchar(100),month varchar(100),curr_time bigint);"

#-------------------------------------Exporting Table from hive to Sql Database---------------------------

sqoop export --connect jdbc:mysql://localhost:3306/project1?useSSL=False --table project1_sql_tbl --username root --password Welcome@123 --export-dir "/user/hive/warehouse/project1_db.db/project1_tbl_inter" --m 1 -- driver com.mysql.jdbc.Driver --input-fields-terminated-by ',';
