# Porting Guide — wpa_supplicant-8021X-2020

## Overview

This document describes how to port the IEEE 802.1X-2020 implementation to new platforms. The library is designed to be hardware and OS agnostic via dependency injection.

## Architecture for Portability

```
┌─────────────────────────────────┐
│     Your Application            │
├─────────────────────────────────┤
│     Service Layer               │  ← Platform-specific: YOU implement this
│  (bridges protocol to hardware) │
├─────────────────────────────────┤
│     Standards Layer             │  ← This library: pure protocol logic
│  (IEEE 802.1X-2020)            │
└─────────────────────────────────┘
```

## What You Need to Implement

### Network Interface

Implement the `network_interface_t` function pointers for your platform:

```cpp
typedef struct {
    int (*send_packet)(const void* packet, size_t length);
    int (*receive_packet)(void* buffer, size_t* length);
    uint64_t (*get_time_ns)(void);
    int (*set_timer)(uint32_t interval_us, timer_callback_t callback);
} network_interface_t;
```

### Platform Examples

#### Linux
```cpp
static int linux_send_packet(const void* packet, size_t length) {
    return sendto(sock_fd, packet, length, 0, ...);
}
```

#### RTOS (FreeRTOS, Zephyr, etc.)
```cpp
static int rtos_send_packet(const void* packet, size_t length) {
    return rtos_eth_send(packet, length);
}
```

#### Bare Metal
```cpp
static int bare_metal_send_packet(const void* packet, size_t length) {
    return eth_mac_send(packet, length);
}
```

## Porting Checklist

- [ ] Implement `network_interface_t` for your platform
- [ ] Provide a monotonic clock source (`get_time_ns`)
- [ ] Provide timer functionality (`set_timer`)
- [ ] Build the library with your toolchain
- [ ] Run the test suite (mock interface) to verify protocol logic
- [ ] Run integration tests with real hardware

## Cross-Compilation

```bash
cmake -S . -B build-arm \
    -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-cortex-m7.cmake \
    -DBUILD_TESTING=OFF

cmake --build build-arm
```
