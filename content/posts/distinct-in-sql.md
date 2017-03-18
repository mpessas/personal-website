+++
date = "2011-11-12T11:34:20+02:00"
title = "DISTINCT in SQL"

+++

How does a RDBMS execute a query that has the `DISTINCT` keyword? The most effective  way to ensure the uniqueness of the returned rows of a query is to sort them first; that is, to sort the result based on all fields. Depending on the number of fields `SELECT`ed, this sorting could take a lot of time and need a lot of RAM. If the available RAM is not enough, the RDBMS will resort to using the disk, which is too slow.

So, it is very important to `SELECT` as few fields as possible. This makes the sorting phase much faster and, additionally, requires less RAM. We had such an [issue at Transifex](http://blog.transifex.net/2011/11/a-little-bug-bites-the-dust-the-anatomy-of-fixing-performance-issues/ "DISTINCT issue at Transifex").
