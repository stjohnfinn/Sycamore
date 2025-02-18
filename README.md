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
   
    For the entire machine:
   
       install -m 644 ./sycamore-completion.min.bash /etc/bash_completion.d/
   
    For just you:
   
       mkdir -p ~/.bash_completion.d/
       install -m 600 ./sycamore-completion.min.bash ~/.bash_completion.d/
       echo "source ~/.bash_completion.d/sycamore-completion.min.bash"   

## Build

There is a `build.sh` script in here that just `minifies` all of the 
scripts.

## Test

There is a `test.sh` script in here that contains regression tests I think. They
aren't really unit tests because they test the entire script. They test the 
behavior of the entire script as a unit. Right now, the test set is pretty 
small, but it will be expanded in the future.

## Known Issues

- `extends` keyword processing isn't written to handle cases where `extend`ed 
jobs use variables from the child job. GitLab YAML parser is able to deal with
this but Sycamore is not. Luckily, the error will be half-caught because 
`set -u` is enabled. If you hit an undefined variable error message, try 
reordering the lines.
