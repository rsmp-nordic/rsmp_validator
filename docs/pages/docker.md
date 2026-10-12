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

2. Create a local folder for storing validator configurations. When mounted into the container, this folder serves the same purpose as the [config folder](https://rsmp-nordic.org/rsmp_validator/config/) when you install manually.

3. Create a configuration file for the equipment, simulator or supervisor that you want to test. Check out the [TLC example config](https://github.com/rsmp-nordic/rsmp_validator/blob/main/config/gem_tlc.yaml), or read more about [site test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-site-testing) and [supervisor test configurations](https://rsmp-nordic.org/rsmp_validator/config/#options-for-supervisor-testing).

4. Choose the config with `--site-config` or `--supervisor-config` when you run the validator. Alternatively, create a [validator.yaml](https://rsmp-nordic.org/rsmp_validator/config/#choosing-what-config-to-use) file and mount it at `/app/config/validator.yaml`, as described below.

## Run from the Terminal
You run the validator by starting the container. The container image includes the validator, test suite, and example configuration files under `/app`.

By default, the image runs the bundled site tests and waits for an external site using the bundled `config/gem_tlc.yaml` test configuration:

```console
% docker run --rm -it -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator
```

By default, the image runs these test folders:

- `test/site/core`: tests covering the RSMP Core spec, which apply to all types of sites.
- `test/site/tlc`: tests for TLCs (Traffic Light Controllers).

To run a self-contained test against the bundled simulator instead, enable the auto site explicitly:

```console
% docker run --rm -it ghcr.io/rsmp-nordic/rsmp_validator run test/site/core test/site/tlc --auto-site-config config/simulator/tlc.yaml
```

For testing a real site, mount the config folder you created above and select the site config. Assuming the config folder is at `./config`, use `$PWD` to construct the absolute host path:

```console
% docker run --name rsmp-validator -it \
  -v "$PWD/config:/config:ro" \
  -p 13111:13111 \
  ghcr.io/rsmp-nordic/rsmp_validator \
  run test/site --site-config /config/my_site.yaml
```

By default the validator listens on port 13111 when testing RSMP sites. The port must be mapped using the `-p` option, as shown above.

After running, you can start the container again to re-run the same set of tests and options with:

```console
% docker start -a rsmp-validator
```

To run with different options, remove the container and run again with different options. You can pass `--rm` when running to automatically remove the container after each completion. See the Docker docs for more info about managing containers.

## Choosing Config
Inside the container, relative paths are resolved from `/app`. For example, `config/gem_tlc.yaml` means `/app/config/gem_tlc.yaml`, the bundled example config.

If you mount your own config folder with `-v "$PWD/config:/config:ro"`, refer to those host files with `/config/...`.

You can choose config in two ways.

The validator looks for its config reference file at `/app/config/validator.yaml`. The image's bundled reference file selects the bundled site and supervisor test configurations; it does not enable an auto node. Mounting a config folder at `/config` does not replace that file, so mount your `validator.yaml` separately:

```yaml
site: /config/my_site.yaml
supervisor: /config/my_supervisor.yaml
```

Then run:

```console
% docker run --rm -it \
  -v "$PWD/config:/config:ro" \
  -v "$PWD/config/validator.yaml:/app/config/validator.yaml:ro" \
  -p 13111:13111 \
  ghcr.io/rsmp-nordic/rsmp_validator \
  run test/site
```

Or pass the config path directly with a command-line option:

```console
% docker run --rm -it \
  -v "$PWD/config:/config:ro" \
  -p 13111:13111 \
  ghcr.io/rsmp-nordic/rsmp_validator \
  run test/site --site-config /config/my_site.yaml
```

Use `--supervisor-config` when testing a supervisor. Config path options take precedence over `validator.yaml`.

When testing a supervisor, the validator connects out from the container, so you normally do not need `-p`. If the supervisor runs on the Docker host, use `host.docker.internal` as its address in the validator config. On Linux, also add `--add-host host.docker.internal:host-gateway` to the `docker run` command.

### Custom Options
You can pass [custom options]({{ site.baseurl}}{% link pages/running.md %}) to the validator, e.g. to run specific tests or enable RSMP logging.

Enable RSMP logging:

```console
% docker run --rm -it -v "$PWD/config:/config:ro" -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator run test/site --site-config /config/my_site.yaml --log
```

Override the RSMP Core and SXL versions for a run:

```console
% docker run --rm -it -v "$PWD/config:/config:ro" -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator run test/site --site-config /config/my_site.yaml --core 3.2.2 --sxls tlc:1.2.1
```

Run a specific test:

```console
% docker run --rm -it -v "$PWD/config:/config:ro" -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator run test/site/core/connect_spec.rb --site-config /config/my_site.yaml
```

### Log Files
By default, the validator produces output to the terminal. You can also write RSMP logs to a file inside the container using `--log-path`. If you want to persist log files on the host, mount a log folder:

```console
% docker run --rm -it -v "$PWD/config:/config:ro" -v "$PWD/log:/log" -p 13111:13111 ghcr.io/rsmp-nordic/rsmp_validator run test/site --site-config /config/my_site.yaml --log-path /log/rsmp.log
```

## Run from Docker Desktop
You can also run tests from Docker Desktop. Find `rsmp_validator` in the images tab and press `Run`. Select *Optional settings* and then enter:

- Ports: host `13111`, container `13111`
- Volumes:
  - Host path: select the config folder you created above
  - Container Path: `/config`
  - Host path: select `validator.yaml` inside that config folder
  - Container Path: `/app/config/validator.yaml`

Start the container by clicking 'Run'. The log output is shown in Docker Desktop.

## Available Images
The latest published image is available under the docker tag `latest`.

Our Docker images are published on GitHub Container Registry. Check the [available images on GitHub](https://github.com/rsmp-nordic/rsmp_validator/pkgs/container/rsmp_validator).
