# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased][unreleased]
### Fixed

### Added

### Removed

### Changed

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

[unreleased]: https://github.com/gliderlabs/herokuish/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/gliderlabs/herokuish/compare/v0.1.0...v0.2.0