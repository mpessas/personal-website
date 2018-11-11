---
title: "Rules for writing tests"
date: 2018-11-11T12:07:57+02:00
draft: true
---

When writing tests for a (Python) codebase:

- We use pytest fixtures. They are way more flexible than an inheritance-based
  system and allow for fine-grained dependencies.
- Every test case should test for a single behavior. This usually means having a
  single `assert` statement in a test case. This makes it easier to know why a
  test failed and what behavior is tested.
- The structure of the test suite on the filesystem should mirror that of the
  codebase, so as to be quick to find the tests for a piece of code.
- Any package should be free to define its own fixtures in a local
  `conftest.py`. Not all fixtures make sense to go to the top-level
  `conftest.py` file.
- A test can override fixtures defined up in the hierarchy, but it should prefer
  to use a new name that makes sense locally. Otherwise, there could be
  confusion about which fixture is used.
- A test case should test one specific thing and test it right at the edge of
  where it is defined and not at higher levels. For instance, if you want to
  test the behavior of a function, do not do it via the API that happens to use
  that function deep in the call hierarchy. This way you are guaranteed that the
  test does not fail for any other reason than what you are testing for.
- A test case must avoid any network calls. Otherwise, tests are slow and
  non-deterministic (e.g. the remote service can go down at any time).
- A test case should avoid any database calls, if possible. Any I/O is slow.
- A test case should avoid mocking, when possible. Prefer to use real fixtures
  or refactor the code to not have as many dependencies. Mocking is fragile and
  the whole concept relies on people remembering to update the mocks as they
  refactor the code.
- Related to mocking: it is mostly useful when you want to avoid side-effects
  (e.g. kicking off a task). It does not always make sense to do dependency
  injection just for the sake of testing. In those cases, mocking is your
  preferable option.
- There should be switches that are turned off when running the test suite and
  completely kill unnecessary side-effects and 3rd party integrations entirely
  (e.g. any integration with a 3rd-party service). This way it is easier to
  ensure that you avoid any extra I/O and minimize the dependencies for your
  test.
- Tests should never cross systems: background tasks should not be allowed to be
  called, application-level events should not be handled. For instance, (in the
  case of tasks) write 2 test cases: one that verifies that a task would be
  called with the proper arguments and one that tests how the task works with
  those arguments. Otherwise, your tests also test the message bus.
- Define the input of a test case explicitly. This way you minimize the
  dependencies of the test case and you are certain what the test does.
- Functional/end-to-end tests are useful, but they should be a very small part
  of the test suite and indicated as such. These tests are slow, freagile and
  thus difficult-to-maintain. They can be useful, e.g. to actually test that
  making an API call results in a webhook being sent, but (i) that behavior
  should have been covered by multiple tests already and (b) it makes more sense
  to have that test against a staging environment and not in the test suite.
- If a test case takes more than a few hundred milliseconds to run, it is not a
  unit-test. This is a good indication that a test case does too many things.
- The default case for a test would be to use [`pytest.mark.parametrize`](https://docs.pytest.org/en/latest/parametrize.html#pytest-mark-parametrize-parametrizing-test-functions):
  a test should have certain inputs that lead to certain outputs. Many functions
  should be written in a way that take a certain input and that causes a
  deterministic output. Using `parametrize` helps you write functions in such a
  way and it is a very quick way to test for more inputs and outputs.
- There should be tests not just for the happy path. Code coverage is an
  indicator for how good a test suite is but a meaningless metric. Code should
  be tested as much as possible. The goal should be to cover all possible
  combinations of input/output instead of whether every line has been hit by a
  single test.

Bonus:

- The longer a function is, the more combinations there are to test. Write small
  functions that are as pure as possible.
