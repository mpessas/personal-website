+++
date = "2014-02-11T11:11:02+02:00"
title = "Exposing objects in multiple represenations"

+++

## The need for multiple representations

Many applications have multiple interfaces: an API that others use to access the
application programmatically or a rich web client built with JavaScript for the
end-users and so on.

The needs of each interface may be different, though. The API, for
instance, may need to expose all details of a specific object, but the web
interface only needs certain details and maybe some extra attributes.

This means that the objects living in the business core need to be exposed to
multiple clients in different ways. How can you achieve this efficiently?

The following examples will use Django, but the same principles apply in
general.

We will also use a `User` object as an example:

    class User(object):

        def __init__(self, username, password, email, firstname, lastname):
            self.username = username
            self.password = password
            self.email = email
            self.firstname = firstname
            self.lastname = lastname


This is not a Django model, since you can also have plain python classes for
your business logic.


## Solutions that don't scale: Putting the code in the view

The first thing that usually comes to mind is to do the necessary transformation
in the view that exposes the object.


    import json
    from django.http import HttpResponse

    def user_details(request, username):
        # Fetch the user from the database.
        user = fetch_user(username=username)
        user_dict = {}
        for attr in [username, email, firstname, lastname]:
            user_dict[attr] = getattr(user, attr)
        return HttpResponse(
            json.dumps(user_dict), content_type="application/json"
        )

A similar approach would be followed in the API views as well.

This approach leads, however, to **duplicated code**: every time you need to
serialize a `User` object you need to follow the exactly same process and have
the exactly same code.

Until you don't; a use-case will come up where you need a different
representation. As an example, you might need in a view to expose the number of
photos a `User` might have as well:

    def user_details_with_photos(request, username):
        # Fetch the user from the database.
        user = fetch_user(username=username)
        user_dict = {}
        for attr in [username, email, firstname, lastname]:
            user_dict[attr] = getattr(user, attr)
        user_dict["nphotos"] = user.nphotos()
        return HttpResponse(
            json.dumps(user_dict), content_type="application/json"
        )

which is the same code as before with just one extra line.

As a result, the next time you have to change something, you have to make the
change in many places, hoping you do not forget one, making this approach
**error-prone**.

These are all well-known drawbacks of putting logic in the views.


## Solutions that don't scale: Putting the code in the object

The next approach is to create a **fat model** and keep the view **skinny**.
That is, we move the code that generates the representation of the `User` object
in the `User` class itself:


    class User(object):
        ...

        def to_dict(self):
            result = {}
            for attr in [username, email, firstname, lastname]:
                result[attr] = getattr(self, attr)
            return result

        def to_dict_with_photos(self):
            result = self.to_dict()
            result["nphotos"] = user.nphotos()
            return result


The corresponding views become:

    def user_details(request, username):
        user = fetch_user(username=username)
        return HttpResponse(
            json.dumps(user.to_dict()),
            content_type="application/json"
        )


    def user_details_with_photos(request, username):
        user = fetch_user(username=username)
        return HttpResponse(
            json.dumps(user.to_dict_with_photos()),
            content_type="application/json"
        )


This solves the problem of **code reuse** nicely. Every way to represent the
`User` object is in one place, in the `User` class, and the code in the views
becomes simpler. Furthermore, tests become much simpler to write: you need to
test the two methods that convert a `User` object to a dictionary, instead of
testing the views directly. Thus, the tests become faster as well,since they do
not have to go through the HTTP stack.

However, the `User` class has become quite large this way. In addition to the
functionality it must support for a user instance, the class also has many
methods to generate all necessary transformations.

In other words, this approach violates the
[**Single Responsibility Principle**][1]. The `User` class has two
responsibilities, one to support the necessary functionality of a `User` object
and one to represent the object in multiple ways. The `User` class becomes this
way harder to understand and more fragile.


## Moving the logic for the representations to separate processes

The solution to this problem is to extract the responsibility of generating a
representation of a `User` instance to a separate function or class.


    class UserRepresentations(object):

        @classmethod
        def to_dict(cls, user):
            result = {}
            for attr in [username, email, firstname, lastname]:
                result[attr] = getattr(user, attr)
            return result

        @classmethod
        def to_dict_with_photos(cls, user):
            result = cls.to_dict(user)
            result["nphotos"] = user.nphotos()
            return result


As an added benefit, these representations can be unit-tested in isolation,
without any dependency on the business objects (and perhaps the database).

The views now become:


    def user_details(request, username):
        user = fetch_user(username=username)
        user_dict = UserRepresentations.to_dict(user)
        return HttpResponse(
            json.dumps(user_dict), content_type="application/json"
        )


    def user_details_with_photos(request, username):
        user = fetch_user(username=username)
        user_dict = UserRepresentations.to_dict_with_photos(user)
        return HttpResponse(
            json.dumps(user_dict), content_type="application/json"
        )


The result is a clear separation of concerns; that is, a cleaner codebase and of
higher quality.


[1]: http://en.wikipedia.org/wiki/Single_responsibility_principle
