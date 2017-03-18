+++
title = "Django, forms, models and DRY"
date = "2014-11-23T09:42:37+02:00"
draft = false

+++

Django provides a `forms` package to make working with forms in web applications easier.

Forms work by subclassing the `Form` class and defining the fields in the class:

    class MyForm(forms.Form):
        field1 = forms.CharField(max_length=10)
        field2 = forms.IntegerField()


But in most cases a form mirrors a model in the database, where you have already
declared the properties for those fields. For this use case, Django provides
`ModelForm` to use as a base class.

As an example, if you had the following model:

    class MyModel(models.Model):
        field1 = models.CharField(max_length=10)
        field2 = models.IntegerField()


you could declare a form for it:

    class MyModelForm(forms.ModelForm):
        class Meta:
            model = MyModel
            fields = ('field1', 'field2', )


There are cases, however, where your form does not correspond to just one model
or the mapping is not very clear. For instance, you provide an API for your web
application, which must be stable no matter how the models change, and have some
complex validation that spans across models. Keep in mind that at the end of the
day [forms validate dictionaries][1] and they are pretty good at it, so why not
use them for validation in general?

In this case, you could create the form by hand, but that is not very DRY; you
would have to edit validation in two places, whenever a change is needed.

A better approach is to do what Django already does in order to construct a
`ModelForm`. Every field in a model has a method called [`formfield`][2], which
constructs a `forms.Field` instance that corresponds to itself: it has the
correct type and correct arguments in place, which you can also override.

The following function allows you to create a `forms.Field` this way.

    def construct_form_field(model, field_name, **kwargs):
        app_name, model_name = model.split('.', 1)
        Model = get_model(app_name, model_name)
        field = Model._meta.get_field_by_name(field_name)[0]
        return field.formfield(**kwargs)


You can use this function then in a form to define the fields you need:

    class MyForm(forms.Form):
        field1 = construct_form_field('app.Model1', 'field1')
        field2 = construct_form_field('app.Model2', 'field2')

[1]: http://www.pydanny.com/core-concepts-django-forms.html#forms-validate-dictionaries
[2]: https://github.com/django/django/blob/bcb693ebd4d3743cb194c6fd05b2d70fb9696a4c/django/db/models/fields/__init__.py#L809
