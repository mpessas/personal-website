+++
date = "2013-11-02T11:20:24+02:00"
title = "Using gettext in Django"

+++

Internationalization (i18n) is the process of enabling your software to be
translated to other languages. This is done by making the software able to map
all user-visible strings to their translations in a specific language and use
them, when appropriate.

The i18n toolset django uses is **gettext** and is enabled with the `USE_I18N`
setting. Gettext works as follows: First, the developer marks the **translation
strings** in the source code and then he runs the `xgettext` command to create
the source PO file. The `xgettext` command analyzes the source code to locate
the strings that were marked as translation strings and
extracts them into a PO file, which can be translated to the target languages.
The last step is to *compile* the PO files into binary message files (.mo files) with
the `msgfmt` command.

Django makes sure to ease the process by providing its own management commands:
`makemessages` that extracts the strings from the source code and
`compilemessages` that converts the files into the binary ones. It also expects to find the PO files for a language under the directory
`locale/<locale>/LC_MESSAGES/django.po`, where `<locale>` is the language code.

In the runtime, whenever a gettext function is used, it will use the PO file
that corresponds to the currently active locale and return the correct
translation that corresponds to this string. If no translation is found, the
original string is used instead.

## The gettext functions

The following is a list of the most important gettext functions that django
exposes and can support unicode strings correctly. Keep in mind that they all
mark the containing *literal string* as translatable, that is, you need to pass
the string itself as an argument, not a variable.

- `ugettext`: The function returns the   translation for the currently selected language.
- `ugettext_lazy`: The function marks the string as translation string, but only
  fetches the translated string, when it is used in a string context, such as
  when rendering a template.
- `ugettext_noop`: This function only marks a string as translation string, it
  does not have any other effect; that is, it always returns the string itself.

The `ugettext_lazy` function is useful in cases, where a string needs to be
marked as translation string, but the user's locale is not active yet. For
instance, all strings in a model or in the settings are loaded, when the django
process is started. During startup, there is no user request that sets the
active locale. By using the `ugettext_lazy` function, you ensure that the
translations will be actually fetched only during a user request, when the locale is known.

Given the `ugettext_lazy` function, the `ugettext_noop` function seems to be
redundant. However, it is really useful in cases that you want to mark a string
as translation string, but need to use it in other contexts in its original form
as well, such as an error message that has to be logged, too. For instance, take
the following view that returns an error message to the user (it is a standard practice to import the gettext functions as "`_`"):

    import logging
    from django.http import HttpResponse
    from django.utils.translation import ugettext as _

    def view(request):
        msg = _("An error has occurred")
        logging.error(msg)
        return HttpResponse(msg)

The response will contain the translated error message, but so will the logs. In
order to circumvent this issue, you can use the `ugettext_noop` function
instead:

    import logging
    from django.http import HttpResponse
    from django.utils.translation import ugettext as _, ugettext_noop as _noop

    def view(request):
        msg = _noop("An error has occurred")
        logging.error(msg)
        return HttpResponse(_(msg))

The `ugettext_noop` will force gettext to mark the error message as translation
string, but it will return the original (English) string. As a result, the log
messages will use the English phrase. However, we still want to present the
translated message to the user. We achieve this by using the `ugettext` function
to force evaluating the string and fetching the translated message. This
technique is especially useful for exception messages, that need to be logged in
a higher layer of the codebase but also presented to the user.

## Plural support

Most languages have two **plural forms**: singular and plural. Some languages,
however, have only one, like Japanese. Others can have up to six, like Arabic.

Which plural  form to use  depends on the number of objects the phrase refers to.  For instance, English  uses the
singular  form, when  the phrase  refers  to one  object ("1  language"), and  the
plural, when it refers to none ("no languages") or more than one ("2 languages"). Other languages have different rules.

Django supports plurals with the `n` family of gettext functions: `ungettext`
and `ungettext_lazy`.

## Context support

Gettext allows developers to define the **context** of a string. For instance,
the word "Read" can mean "read an email" or "emails read". The developer can
define and explain the context of a string to differentiate between the two uses. This way, gettext will create
separate entries for the word "read", one for each context.

This is supported in django with the `p` family of gettext functions:
`pgettext`, `pgettext_lazy`, `npgettext` and `npgettext_lazy`.

## Support in templates

Django provides two *templatetags* for marking translation strings in templates:
`trans` and `blocktrans`. The main difference is that the `trans` templatetag
only supports simple strings, while the `blocktrans` templatetag supports
variable substitution (placeholders) as well.

Both templatetags support most of the gettext features. One thing to keep in
mind for the `blocktrans` templatetag, though, is that the containing string is
extracted as is. This means that the string will be extracted by gettext with
any newline and space characters or indentation it might have. For this reason,
all indentation should be avoided.

More details for how to internationalize your web application can be found at
[django's documentation][1].

[1]: https://docs.djangoproject.com/en/dev/topics/i18n/translation/
