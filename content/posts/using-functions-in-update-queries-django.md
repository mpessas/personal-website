+++
date = "2013-04-06T11:26:49+02:00"
title = "Using functions in UPDATE queries from the Django ORM"

+++

PostgreSQL is a great database and comes with many great and really useful features, one of which is arrays. There are various apps that add support for arrays in the Django ORM, like [django-dbarray][1], [djorm-ext-pgarray][2] and [django-pg-extensions][3].

However, those packages provide only fields that represent a PostgreSQL array (and maybe support for some of the operators), but not for the [functions][4] that PostgreSQL provides to manipulate arrays. Some of those functions are really useful, like adding elements to an array.

For instance, if you choose to use arrays to represent tags for an entity, how do you add new tags to a set of entities? In other words, how do you use the PosetgreSQL functions with the `.update()` QuerySet API?

Django ORM provides a feature to allow developers control the SQL generated in some of the queries; if the argument is an object with a `.as_sql()` method, django will [use that][5] to construct the SQL for the query. The `as_sql` method needs to return the SQL string and a list of the parameters used in the SQL — it is important to avoid embedding the parameters in the SQL query, so that they can be correctly escaped, before being executed.

As an example, the following class generates the SQL to append a value to an array.

    class AppendToArray(object):

         def __init__(self, column, value):
             self.column = column
             self.value = value

         def as_sql(self):
              return "array_append(%s, %%s)" % self.column, [self.value]

If you wanted to use it in a `QuerySet` method, you could have something like

    class MyQuerySet(models.QuerySet):

         def add_element(self, element):
             value = AppendToArray("column_name", element)
             return self.update(column=value)

[1]: https://github.com/ecometrica/django-dbarray
[2]: https://github.com/niwibe/djorm-ext-pgarray
[3]: https://github.com/mpessas/django-pg-extensions
[4]: http://www.postgresql.org/docs/9.2/static/functions-array.html
[5]: https://github.com/django/django/blob/master/django/db/models/sql/compiler.py#L932
