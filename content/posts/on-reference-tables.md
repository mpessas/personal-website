+++
date = "2011-10-04T11:38:38+02:00"
title = "On reference tables"

+++

Working on a constantly evolving web application means that sooner or later you will have to change your database schema. One of the most difficult changes to make is to add a new column to a table.

Let's say you need to add a new column ``ncol`` to an existing table ``t`` in a database. The new column is of type ``INT``, it cannot take the ``NULL`` value and defaults to the value ``0``. The SQL command to use is

    ALTER TABLE t ADD ncol INT DEFAULT 0 NOT NULL

However, the ``ALTER TABLE`` command needs to acquire an [EXCLUSIVE LOCK](http://www.postgresql.org/docs/9.1/static/explicit-locking.html) to the whole table, before it attempts to execute itself. An exclusive lock is the most strict variant of locks in PostgreSQL (and other databases) and it conflicts with every other type of lock defined. So, executing an ``ALTER TABLE`` command on a big table (think millions of rows and more) alongside other statements will block all those statements, even simple ``SELECT``s.

Let's say the ``ALTER TABLE`` statement acquires the ``EXCLUSIVE LOCK`` on the table. Since there is a transaction that has an ``EXCLUSIVE LOCK`` on the table, every other transaction will block and wait for the first transaction to finish. The ``ALTER TABLE`` statement will happily add the column ``ncol`` to the table `t`. That is, it will visit every row, add the new field and set its value to the default one provided.  This action, actually, will result in rewriting the table and its indexes, for it changes the structure of the table. This could take minutes, depending on the size of the table ``t``. Most live applications cannot afford that; if table ``t`` is accessed constantly, clients that use that table would block waiting for the ``ALTER TABLE`` statement to finish - the requests would probably time-out.

A way around the above problems is to break that ``ALTER TABLE`` statement to separate, "lighter" steps. As the [docs](http://www.postgresql.org/docs/9.1/static/sql-altertable.html) say (section *Notes*), setting the columns to ``NULL`` by default will not require the heavy-weight operation of rewriting the whole table and the indexes. So, adding the above column can be done with the following group of statements:

    ALTER TABLE t ADD ncol NULL
    ALTER TABLE t ALTER ncol SET DEFAULT 0
    UPDATE TABLE t SET ncol = 0
    ALTER TABLE t ALTER ncol SET NOT NULL

The above group of statements has the same effect as the original statement. However, only the first one requires an ``EXPLICIT LOCK`` on the table and that statement is executed very fast (think, milliseconds). As a result, any statement that might come and uses the locked table will only block for a tiny amount of time.
