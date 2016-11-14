# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased][unreleased]
### Fixed

### Added

### Removed

### Changed


## [0.3.21] - 2016-11-14
### Changed
- @michaelshobbs remove emberjs buildpack from default set
- @michaelshobbs skip blank lines in .env. closes #195


## [0.3.20] - 2016-11-13
### Changed
- @michaelshobbs new .env parser that handles spaces
- @michaelshobbs change readme instructions to use github releases
- @michaelshobbs Update go to version v52
- @michaelshobbs Update php to version v114
- @michaelshobbs Update python to version v83


## [0.3.19] - 2016-09-20
### Changed
- @josegonzalez Update static buildpack to v6
- @michaelshobbs Update gradle to version v18
- @michaelshobbs Update java to version v46
- @michaelshobbs Update php to version v110
- @michaelshobbs Update python to version v82


## [0.3.18] - 2016-07-29
### Changed
- @xtian Don't print .release file during build
- @michaelshobbs Update php to version v109
- @michaelshobbs Update go to version v44
- @michaelshobbs Update scala to version v72


## [0.3.17] - 2016-07-14
### Fixed
- @michaelshobbs set unprivileged user/group to same name and test with this user


## [0.3.16] - 2016-07-14
### Added
- @michaelshobbs add named unprivileged user


## [0.3.15] - 2016-07-14
### Fixed
- @joshmanders only delete $app_path if $import_path is not empty. fixes #111

### Changed
- @michaelshobbs Update go to version v42
- @michaelshobbs Update nodejs to version v91
- @michaelshobbs Update php to version v108
- @michaelshobbs Update python to version v81
- @michaelshobbs Update scala to version v71


## [0.3.14] - 2016-06-27
### Added
- @michaelshobbs implement heroku-like buildpack detect order and output. closes #133

### Fixed
- @michaelshobbs because nodejs matches before ember, manually set the ember buildpack

### Changed
- @michaelshobbs Update go to version v41
- @michaelshobbs Update grails to version v21
- @michaelshobbs Update php to version v107


## [0.3.13] - 2016-05-09
### Fixed
- @michaelshobbs ensure correct permissions on tgz buildpack directories

### Changed
- @michaelshobbs Update php to version v102
- @michaelshobbs Update go to version v36


## [0.3.12] - 2016-04-27
### Fixed
- @michaelshobbs try testing port more times before continuing. add output when testing for a listener
- @michaelshobbs increase retry in an attempt to allow the (ember specifially) app to fully startup

### Added
- @michaelshobbs support compressed tarball buildpacks (#144)

### Changed
- @michaelshobbs Update go to version v34
- @michaelshobbs Update nodejs to version v90
- @michaelshobbs Update php to version v101
- @michaelshobbs Update scala to version v70


## [0.3.11] - 2016-04-07
### Changed
- @michaelshobbs Update php to version v100 (#140)
- @michaelshobbs Update python to version v80 (#141)


## [0.3.10] - 2016-03-30
### Changed
- @michaelshobbs Update nodejs to version v89
- @michaelshobbs Update php to version v99
- @michaelshobbs Update python to version v79
- @michaelshobbs Update ruby to version v146
- @michaelshobbs Update scala to version v67


## [0.3.9] - 2016-03-08
### Fixed
- @graphaelli clean up link warning

### Added
- @michaelshobbs extract config_vars from .release

### Changed
- @singlow singlow use find to identify only files not already owned by user
- @michaelshobbs Update clojure to version v75
- @michaelshobbs Update grails to version v20
- @michaelshobbs Update java to version v44
- @michaelshobbs Update nodejs to version v88
- @michaelshobbs Update play to version v26
- @michaelshobbs Update python to version v77
- @michaelshobbs Update ruby to version v145
- @michaelshobbs Update scala to version v66
- @michaelshobbs Update php to version v95
- @michaelshobbs Update go to version v31
- @michaelshobbs upgrade to go1.6


## [0.3.8] - 2016-01-06
### Changed
- @josegonzalez Upgrade gradle buildpack version to 17
- @josegonzalez Update java buildpack version to 42
- @josegonzalez Update scala buildpack version to 64


## [0.3.7] - 2015-12-31
### Fixed
- @michaelshobbs force rebuild of packages that are already up to date
- @michaelshobbs fix buildpack version output after adding dokku/buildpack-nginx

### Removed
- @michaelshobbs remove unnecessary null line check

### Changed
- @michaelshobbs re-implement yaml-get and yaml-keys in bash
- @CEikermann Updated buildpack-php to v90
- @josegonzalez Upgrade python buildpack to v74


## [0.3.6] - 2015-12-14
### Changed
- Update php buildpack to version 87
- Update clojure buildpack to version 73
- Update golang buildpack to version 22
- Update gradle buildpack to version 16
- Update java buildpack to version 41
- Update nodejs buildpack to version 87
- Update python buildpack to version 73
- Update ruby buildpack to version 141
- Update multi buildpack to version v1.0.0


## [0.3.5] - 2015-11-25
### Added
- Add static buildpack and test

### Changed
 - Increased CURL_TIMEOUT env var in buildpacks from the default 30 to 180
 - Update python buildpack to v70
 - Update static buildpack to v5
 - Update local build env to docker 1.9.1


## [0.3.4] - 2015-10-23
### Changed
- Upgrade clojure buildpack to version 70
- Update go buildpack to version 18
- Update java buildpack to version 40
- Update nodejs buildpack to version 86
- Update php buildpack to version 80
- Update python buildpack to version 68
- Update ruby buildpack to version 140
- Update scala buildpack to version 63


## [0.3.3] - 2015-09-10
### Added
- Use exec to run procfile entries
- Throw error when detect fails in custom buildpack

### Changed
- Bumped scala buildpack to v60


## [0.3.2] - 2015-07-28
### Added
- Repo Analytics to README

### Changed
- Bumped golang buildpack to fa0679c
- Bumped php buildpack to version 70
- Bumped clojure buildpack to version 67
- Bumped grails to version 19
- Bumped java buildpack to version 38
- Bumped multi buildpack to 26fa21a
- Bumped play buildpack to version 24
- Bumped python buildpack to version 61
- Bumped ruby buildpack to version 138


## [0.3.1] - 2015-07-09
### Fixed
- Fixed directory permission for custom buildpacks

### Added
- Added ability to build in docker container

### Removed
- Remove testing play-v1 from play buildpack

### Changed
- Build from mainline heroku/cedar:14 docker images
- Bump nodejs/scala buildpack versions


## [0.3.0] - 2015-04-04
### Fixed
- Fixed Scala buildpack and app test
- Fixed collision issue with `VERSION` environment variable

### Added
- Added Dockerfile making Herokuish an alternative for Buildstep
- Added `PS1` and source `/etc/profile.d` like Buildstep
- Added `IMPORT_PATH` to copy to `APP_PATH` for untouched mounted apps
- Added `herokuish test` command for testing apps against Herokuish

### Removed
- Dropped shunit2 for [basht](https://github.com/progrium/basht)
- Dropped cedarish cache and release tracking

### Changed
- *Significantly* reduced complexity of testing setup
- Moved buildpack versions and app tests to `buildpacks` directory
- Prepared for automated tracking branches for latest buildpacks


## [0.2.0] - 2015-02-10
### Fixed
- Fixed CI issue with `go get` on CircleCI
- Updated go-basher usage to latest API
- Buildpack setup uses `$unprivileged_user` instead of hardcoded `nobody`
- Buildpack compile happens in `$build_path`
- Default buildpack process types added to a created Procfile

### Added
- Buildpack clones try to be shallow
- Ability to set `$unprivileged_user` with `$USER`
- Grails buildpack support and test app
- Play (v1) test app

#### Removed
- Dropped bindata.go from repo

#### Changed
- Updated to latest buildpack releases
- User for `buildpack-build` is `$USER` or randomized
- User for `procfile-exec` is `$USER` or detected from `/app`

[unreleased]: https://github.com/gliderlabs/herokuish/compare/v0.3.21...HEAD
[0.3.21]: https://github.com/gliderlabs/herokuish/compare/v0.3.20...v0.3.21
[0.3.20]: https://github.com/gliderlabs/herokuish/compare/v0.3.19...v0.3.20
[0.3.19]: https://github.com/gliderlabs/herokuish/compare/v0.3.18...v0.3.19
[0.3.18]: https://github.com/gliderlabs/herokuish/compare/v0.3.17...v0.3.18
[0.3.17]: https://github.com/gliderlabs/herokuish/compare/v0.3.16...v0.3.17
[0.3.16]: https://github.com/gliderlabs/herokuish/compare/v0.3.15...v0.3.16
[0.3.15]: https://github.com/gliderlabs/herokuish/compare/v0.3.14...v0.3.15
[0.3.14]: https://github.com/gliderlabs/herokuish/compare/v0.3.13...v0.3.14
[0.3.13]: https://github.com/gliderlabs/herokuish/compare/v0.3.12...v0.3.13
[0.3.12]: https://github.com/gliderlabs/herokuish/compare/v0.3.11...v0.3.12
[0.3.11]: https://github.com/gliderlabs/herokuish/compare/v0.3.10...v0.3.11
[0.3.10]: https://github.com/gliderlabs/herokuish/compare/v0.3.9...v0.3.10
[0.3.9]: https://github.com/gliderlabs/herokuish/compare/v0.3.8...v0.3.9
[0.3.8]: https://github.com/gliderlabs/herokuish/compare/v0.3.7...v0.3.8
[0.3.7]: https://github.com/gliderlabs/herokuish/compare/v0.3.6...v0.3.7
[0.3.6]: https://github.com/gliderlabs/herokuish/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/gliderlabs/herokuish/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/gliderlabs/herokuish/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/gliderlabs/herokuish/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/gliderlabs/herokuish/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/gliderlabs/herokuish/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/gliderlabs/herokuish/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/gliderlabs/herokuish/compare/v0.1.0...v0.2.0
