# herokuish

A command line tool for emulating Heroku build and runtime operations. It pairs excellently with [cedarish](https://github.com/progrium/cedarish), though you can likely use it anywhere.

The project consolidates and decouples Heroku "emulation" logic from specific platform images like those used by Dokku/Buildstep, Deis, Flynn, etc with the intention of being a shared utility across communities with extensive test coverage.

Target users for herokuish are platform authors, like those of Dokku, Deis, and Flynn. Herokuish was designed based on the experience developing and re-developing Heroku compatibility in all three of those projects.  

[![Circle CI](https://circleci.com/gh/gliderlabs/herokuish.png?style=shield)](https://circleci.com/gh/gliderlabs/herokuish)

## Getting herokuish

Download and uncompress the latest binary tarball from [releases](https://github.com/gliderlabs/herokuish/releases). 

For example, you can do this directly in your Dockerfiles installing into `/bin` as one step:

```
RUN curl https://github.com/gliderlabs/herokuish/releases/download/v0.1.0/herokuish_0.1.0_linux_x86_64.tgz \
		--silent -L | tar -xzC /bin
```

It depends on Bash (4.0 or newer) and a handful of standard GNU utilties you probably have. It likely won't work on Busybox, though neither will any Heroku buildpacks.

## Using herokuish

Herokuish is meant to work behind the scenes inside a container. It makes little assumptions about how you construct those containers or the operational decisions behind them. It focuses on neatly emulating Heroku, letting you design and orchestrate containers around it.

```
$ herokuish

Available commands:
  buildpack                Use and install buildpacks
    build                    Build an application using installed buildpacks
    install                  Install buildpack from Git URL and optional committish
    list                     List installed buildpacks
  help                     Shows help information for a command
  paths                    Shows path settings
  procfile                 Use Procfiles and run app commands
    exec                     Run as random, unprivileged user with Heroku-like env
    parse                    Get command string for a process type from Procfile
    start                    Run process type command from Procfile through exec
  slug                     Manage application slugs
    export                   Export generated slug tarball to URL (PUT) or STDOUT
    generate                 Generate a gzipped slug tarball from the current app
    import                   Import a gzipped slug tarball from URL or STDIN
  version                  Show version and supported version info

```

Main functionality revolves around buildpack commands, procfile/exec commands, and slug commands. They are made to work together, but can be used independently or not at all. 

For example, build processes that produce Docker images without producing intermediary slugs can ignore slug commands. Similarly, non-buildpack runtime images such as [google/python-runtime](https://github.com/GoogleCloudPlatform/python-docker/tree/master/runtime) might find procfile commands useful just to support Procfiles.

#### Buildpacks

Herokuish does not come with any buildpacks, but it is tested against recent versions of Heroku supported buildpacks. You can see this information (soon) with `herokuish version`. 

Although you can manually install buildpacks individually with `herokuish buildpack install`, it's better to mount a directory containing your platform's supported buildpacks. Alternatively, you could bake your supported buildpacks into an image. These are the types of decisions that are up to you.

#### Paths

Use `herokuish paths` to see relevant system paths it uses. You can use these to import or mount data for use inside a container. They can also be overridden by setting the appropriate environment variable.

```
$ herokuish paths
APP_PATH=/app                    # Application path during runtime
ENV_PATH=/tmp/env                # Path to files for defining base environment
BUILD_PATH=/tmp/build            # Working directory during builds
CACHE_PATH=/tmp/cache            # Buildpack cache location
BUILDPACK_PATH=/tmp/buildpacks   # Path to installed buildpacks

```

#### Entrypoints

Some subcommands are made to be used as default commands or entrypoint commands for containers. Specifically, herokuish detects if it was called as `/start`, `/exec`, or `/build` which will shortcut it to running those subcommands directly. This means you can either install the binary in those locations or create symlinks from those locations, allowing you to use them as your container entrypoint.

#### Help

Don't be afraid of the help command. It actually tells you exactly what a command does:

```
$ herokuish help slug export
slug-export <url> 
  Export generated slug tarball to URL (PUT) or STDOUT

slug-export () 
{ 
    declare desc="Export generated slug tarball to URL (PUT) or STDOUT";
    declare url="$1";
    if [[ ! -f "$slug_path" ]]; then
        return 1;
    fi;
    if [[ -n "$url" ]]; then
        curl -0 -s -o /dev/null --retry 2 -X PUT -T "$slug_path" "$url";
    else
        cat "$slug_path";
    fi
}

```

## Contributing

Pull requests are welcome! Herokuish is written in Bash and Go. Please conform to the [Bash styleguide](https://github.com/progrium/bashstyle) used for this project when writing Bash.

Developers should have Go installed with cross-compile support for Darwin and Linux. Tests will require Docker to be available. If you have OS X, we recommend boot2docker.

## Sponsor

This project was made possible by the [Deis Project](http://deis.io).

## License

BSD