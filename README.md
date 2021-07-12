# herokuish

[![Circle CI](https://circleci.com/gh/gliderlabs/herokuish.png?style=shield)](https://circleci.com/gh/gliderlabs/herokuish)
[![IRC Channel](https://img.shields.io/badge/irc-%23gliderlabs-blue.svg)](https://kiwiirc.com/client/irc.freenode.net/#gliderlabs)
[![Docker Hub](https://img.shields.io/badge/docker%20hub-v0.5.29-blue)](https://hub.docker.com/r/gliderlabs/herokuish)

A command line tool for emulating Heroku build and runtime tasks in containers.

Herokuish is made for platform authors. The project consolidates and decouples Heroku compatibility logic (running buildpacks, parsing Procfile) and supporting workflow (importing/exporting slugs) from specific platform images like those in Dokku/Buildstep, Deis, Flynn, etc.

The goal is to be the definitive, well maintained and heavily tested Heroku emulation utility shared by all. It is based on the [Heroku:18 and Heroku:20 system images](https://github.com/heroku/stack-images). Together they form a toolkit for achieving Heroku compatibility.

Herokuish is a community project and is in no way affiliated with Heroku.

## Getting herokuish

Download and uncompress the latest binary tarball from [releases](https://github.com/gliderlabs/herokuish/releases).

For example, you can do this directly in your Dockerfiles installing into `/bin` as one step:

```
RUN curl --location --silent https://github.com/gliderlabs/herokuish/releases/download/v0.5.29/herokuish_0.5.29_linux_x86_64.tgz \
		  | tar -xzC /bin
```

Herokuish depends on Bash (4.0 or newer) and a handful of standard GNU utilties you probably have. It likely won't work on Busybox, though neither will any Heroku buildpacks.

## Using herokuish

Herokuish is meant to work behind the scenes inside a container. It tries not to force decisions about how you construct and operate containers. In fact, there's nothing that even ties it specifically to Docker. It focuses on neatly emulating Heroku, letting you design and orchestrate containers around it.

```
$ herokuish

Available commands:
  buildpack                Use and install buildpacks
    build                    Build an application using installed buildpacks
    install                  Install buildpack from Git URL and optional committish
    list                     List installed buildpacks
    test                     Build and run tests for an application using installed buildpacks
  help                     Shows help information for a command
  paths                    Shows path settings
  procfile                 Use Procfiles and run app commands
    exec                     Run as unprivileged user with Heroku-like env
    parse                    Get command string for a process type from Procfile
    start                    Run process type command from Procfile through exec
  slug                     Manage application slugs
    export                   Export generated slug tarball to URL (PUT) or STDOUT
    generate                 Generate a gzipped slug tarball from the current app
    import                   Import a gzipped slug tarball from URL or STDIN
  test                     Test running an app through Herokuish
  version                  Show version and supported version info

```

Main functionality revolves around buildpack commands, procfile/exec commands, and slug commands. They are made to work together, but can be used independently or not at all.

For example, build processes that produce Docker images without producing intermediary slugs can ignore slug commands. Similarly, non-buildpack runtime images such as [google/python-runtime](https://github.com/GoogleCloudPlatform/python-docker/tree/master/runtime) might find procfile commands useful just to support Procfiles.

`herokuish exec` will by default drop root privileges through use of [setuidgid](https://cr.yp.to/daemontools/setuidgid.html),
but if already running as a non-root user setuidgid will fail, you can opt-out from this by setting the env-var `HEROKUISH_SETUIDGUID=false`.

#### Buildpacks

Herokuish does not come with any buildpacks, but it is tested against recent versions of Heroku supported buildpacks. You can see this information with `herokuish version`. Example output:

```
$ herokuish version
herokuish: 0.3.0
buildpacks:
  heroku-buildpack-multi     cddec34
  heroku-buildpack-nodejs    v60
  heroku-buildpack-php       v43
  heroku-buildpack-python    v52
  heroku-buildpack-ruby      v127
  ...
```

You can install all supported buildpacks with `herokuish buildpack install`, or you can manually install buildpacks individually with `herokuish buildpack install <url> [committish]`. You can also mount a directory containing your platform's supported buildpacks (see Paths, next section), or you could bake your supported buildpacks into an image. These are the types of decisions that are up to you.

#### Paths

Use `herokuish paths` to see relevant system paths it uses. You can use these to import or mount data for use inside a container. They can also be overridden by setting the appropriate environment variable.

```
$ herokuish paths
APP_PATH=/app                    # Application path during runtime
ENV_PATH=/tmp/env                # Path to files for defining base environment
BUILD_PATH=/tmp/build            # Working directory during builds
CACHE_PATH=/tmp/cache            # Buildpack cache location
IMPORT_PATH=/tmp/app             # Mounted path to copy to app path
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

## Using Herokuish to test Heroku/Dokku apps

Having trouble pushing an app to Dokku or Heroku? Use Herokuish with a local Docker
instance to debug. This is especially helpful with Dokku to help determine if it's a buildpack
issue or an issue with Dokku. Buildpack issues should be filed against Herokuish.

#### Running an app against Herokuish

```
$ docker run --rm -v /abs/app/path:/tmp/app gliderlabs/herokuish /bin/herokuish test
```

Mounting your local app source directory to `/tmp/app` and running `/bin/herokuish test` will run your app through the buildpack compile process. Then it starts your `web` process and attempts to connect to the web root path. If it runs into a problem, it should exit non-zero.

```
::: BUILDING APP :::
-----> Ruby app detected
-----> Compiling Ruby/Rack
-----> Using Ruby version: ruby-1.9.3
  ...

```

You can use this output when you submit issues.

#### Running an app tests using Heroku buildpacks

```
$ docker run --rm -v /abs/app/path:/tmp/app gliderlabs/herokuish /bin/herokuish buildpack test
```

Mounting your local app source directory to `/tmp/app` and running `/bin/herokuish buildpack test` will run your app through the buildpack test-compile process. Then it will run `test` command to execute application tests.

```
-----> Ruby app detected
-----> Setting up Test for Ruby/Rack
-----> Using Ruby version: ruby-2.3.3
  ...
-----> Detecting rake tasks
-----> Running test: bundle exec rspec
       .
       Finished in 0.00239 seconds (files took 0.07525 seconds to load)
       1 example, 0 failures
```

#### Troubleshooting

If you run into an issue and looking for more insight into what `herokuish` is doing, you can set the `$TRACE` environment variable.

```
$ docker run --rm -e TRACE=true -v /abs/app/path:/tmp/app gliderlabs/herokuish /bin/herokuish test
+ [[ -d /tmp/app ]]
+ rm -rf /app
+ cp -r /tmp/app /app
+ cmd-export paths
+ declare 'desc=Exports a function as a command'
+ declare fn=paths as=paths
+ local ns=
++ cmd-list-ns
++ sort
++ grep -v :
++ for k in '"${!CMDS[@]}"'
++ echo :help
...
++ unprivileged /tmp/buildpacks/custom/bin/detect /tmp/build
++ setuidgid u33467 /tmp/buildpacks/custom/bin/detect /tmp/build
++ true
+ selected_name=
+ [[ -n /tmp/buildpacks/custom ]]
+ [[ -n '' ]]
+ title 'Unable to select a buildpack'
----->' Unable to select a buildpack
+ exit 1
```

## Contributing

Pull requests are welcome! Herokuish is written in Bash and Go. Please conform to the [Bash styleguide](https://github.com/progrium/bashstyle) used for this project when writing Bash.

Developers should have Go installed with cross-compile support for Darwin and Linux. Tests will require Docker to be available. If you have OS X, we recommend boot2docker.

For help and discussion beyond Github Issues, join us on Freenode in `#gliderlabs`.

## Releases

Anybody can propose a release. First bump the version in `Makefile` and `Dockerfile`, make sure `CHANGELOG.md` is up to date, and make sure tests are passing. Then open a Pull Request from `master` into the `release` branch. Once a maintainer approves and merges, CircleCI will build a release and upload it to Github.

## Acknowledgements

This project was sponsored and made possible by the [Deis Project](http://deis.io).

That said, herokuish was designed based on the experience developing and re-developing Heroku compatibility in Dokku, Deis, and Flynn. Herokuish is based on code from all three projects, as such, thank you to all the contributors of those projects.

In fact, since I hope this is the final implementation of Heroku emulation I'm involved with, I'd like to finally thank Matt Freeman ([@nonuby](https://twitter.com/nonuby)). I've been more or less copy-and-pasting code he originally wrote for the now defunct [OpenRuko](https://github.com/openruko) since 2012.

Lastly, thank you Heroku for pioneering such a great platform and inspiring all of us to try and take it further.

## License

BSD
<img src="https://ga-beacon.appspot.com/UA-58928488-2/herokuish/readme?pixel" />
