+++
date = "2016-08-13T10:25:01+02:00"
title = "Using .env files"

+++

Enabling the environment variables in a bash script:

    env $(cat .env.test | xargs)
