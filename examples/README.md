# Examples

Example programs demonstrating IEEE 802.1X-2020 protocol usage.

## Walking Skeleton

The `walking_skeleton/` directory contains a minimal example showing:
- Hardware abstraction via dependency injection (function pointers)
- Protocol layer that is completely hardware-agnostic
- Mock implementation for testing without hardware

### Building

```bash
cmake -S .. -B ../build -DBUILD_EXAMPLES=ON
cmake --build ../build
./build/examples/walking_skeleton/walking_skeleton
```

## Adding Examples

When adding new examples:
1. Create a subdirectory under `examples/`
2. Add a `CMakeLists.txt` that links against the protocol library
3. Document the example's purpose and usage
4. Ensure examples compile and run in CI
