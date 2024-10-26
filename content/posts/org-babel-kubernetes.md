---
title: "Evaluating org code blocks in a Kubernetes pod"
date: 2024-10-26T08:58:25+03:00
---

If you use [org-babel](https://orgmode.org/worg/org-contrib/babel/), you can ask it to run any code blocks in a running kubernetes pod using [tramp's support for kubernetes](https://www.gnu.org/software/tramp/#index-method-kubernetes). This can be achieved with the `:dir` option:


```orgmode
#+begin_src python :results output :dir /kubernetes:container-name.pod-name:/path/to/dir/
print("Hello, world!")
#+end_src
```

You may need to set the options `tramp-kubernetes-context` and `tramp-kubernetes-namespace` first.
