+++
date = "2011-12-27T11:31:39+02:00"
title = "TimedRotatingFileHandler"

+++

<span class="comment">(For future reference.)</span>

[`TimedRotatingFileHandler`](http://docs.python.org/library/logging.handlers.html#timedrotatingfilehandler) logs messages to a file and rotates it based on time values.

Among the arguments it accepts is the `when` argument, which specifies the type of interval. One of the possible values is `'W'`, which specifies that the rollover should be done on a specific day of the week (with `0` being Monday). The day is specified by appending the necessary number (`[0-6]`) to `when`, like `W0` for rotating the logs on Mondays.

The relevant code from logging.handler:

    elif self.when.startswith('W'):
        self.interval = 60 * 60 * 24 * 7 # one week
        if len(self.when) != 2:
            raise ValueError(...)
        if self.when[1]  '6':
            raise ValueError(...)
        self.dayOfWeek = int(self.when[1])
