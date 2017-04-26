+++
date = "2017-04-26T07:55:22+01:00"
title = "Tips for writing tests"
draft = true

+++

## Goals of testing

We write automated tests, so that we have:

- confidence when **refactoring**
- confidence when **deploying**.


## Tells of a possibly good test suite

The test suite

- is fast,
- has good coverage,
- gives confidence to the team.


## Tips for good testing

### Law of Demeter

The Law of Demeter for functions requires that a method m of an object O may only invoke the methods of the following kinds of objects:[2]
1.	O itself
2.	m's parameters
3.	Any objects created/instantiated within m
4.	O's direct component objects
5.	A global variable, accessible by O, in the scope of m

In particular, an object should avoid invoking methods of a member object
returned by another method. For many modern object oriented languages that use a
dot as field identifier, the law can be stated simply as "use only one dot".
That is, the code a.b.Method() breaks the law where a.Method() does not. As an
analogy, when one wants a dog to walk, one does not command the dog's legs to
walk directly; instead one commands the dog which then commands its own legs.

The goal is to minimize dependencies.


### Prefer to hit database than mocking

Mocking gives a false sense of coverage. Things can easily break, but because
they are mocked out, the test suite will not let you know.

That said, mocking is useful:

- to test external services
- to mock out lower level functionality *that has aleady been tested*.

### Dependency injection

It make it much easier to swap out implementations for testing. Best example
here is date and time objects: you cannot have tests that depend on time values,
which you do not control.

However, dependency injection just for testing could be bad.


### Small functions

Whenever you feel like writing a comment, check if

- a better name can explain things
- you can extract the method with the name being the comment you were about to write.


### FactoryBoy

Use factoryboy instead of fixtures. This way, you only load the things you
actually need, reducing the time necessary to initialize your tests.


### Use a `TestCase` per class or even method

Each `TestCase` tests a certain behavior or functionality, which is not
necessarily a function, class or module.


### Single Responsibility

Each function and class should have one responsibility. We write tests that test
only that responsibility.


### Testing external APIs

Create a thin layer that interacts with any external APIs. Use well-defined data
structures and functions to talk back and forth with the thin wrapper and assign
to a single entity to run the interaction and do the translation.

This way, you can test only your system, since the translation between the two
should be trivial.

It is, however, a good idea to keep scripts handy that can test the remote API
actually works, so that you can easily verify in case of issues whether the
remote service is at fault (e.g. changing their API or intermittent issue with
their service) or the local system.


### Prefer declarative style for the higher level services

Using a declarative style with no business logic for your "controllers" means
that you do not need to test it; you would only test that the programmer did not
do any errors.


### Orthogonal responsibilities

Permission checking, logging, notifications etc are not part of the core system.
As a result, they should be tested separately and not in combination with the
core software.
tpaint
If the collaboration of different components is just a matter of declaring some
things (such as, using a `permission_check` decorator), then no teting is
necessary.

This is true for any independent components.


## Remember

Tests are not the goal, just a means to the real goals.
