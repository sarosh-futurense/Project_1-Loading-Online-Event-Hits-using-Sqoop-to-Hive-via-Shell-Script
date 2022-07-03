# Project_1-Loading-Online-Event-Hits-using-Sqoop-to-Hive-via-Shell-Script

<img width="593" alt="image" src="https://user-images.githubusercontent.com/108056013/177042983-b9e00403-410e-48b5-bb2c-68842725e72e.png">

A company ABC receives the data about the purchase made on their website by customers on a daily basis. The company wishes to load all the data on a relational database system so that it can be analyzed easily. Also, they need to maintain the data which is up-to–date i.e if there is any change made in the purchase order, it must overwrite the previous data reflect in the database.

Approach:

1. Load the data from client's machine to edgenode using WinSCP.
2. Create a MySQL table (project1_tbl) and addded one column curr_time for comparing updated timestamp.
3. Export Day_1 data to Mysql talbe i.e project1_tbl.
4. From RDBMS, export the data to HDFS using Sqoop.
5. Created a table in Hive and loaded all the data into it from HDFS.
6. Created a external table, and partitioned it based on year and months.
7. Load all the data from manage table to external table.
8. Implement SCD-01 Type Logic.
9. Again created one intermediate table in hive, and inserted all data from external table to this and implemented SQL query for getting updated values only for    successfull implementation of SCD Type-1 for further Data coming next days.
10. Then created a table in SQL and export all records from intermediate to it using sqoop for Data Reconciliation.

