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

3. Create a configuration file for the equipment, simulator or supervisor that you want to test. Check out an [example for TLC emulator](https://github.com/rsmp-nordic/rsmp_validator/blob/master/config/gem_tlc.yaml) build into the the rsmp Ruby gem, or ream more about [site test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-site-testing) and [supervisor test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-supervisor-testing).

4. Create a [validator.yaml](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) file inside you config filer and edit it to point to the test config that you created above. (Or as an alternative, set [`SITE_CONFIG` or `SUPERVISOR_CONFIG`
](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) when you run the validator).



## Run from the Terminal
You run the validator be starting the container. You must mount the config folder you create above, so the validator can read files in it. Assuming the config folder you created is at ./config, you can use $PWD to construct the absolute path:

`% docker run --rm --name rsmp_validator -it -v $PWD/config:/config -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator`

By default the validator listens on port 13111 when testing rsmp sites. The port must be mapped using the `-p` option, as shown above.

### Custom Arguments
You can pass custom options to the validator, e.g. to run specific tests, filter tests by tags or use a custom reporting format.

Use the detailed log format:

`% docker run --rm --name rsmp_validator -it -v $PWD/config:/config -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator spec/site/core --format Validator::Details`

Run a specific test:

`docker container run -it --name rsmp_validator -v $PWD/config -p 12111:12111 ghcr.io/rsmp-nordic/rsmp_validator spec/site/tlc/detector_logics_spec.rb:31`

See [running]({{ site.baseurl}}{% link pages/running.md %}) for more info regarding options.


### Log Files
By default, the validator produce a single output which will be send to the terminal. If you like you can direct this output to a file to keep it.

The validator also has the option to produce multiple outputs, directing some to files. When running with Docker, this would by default be to files inside the container. As soon as you remove the container, these files will be lost.

If you want to persists these extra log files, you can mount a log folder, and use it to persiste log files:

`docker run --rm --name rsmp_validator -it -v $PWD/config:/config -v $PWD/log:/log -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator spec/site/core --format Validator::Brief --format Validator::Details --out log/validation.log`

Here we mount the local folder `./log` to `/log` in the container. The first `--format Validator::Brief` will output to the terminal. The second `--format Validator::Details --out log/validation.log` specify an additional output format which will be stored to the file `log/validation.log`. Since this is in a mounted host folder, the log file will be kept after the container is deleted.


## Run from Docker Desktop
You can also run tests from Docker Desktop. Find `rsmp_validator` in the images tab and press `Run`, Select *Optional settings* and then enter:

   * Ports: `13111`
   * Volumes:
     * Host path: *Select the folder you created in step 1*
     * Container Path: `/config`

Start the container by cliking 'Run'. The log output is shown in Docker Desktop.


## Default test set
By default the container will run tests in these two folders:

- `spec/site/core`: tests covering the RSMP Core spec, which apply to all types of sites (equipment).
- `spec/site/tlc`: test for TLCs (Traffic Light Controller).

This default set of tests is defined in the CMD directive of the Dockerfile used to build the Docker image.

To change the set of tests run, you could modifify the CMD directive in the Dockerfile and rebuild the image. But usually it's easier to just override pass custom arguments to the `docker run` command, as shown above.


## Available Images
The latest commit of the master branch is available under the docker tags `latest`, and also as `master`.

Our docker images are publish on Github Container Registry. Check the [available images on github](https://github.com/rsmp-nordic/rsmp_validator/pkgs/container/rsmp_validator).
