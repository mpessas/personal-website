+++
date = "2013-10-19T11:22:45+02:00"
title = "Running your Django tests in memory with PostgreSQL"

+++


Many people advise to use sqlite for running your tests in django. The reason is
that Django will automatically create the database [in-memory][1], which speeds up
any tests that query the database.

However, this means that your test database is different than your production
one, which might cause issues because of the differences between the databases,
such as how they handle transactions. Besides, you might be using
[features of PostgreSQL][2] that sqlite does not support.

There are ways to make [PostgreSQL much faster for running your tests][3], but
why not run your database in-memory as well and avoid any I/O operations?

This is possible in linux by using a ramdisk for your test database.

First, you need to create the ramdisk:

    sudo mount -t ramfs none /mnt/
    sudo mkdir /mnt/pgdata/
    sudo chown postgres:postgres /mnt/pgdata/

Then, you need to create a [tablespace][4] that uses the ramdisk:

    psql -d postgres -c "CREATE TABLESPACE ramfs LOCATION '/mnt/pgdata'"

The last step is to instruct django to use this tablespace for the test
database. This can be done by adding the following to your settings:

    if 'test' in sys.argv:
        DEFAULT_TABLESPACE = 'ramfs'

This will help reducing the running time of your test suite a bit more.

Keep in mind you might have to drop the tablespace and re-create it after a
reboot.


[1]: http://www.sqlite.org/inmemorydb.html
[2]: https://github.com/mpessas/django-pg-extensions
[3]: http://mpessas.tumblr.com/post/15402128609/testing-with-postgresql
[4]: http://www.postgresql.org/docs/9.2/static/manage-ag-tablespaces.html
