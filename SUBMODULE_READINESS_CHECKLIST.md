# Submodule Readiness Checklist — wpa_supplicant-8021X-2020

## Purpose

This checklist validates that the IEEE 802.1X-2020 library is ready to be consumed as a Git submodule by downstream projects.

## API Stability

- [ ] Public API headers are in `include/` directory
- [ ] API is documented with Doxygen comments
- [ ] Breaking changes follow semantic versioning
- [ ] Deprecation warnings for removed features

## Build Integration

- [ ] `add_subdirectory()` works from parent CMake project
- [ ] No absolute paths in CMakeLists.txt
- [ ] No `CMAKE_SOURCE_DIR` usage (use `PROJECT_SOURCE_DIR` instead)
- [ ] `FetchContent` compatible
- [ ] Install targets defined

## Dependencies

- [ ] All dependencies documented in INSTALL.md
- [ ] External dependencies fetched via CMake FetchContent
- [ ] No system-specific package requirements
- [ ] Submodule works with `--recursive` clone

## Testing

- [ ] Tests can run independently
- [ ] Tests don't modify global state
- [ ] `BUILD_TESTING` option disables tests when used as subdirectory
- [ ] No test-only files pollute install

## Documentation

- [ ] README.md explains integration steps
- [ ] PORTING_GUIDE.md covers platform requirements
- [ ] API reference generated from headers
- [ ] Changelog maintained

## CI/CD

- [ ] CI validates submodule integration
- [ ] Version tags follow SemVer
- [ ] Release artifacts include source tarball
