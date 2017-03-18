+++
date = "2011-10-13T11:36:36+02:00"
title = "On database and code changes"

+++

Running a web application means that you always develop new features (and fix bugs) which should be deployed as soon as possible. This is the only way these enhancements reach your users. However, it also means that your application is used by people from all over the world, i.e., there is no point in time, when you can just shutdown the servers and do any necessary maintenance work; downtime should be avoided.

Of particular difficulty are changes in code which require changes in the database schema, too. If you had the luxury of taking the servers down, you would be able to change the database schema, run any data migrations necessary and update the application code. But you do not have that luxury. So, you must make sure you do all those steps, while the servers are running, and at the same time you must ensure that at no point in the update process a request from a user fails.

Updating the application code first is not an option, since it would try to use the new database schema, before it was deployed. The only option is to first update the database schema with the new changes, while making sure that existing code that uses the old schema does not break.

However, that is not straightforward either. Consider the case of adding a new column which does not have a default value to use; any `INSERT` queries in the existing code would fail, since they do not account for the new column.

Additionally, there are issues with [changing the database schema](http://mpessas.tumblr.com/post/11220255249/on-database-schema-changes), too; you must take extra care not to block any concurrent user requests to the database. So, you must plan ahead for the various steps you need to take.

At [Transifex](https://www.transifex.net) we have adopted the following procedure for handling probably the most complex type of change: adding a new column to a table.

- First, the new column is added to the database with no restrictions whatsoever using `NULL` as the default value. That is, in case we wanted to add a column named `col` to a table named `tbl` of type `INT` we would issue the query

        ALTER TABLE tbl ADD col INT NULL

  Allowing null values avoids rewriting the table, i.e., it is the fastest way to add a new column to a table. As a result, the time the table is locked for other requests is minimum. Moreover, any writes to the table will just use the `NULL` value for the specific column.
- Set the default value for the column, if there is one. Assuming the default value for the above column is 0, we would issue the query

        ALTER TABLE tbl ALTER col SET DEFAULT 0

  Setting the default value before updating the code to write to the new column allows any writes issued to take advantage of it.
- Update the code to start writing data to the new column. At this point, the database is not fully consistent yet. By enabling the writes we will eventually reach a consistent state.
- Update existing rows with the data they should have, i.e., migrate the existing data to the new schema. At the end of this step, the table should be in a consistent state. We can also make sure that we have changed all the writes to the database to use the new schema. For example, if the code update was correct, there should be no writes that add a `NULL` value.
- Add the necessary constraints to the column. For example, add the constraint that the column is a foreign key.
- Add the necessary indexes using the new column.
- Update the code to start reading values from the column. The update is now complete.

Other database schema changes can be handled in similar ways.

In summary, we try to make the operation of adding the column as fast as possible, since this locks the table and blocks **all** queries. Then, we enable the writes to the table, so that we can reach a consistent state. Only then do we enforce the constraints and add the necessary indexes. Finally, we start reading and fully utilizing the new column.
