# Publish the posts
publish: build _commit_submodule

build:
    hugo

_commit_submodule:
    #!/bin/bash -e
    cd public
    git add -A
    git commit -m "Rebuilding site $(date '+%Y-%m-%dT%H:%M')"
    git push origin master
