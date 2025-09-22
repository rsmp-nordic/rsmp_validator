---
layout: page
title: Docker
permalink: /docker/
parent: Getting Started
nav_order: 1
---

# Running with Docker
This section explains how to run the RSMP Validator using Docker. You can also [install locally]({{ site.baseurl}}{% link pages/installing.md %}).


## Setup
1. Download and install [Docker](https://www.docker.com).

2. Create a local folder for storing validator configurations. It will serve the same purpose as the [config folder](https://rsmp-nordic.org/rsmp_validator/config/) when you install manually.

3. Create a configuration file for the equipment, simulator or supervisor that you want to test. Check out an [example for TLC emulator](https://github.com/rsmp-nordic/rsmp_validator/blob/master/config/gem_tlc.yaml) built into the rsmp Ruby gem, or read more about [site test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-site-testing) and [supervisor test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-supervisor-testing).

4. Create a [validator.yaml](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) file inside your config folder and edit it to point to the test config that you created above. (Or as an alternative, set [`SITE_CONFIG` or `SUPERVISOR_CONFIG`](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) when you run the validator).


## Run from the Terminal
You run the validator by starting the container. You must mount the config folder you created above, so the validator can read files in it. Assuming the config folder you created is at ./config, you can use $PWD to construct the absolute path:

`% docker run --name rsmp_validator -it -v $PWD/config:/config -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator`

By default the validator listens on port 13111 when testing RSMP sites. The port must be mapped using the `-p` option, as shown above.

After running, you can start the container again to re-run the same set of tests and options with:

`% docker start -a rsmp_validator`

To run with different options, remove the container and run again with different options. You can pass `--rm` when running to automatically remove the container after each completion. See the Docker docs for more info about managing containers.

### Custom Options
You can pass [custom options]({{ site.baseurl}}{% link pages/running.md %}) to the validator, e.g. to run specific tests, filter tests by tags or use a custom reporting format.

Use the detailed log format:

`% docker run --name rsmp_validator -it -v $PWD/config:/config -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator spec/site/core --format Validator::Details`

Run a specific test:

`% docker run --name rsmp_validator -it -v $PWD/config:/config -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator spec/site/tlc/detector_logics_spec.rb:31`


### Log Files
By default, the validator produces a single output which will be sent to the terminal. If you like you can direct this output to a file to keep it.

The validator also has the option to produce [multiple outputs]({{ site.baseurl}}{% link pages/output.md %}), directing some to files. When running with Docker, this would by default be to files inside the container. If you remove the container, the files will be lost. If you want to persist these extra log files on the host, you can mount a log folder and write logs to it:

`% docker run --name rsmp_validator -it -v $PWD/config:/config -v $PWD/log:/log -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator spec/site/core --format Validator::Brief --format Validator::Details --out log/validation.log`



## Run from Docker Desktop
You can also run tests from Docker Desktop. Find `rsmp_validator` in the images tab and press `Run`. Select *Optional settings* and then enter:

   * Ports: `13111`
   * Volumes:
     * Host path: *Select the folder you created in step 1*
     * Container Path: `/config`

Start the container by clicking 'Run'. The log output is shown in Docker Desktop.


## Default test set
By default the container will run tests in these two folders:

- `spec/site/core`: tests covering the RSMP Core spec, which apply to all types of sites (equipment).
- `spec/site/tlc`: tests for TLCs (Traffic Light Controllers).

This default set of tests is defined in the CMD directive of the Dockerfile used to build the Docker image.

To change the set of tests run, you could modify the CMD directive in the Dockerfile and rebuild the image. But usually it's easier to just pass custom arguments to the `docker run` command, as shown above.


## Available Images
The latest commit of the master branch is available under the docker tags `latest`, and also as `master`.

Our docker images are published on Github Container Registry. Check the [available images on github](https://github.com/rsmp-nordic/rsmp_validator/pkgs/container/rsmp_validator).
