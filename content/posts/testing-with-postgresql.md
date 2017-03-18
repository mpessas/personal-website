+++
date = "2012-01-06T11:30:08+02:00"
title = "Testing with PostgreSQL"

+++

Transifex is a quite big application, counting tens of thousands of lines of Python, javascript and HTML code. In order to make sure the code works, it has an extensive test suite, which, obviously, takes quite some time to run.

There are various things that can be done to make tests run faster. But let's talk about databases.

Transifex is built on top of [Django](https://www.djangoproject.com) and uses its ORM. As a result, it can use various database backends, like [SQLite](http://www.sqlite.org/) and [PostgreSQL](http://www.postgresql.org/).

When Django is configured to use SQLite, it does a nice little trick when running the test suite; it creates the database in memory. As a result, database access is very fast, since there is no I/O, which results in reduced execution time for the tests.

For example, we run the test suite for the *projects* app of Transifex:

    time ./manage.py test projects

and the results are:

    real    2m52.429s
    user    2m5.132s
    sys     0m2.953s

For the *resources* app (the test suite of which is much bigger) the results are:

    real    6m29.072s
    user    4m35.209s
    sys     0m8.956s

Of course, the above numbers are not a benchmark, but just an indication of how long it takes to run those tests on a machine with 8GB of RAM.

However, [Transifex.net](https://www.transifex.net) runs on PostgreSQL and all testing should be done with the setup that is used in production. For instance, PostgreSQL is much more strict about transaction semantics than SQLite and that affects many tests. That means, tests should be run against PostgreSQL.

But, the default setup of PostgreSQL is not optimized at all. In fact, the default settings are chosen, so that PostgreSQL can run on servers with as little as 64MB of RAM (or something like that).

With the default setup of PostgreSQL, the *projects* test suite runs in:

    real    4m40.891s
    user    2m16.898s
    sys     0m3.816s

and the *resources* app in

    real    10m7.483s
    user    4m58.841s
    sys     0m9.566s

Both running times are mush worse than those achieved, when using SQLite as database backend.

There are a few settings, however, which could be optimized to make PostgreSQL faster for testing. In my machine, I have

    shared_buffers = 512MB
    work_mem = 16MB
    fsync = off
    synchronous_commit = off
    wal_buffers = 64MB
    checkpoint_segments = 36
    checkpoint_timeout = 10min
    random_page_cost = 2.0
    effective_cache_size = 1024MB

The goal is to allow PostgreSQL to use much more memory and, as a result, to choose more efficient execution plans for the queries. For instance, we set the `work_mem` to 16MB, a value large enough (for the tests of Transifex), so that all `SORT` operations are executed in RAM.

At the same time, we try to reduce the I/O that PostgreSQL will perform. For example, we deactivate the `fsync` option, which instructs PostgreSQL to do a `fsync()` call, whenever it writes something to disk, and increase the `checkpoint_segments` option, which instructs PostgreSQL to flush data in larger intervals.

You can see what each option is for in the [manual of PostgreSQL](http://www.postgresql.org/docs/current/static/).

With the above settings, the execution times are:

    real    3m4.360s
    user    2m14.458s
    sys     0m3.360s

for the *projects* app and

    real    6m49.579s
    user    4m49.101s
    sys     0m9.256s

for the *resources* app, which are comparable to the ones obtained, when using SQLite.

The values chosen depend, of course, on the CPU and available memory you have. Additionally, some of the options (like `fsync`) should not be used in production.
Keep also in mind that you will probably need to increase the maximum size of a shared memory segment with the command

    sysctl -w kernel.shmmax=8589934592

in order to use the above settings (or add the new value in `/etc/sysctl.conf`).
