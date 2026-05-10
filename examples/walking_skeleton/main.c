/**
 * @file main.c
 * @brief Walking skeleton for IEEE 802.1X-2020 implementation
 *
 * This minimal example demonstrates the dependency injection pattern
 * used throughout the 802.1X-2020 protocol library. It shows
 * how the standards layer receives hardware abstraction via function
 * pointers, keeping protocol logic completely hardware-agnostic.
 *
 * This is a starting point — replace with actual protocol logic.
 *
 * @see IEEE 802.1X-2020 specification for authoritative requirements.
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* ─── Hardware Abstraction Interface ─────────────────────────────────────── */
/* This is the interface that platform-specific code must implement.         */

typedef int      (*send_fn)(const void* packet, size_t length);
typedef int      (*recv_fn)(void* buffer, size_t* length);
typedef uint64_t (*time_fn)(void);

typedef struct {
    send_fn  send_packet;
    recv_fn  receive_packet;
    time_fn  get_time_ns;
} network_interface_t;

/* ─── Protocol Logic (Standards Layer) ──────────────────────────────────── */
/* Pure protocol logic — no hardware calls, no OS calls.                    */

int protocol_init(const network_interface_t* iface) {
    if (!iface || !iface->send_packet || !iface->receive_packet || !iface->get_time_ns) {
        return -1;  /* Invalid interface */
    }
    printf("[Protocol] 802.1X-2020 initialized with hardware abstraction\n");
    return 0;
}

int protocol_send_message(const network_interface_t* iface, uint8_t msg_type) {
    uint8_t packet[64];
    memset(packet, 0, sizeof(packet));
    packet[0] = msg_type;   /* Message type field */
    packet[1] = 0x02;       /* Protocol version   */

    int result = iface->send_packet(packet, sizeof(packet));
    if (result == 0) {
        printf("[Protocol] Sent message type 0x%02X at time %lu ns\n",
               msg_type, (unsigned long)iface->get_time_ns());
    }
    return result;
}

/* ─── Mock Implementation (for testing / walking skeleton) ─────────────── */

static uint64_t mock_clock_ns = 0;

static int mock_send(const void* packet, size_t length) {
    (void)packet;
    printf("[Mock HAL] Sent %zu bytes\n", length);
    return 0;
}

static int mock_recv(void* buffer, size_t* length) {
    (void)buffer;
    *length = 0;
    return 0;
}

static uint64_t mock_time(void) {
    mock_clock_ns += 1000;  /* Advance 1 µs per call */
    return mock_clock_ns;
}

/* ─── Main ───────────────────────────────────────────────────────────────── */

int main(void) {
    printf("=== IEEE 802.1X-2020 Walking Skeleton ===\n\n");

    network_interface_t mock = {
        .send_packet    = mock_send,
        .receive_packet = mock_recv,
        .get_time_ns    = mock_time,
    };

    if (protocol_init(&mock) != 0) {
        fprintf(stderr, "Failed to initialize protocol\n");
        return 1;
    }

    /* Send a sample message (type 0x00) */
    protocol_send_message(&mock, 0x00);

    printf("\n[Done] Walking skeleton executed successfully.\n");
    return 0;
}
