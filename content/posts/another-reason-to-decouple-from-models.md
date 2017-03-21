+++
date = "2017-03-21T09:36:05+02:00"
title = "Another reason to decouple your code from the models"

+++

As the application grows, the schema in the database will evolve as well, e.g.
you will need new tables or add new columns to an existing table.

One of the changes that may need to take place is editing the column, either the
type or its size or even the type of data it contains.

If you want to do the change without incurring any downtime, the best way to
alter the column is to add a new column, migrate the data and then remove the
old one. (That said, there are cases where a database will allow you to do the
edit in-place without locking the table.)

If you use an ORM though, this means that in general you cannot rely on the
interface of the ORM-based class being stable.

This is another reason to build a different layer for your domain objects, which
can make the promise of a stable API and encapsulate the interfacing with the
database behing a separate layer ([Repository
pattern](https://martinfowler.com/eaaCatalog/repository.html)).


## Sidebar

There are ways around this: adding a property in your ORM-based class with the
old name and use that in the codebase. But this means you cannot still use the
name in any queries - you have to refactor them.
