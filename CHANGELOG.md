# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased][unreleased]
### Fixed

### Added

### Removed

### Changed

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

[unreleased]: https://github.com/gliderlabs/herokuish/compare/v0.3.8...HEAD
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
