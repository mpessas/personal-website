+++
date = "2017-04-25T11:25:55+03:00"
title = "When to use signals"
draft = true

+++

One of the features that Django (and other web frameworks) provide is support
for signals. The goal is for an application A to be able to hook into certain
operations that an application B does and execute extra functionality, without
coupling the two applications together.

Signals, though, come with their own set of problems:

- Tests need to take into account the signal listeners.
- Synchronous execution
