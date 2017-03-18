+++
date = "2011-09-29T11:39:32+02:00"
title = "On database denormalization"

+++

One of the factors of a successful web application is its speed. However, the more successful the application is, the more serious performance issues it will have. As the users and their activity in the application and the data they manage begin to increase, every action becomes even slower, since it competes with more requests for the same resources (CPU, RAM, I/O) and has more data to manage. Usually, the problem lies in the database hits and the queries the app executes. So, if you want to scale, you have at one point or another to look at your database access patterns.

One of the things we can do is start denormalizing things in the database. What is denormalization? Well, first you need to know what [normalization](http://en.wikipedia.org/wiki/Database_normalization) is. Basically, normalizing a database (at least in the 3rd normal form that everybody should strive to design for) means you keep every piece of information in one place. The main advantage of having every piece of information stored in one place is that there is no risk for inconsistencies.

Usually you achieve normalized schemas by creating tables, each one of which is the reference for every type of information stored in the database. Then, in order to get the information you want you join the relevant tables.

For example, say you have the following schema:

    CREATE TABLE resource (
        id INTEGER SERIAL,
        slug VARCHAR(20),
        name VARCHAR(50),
    )

    CREATE TABLE source_entity (
        id INTEGER SERIAL,
        string VARCHAR(50),
        resource_id INTEGER FOREIGN KEY REFERENCES resource(id),
    )

    CREATE TABLE translation (
        id INTEGER SERIAL,
        string VARCHAR(50),
        language_id INTEGER,
        source_entity_id INTEGER FOREIGN KEY REFERENCES source_entity(id),
    )

The above example comes from [Transifex](https://www.transifex.net). A project in Transifex has one or more *resources* that correspond to a translation unit in the project (e.g. a po file). Each resource has one or more *source entities*. A source entity is more or less a key to identify each translatable message in the resource. For each source entity there is one *translation* per language. The relationship between the three entities is:

    resource
