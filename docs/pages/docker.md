---
layout: page
title: Installation
permalink: /install/
parent: Getting Started
nav_order: 1
---

# Docker
This section explains how to run the RSMP Validator using Docker. You can also [install locally]({{ site.baseurl}}{% link pages/installing.md %}).

## Setup
1. Download and install [Docker](https://www.docker.com).

2. Download the Docker image with `docker pull ghcr.io/rsmp-nordic/rsmp_validator:docker`. You can find the [available docker images on github](https://github.com/rsmp-nordic/rsmp_validator/pkgs/container/rsmp_validator).


2. Create a local folder for storing validator configurations. It will serve the same purpose as the [config folder](https://rsmp-nordic.org/rsmp_validator/config/) when you install manually.

3. Create a configuration file for the equipment, simulator or supervisor that you want to test. Check out an [example for TLC emulator](https://github.com/rsmp-nordic/rsmp_validator/blob/master/config/gem_tlc.yaml) build into the the rsmp Ruby gem, or ream more about [site test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-site-testing) and [supervisor test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-supervisor-testing).

4. Create a [validator.yaml](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) file inside you config filer and edit it to point to the test config that you created above. (Or as an alternative, set [`SITE_CONFIG` or `SUPERVISOR_CONFIG`
](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) when you run the validator).


## Run tests from the terminal
You run tests by starting the container and running `rspec` inside it. To make your config files available to the container, it must be mounted, identified by its absolute path. If you're inside the folder you can use `$PWD` to get the path:

`% docker container run -it --name rsmp_validator -v $PWD -p 12111:12111 rsmp_validator spec/site/tlc`

By default the validator uses port 12111 when testing rsmp sites, and 14111 when testing supervisors. The port must be mapped using the `-p` option, as shown above.

You can pass custom options to docker or the validator, e.g. to run a specific test, filter tests by tags or use a custom reporting format:

`% docker container run -it --name rsmp_validator -v $PWD -p 12111:12111 rsmp_validator --format Validator::Brief --tags "~slow" spec/site/tlc/detector_logics_spec.rb:31`


## Run tests from Docker Destop
If you're using Docker Desktop, find `rsmp_validator` in the images tab and press `Run`, and Select *Optional settings* using the following settings:
   * Ports: `12111` 
   * Volumes:
     * Host path: *Select the folder you created in step 1*
     * Container Path: `/config`

Start the container. By default the container will run `bundle exec rspec spec/site/tlc`, which will run all TLC (Traffic Light Controller) tests.
