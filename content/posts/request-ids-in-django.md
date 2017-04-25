+++
date = "2017-04-25T10:55:11+03:00"
title = "Assigning a unique ID to each request in Django"

+++

It is a standard practice to assign a unique ID to every request, so that you
can easily associate the log messages with their request and, thus, make
debugging easier.

You can do that in Django using a middleware. The middleware needs to define the
`process_request` metho and generate the unique ID (e.g. using UUID) to
associate with the request.

One way to use this ID is to pass it as an argument down the call stack and use
it in every log message. That approach, however, creates a dependency from the
upper layer (HTTP layer) to the lower level layers (model or domain layer).
Moreover, this approach requires that every function accepts the ID as an
argument, which complicates the function signatures.

An alternative is to use thread local variables. These variables are similar to
global variables, but their scope is limited within the thread of execution.
This way all logging code has access to the thread local variable (if defined).

It should be noted, however, that these are global variables and so should be
handled with care.

It is useful, however, to use the same ID in celery tasks, so that you can trace
the request in the celery workers log messages, as well. This can be achieved
using celery's `before_task_publish_handler` signal (to add the ID to the task
arguments) and `task_prerun_handler` signal (to read the ID from the task
arguments and set the thread local variable).

The final piece of the puzzle is creating log filters that read the thread local
variables and make them available to the log message formatters automatically,
e.g.

    import logging
    from threading import local

    _locals = local()


    def get_current_identifier():
        """Get the current identifier of the request/task etc."""
        return getattr(_locals, 'identifier', u'')


    class ContextFilter(logging.Filter):
        """Add the request.user to the context of a log record."""

        def filter(self, record):
            record.user_identifier = get_current_identifier()
            return True
