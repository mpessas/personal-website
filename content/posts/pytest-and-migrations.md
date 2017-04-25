+++
date = "2017-04-25T07:48:22+03:00"
title = "Speeding up the Django database creation with pytest"

+++

The standard way to set up the database for running your Django test suite is to
run the the projects migrations from scratch.

This can be quite slow, though, when there are many migrations. For this reason,
`pytest-django` provides an option to keep the database between runs, so as to
avoid this cost every time (`--reuse-db` option).

However, one still has to create the database every now and then from scratch,
e.g. when there are new migrations in the current branch.

One way to always make setting up the database fast is to cache the database
schema itself and use pytest-django's hooks to load it and only then apply any
necessary migrations.

The process is the following:
- Run the test suite with the `--reuse-db` option.
- Use `pg_dump` (or equivalent) to create a backup of your database and commit
  it in your main branch.
- Override `pytest-django`'s fixtures in the top-level `conftest.py` file to
  first load the backup (using `pg_restore` or equivalent) and then run the
  migrations. Every branch should be rebased on top of devel frequently.

Here is an example implementation:

    import subprocess

    import pytest
    from django.conf import settings
    from django.db import connection


    @pytest.fixture(scope='session')
    def _django_db_setup(request, _django_test_environment,
                         _django_cursor_wrapper):
        """Load cached schema from the filesystem before running the migrations."""
        from django.core.management import call_command

        config = request.config
        django_db_keepdb = all([
            config.getvalue('reuse_db'), not config.getvalue('create_db')
        ])

        test_database_name = 'test_db'

        if django_db_keepdb:
            # Update settings and return.
            settings.DATABASES[connection.alias]["NAME"] = test_database_name
            connection.settings_dict["NAME"] = test_database_name
            return

        with _django_cursor_wrapper:
            cursor = connection.cursor()
            cursor.execute("DROP DATABASE IF EXISTS %s" % test_database_name)
            cursor.execute(
                "CREATE DATABASE %s WITH TEMPLATE template1" % test_database_name
            )
            cursor.close()
            connection.close()
        cmd = (
            'pg_restore -n public -U %s -h %s '
            '-d test_db test_db_schema.dump'
        )
        username = settings.DATABASES['default']['USER']
        host = settings.DATABASES['default']['HOST']
        subprocess.call(cmd % (username, host), shell=True)

        with _django_cursor_wrapper:
            settings.DATABASES[connection.alias]["NAME"] = test_database_name
            connection.settings_dict["NAME"] = test_database_name
            call_command('migrate', '--noinput')
