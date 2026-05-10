# Installing wpa_supplicant-8021X-2020

## Prerequisites

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| CMake | 3.16 | Build system |
| C++ Compiler | C++14 support | GCC 7+, Clang 5+, MSVC 2017+ |
| Python | 3.8 | Tooling scripts |
| Git | 2.x | Version control |

## Build from Source

```bash
# Clone the repository
git clone https://github.com/wpa_supplicant/wpa_supplicant-8021X-2020.git
cd wpa_supplicant-8021X-2020

# Configure
cmake -S . -B build

# Build
cmake --build build

# Run tests
ctest --test-dir build --output-on-failure
```

## Build Options

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_TESTING` | ON | Build test suite |
| `BUILD_EXAMPLES` | OFF | Build example programs |
| `BUILD_DOCS` | OFF | Build Doxygen documentation |
| `ENABLE_COVERAGE` | OFF | Enable code coverage flags |

```bash
cmake -S . -B build -DBUILD_EXAMPLES=ON -DENABLE_COVERAGE=ON
```

## Platform Support

| Platform | Status |
|----------|--------|
| Linux (x86_64) | Primary |
| Windows (x64) | Supported |
| macOS (x86_64/ARM) | Supported |
| ARM Cortex-M7 | Target (cross-compile) |

## Integration into Your Project

### As a CMake subdirectory

```cmake
add_subdirectory(external/wpa_supplicant-8021X-2020)
target_link_libraries(your_target PRIVATE wpa_supplicant-8021X-2020_interface)
```

### As an installed package

```bash
cmake --install build --prefix /usr/local
```

Then in your CMakeLists.txt:
```cmake
find_package(wpa_supplicant-8021X-2020 REQUIRED)
target_link_libraries(your_target PRIVATE wpa_supplicant-8021X-2020::wpa_supplicant-8021X-2020)
```
