+++
date = "2013-07-11T11:24:31+02:00"
title = "Forward attribute access for wrapper classes"

+++

Let's say you want to create a wrapper class around a Django model. For convenience, you want your wrapper class to forward any direct field access calls to the model it wraps. That is, you want the following code to work:

    class MyModel(models.Model):
        slug = models.SlugField()

    class Wrapper(object):
        model = MyModel

        def __init__(self, w):
            self.w = w

    w = MyModel(slug='slug')
    w = Wrapper(w)
    print w.slug

This boils down to dynamically adding properties to the `Wrapper` class that forward the call to and return the value from the wrapped instance.

Let's also say that you want to create a base `Wrapper` class which can be used for all wrapper classes around your models.

One way to do it would be to use the `__getattr__` function. Keep in mind we are only interested in responding to calls to fields, not every attribute of the model instance.

    class Wrapper(object):

        def __init__(self, queryset):
            self.qs = queryset
            self._qs_field_names = [f.name for f in self.qs._meta.fields]

        def __getattr__(self, name):
            if name in self._qs_field_names:
                return getattr(self.qs, name)
            return super(Wrapper, self).__getattr__(name)

However, this means that all subclasses that want to override `__getattr__` will have to remember to call `super` as well. This approach works well; on the other hand, it puts an extra burden to developers: they have to know the internals of the parent class whenever they need to override an internal function like `__getattr__`.

The other way is to use *metaclasses* and override the `__new__` method:

    def name_getter(obj, name):
        """Closure to creatre a function that operates on the given name."""
        def getter(obj):
            return getattr(obj.qs, name)
        return getter

    class WrapperMeta(type):

        def __new__(meta, name, bases, dct):
            cls = super(ServiceMeta, meta).__new__(meta, name, bases, dct)
            if cls.model is not None:  # Ignore base class case
                for f in cls.model._meta.fields:
                    setattr(cls, f.name, property(name_getter(cls, f.name)))
            return cls

    class Wrapper(object):
        __metaclass__ = WrapperMeta
        model = None

        def __init__(self, queryset):
            self.qs = queryset

First, the `WrapperMeta` metaclass overrides the `__new__` method, so that it will automatically add a `property` to the *derived* classes for each field in the base class.

The `property` function takes as (first) argument a function that takes one argument (the object, i.e., `self`) and returns a value. Since we create those properties dynamically for every attribute, we need to create a function that remembers the name of the attribute any specific property handles. Thus, we use a closure, `name_getter`. The `name_getter` function stores the name `name` of the attribute we want to access and returns a function that, given an object, will return the value of its attribute named `name`.

This allows us to create simple wrapper classes for a django model:

    class MyWrapper(Wrapper):
        model = MyModel

    w = MyWrapper(MyModel(slug='slug'))
    print w.slug
