# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased][unreleased]
### Fixed

### Added

### Removed

### Changed

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

[unreleased]: https://github.com/gliderlabs/herokuish/compare/v0.3.2...HEAD
[0.3.2]: https://github.com/gliderlabs/herokuish/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/gliderlabs/herokuish/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/gliderlabs/herokuish/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/gliderlabs/herokuish/compare/v0.1.0...v0.2.0
