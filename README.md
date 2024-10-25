# Sycamore

A shell script that makes it easier to run GitLab Pipelines locally.

Don't ask me sh*t about how the code works, Claude wrote it.

## Usage

Create a shell script that executes the `build-job` pipeline job:

    ./sycamore.sh --job build-job

Create a shell script that executes the `build-job` pipeline job and then run
the created shell script:

    ./sycamore.sh --job build-job --run

Create a shell script that executes the `build-job` pipeline job from the file
`Pipeline.gitlab-ci.yml`:

    ./sycamore.sh --job build-job --pipeline-file Pipeline.gitlab-ci.yml

This script does not support any of the following actions right now:

* running an entire pipeline
* running or converting multiple pipeline jobs with a single command

I just need this for work on monday, so I don't really want to extend it more 
than I have to.

## Todo

Turn this into a Golang project or Python project.
