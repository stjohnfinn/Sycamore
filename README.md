# Sycamore

A shell script that takes the name of a GitLab pipeline job as input (and some
other stuff optionally) and outputs a shell script that exports relevant
environment variables.

Don't ask me sh*t about how the code works, Claude wrote it.

## Usage

Parse the `build-job` pipeline job:

    ./sycamore.sh --job build-job

Parse the `build-job` pipeline job from the file
`Pipeline.gitlab-ci.yml`:

    ./sycamore.sh --job build-job --pipeline-file Pipeline.gitlab-ci.yml

## Installation

1. Copy the script to somewhere in your `$PATH`.

    mkdir -p $HOME/.local/bin
    install -m 755 ./sycamore.min.sh ~/.local/bin

1. Add the autocomplete file.

    install -m 644 ./sycamore-completion.min.bash /etc/bash_completion.d/
