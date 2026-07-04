# Architecture Quality Attribute Scenarios

ISO/IEC/IEEE 42010:2011 quality attribute scenarios for the IEEE 802.1X-2020
wpa_supplicant extension. Each scenario follows the form
**Source → Stimulus → Artifact → Environment → Response → Measure** and traces
to the requirements (GitHub Issues) it constrains.

These scenarios are the architecture-level quality attributes. Per-requirement
acceptance scenarios (Gherkin) live in the individual requirement issue bodies.

## Performance

### QA-SC-PERF-001: MKA Convergence After Topology Change
- **Source**: Network event (peer join/leave or key-server loss)
- **Stimulus**: A new participant joins or the key server leaves the live peer set
- **Artifact**: MKA Key Agreement entity (KaY), `src/pae/ieee802_1x_kay.c`
- **Environment**: Normal operation, IEEE 802.1X-2020 Clause 9
- **Response**: KaY elects/re-elects the key server and distributes a new SAK
- **Measure**: Controlled Port reaches SECURED within 100 ms (p99) of the event
- **Traces to**: #2 (StR-002), #13 (REQ-F-MKA-001), #15 (REQ-F-MKA-003), #18 (REQ-NF-MKA-001), #10 (REQ-NF-PERF-001)

### QA-SC-PERF-002: Supplicant PACP Authentication Latency
- **Source**: Port enable
- **Stimulus**: `portEnabled` becomes TRUE
- **Artifact**: Supplicant PACP state machine, `src/eapol_supp/eapol_supp_sm.c`
- **Environment**: 802.1X-2020 Clause 8.7
- **Response**: PACP transitions DISCONNECTED → CONNECTING → AUTHENTICATING → AUTHENTICATED
- **Measure**: Transitions complete without spurious retries; `heldWhile` honors Clause 8.7 timers
- **Traces to**: #5 (REQ-F-PAE-001), #6 (REQ-F-PAE-002), #7 (REQ-F-PAE-003), #8 (REQ-F-PAE-004), #10 (REQ-NF-PERF-001)

### QA-SC-PERF-003: Logon Process NID Selection Determinism
- **Source**: Network announcement / NID advertisement
- **Stimulus**: One or more NIDs become available
- **Artifact**: Logon Process state machine, `src/pae/ieee802_1x_logon.c`
- **Environment**: 802.1X-2020 Clause 12
- **Response**: Logon Process selects the target NID per network policy and drives PACP/KaY accordingly
- **Measure**: Selection is deterministic for a given NID set and policy; no flapping between NIDs
- **Traces to**: #19 (REQ-F-LOGON-001), #20 (REQ-F-LOGON-002), #21 (REQ-F-LOGON-003), #22 (REQ-F-LOGON-004), #50 (REQ-F-NID-001)

## Availability

### QA-SC-AVAIL-001: Continued Service During Re-authentication
- **Source**: Authenticator
- **Stimulus**: Re-authentication request while data is flowing
- **Artifact**: Controlled Port + KaY
- **Environment**: 802.1X-2020 Clause 9/12
- **Response**: SAK rotation / re-auth completes without dropping authorized traffic beyond the spec-allowed interval
- **Measure**: Zero unplanned data-plane interruptions; Controlled Port does not drop to UNAUTHENTICATED during re-key
- **Traces to**: #2 (StR-002), #16 (REQ-F-MKA-004), #17 (REQ-F-MKA-005), #22 (REQ-F-LOGON-004), #48 (REQ-F-CP-001)

### QA-SC-AVAIL-002: Graceful Handling of Peer Loss
- **Source**: Live peer set
- **Stimulus**: A peer becomes unreachable (CAK liveness timeout)
- **Artifact**: KaY
- **Environment**: 802.1X-2020 Clause 9.4
- **Response**: Participant is removed cleanly; SAK continuity preserved for remaining participants
- **Measure**: No orphaned SAs; remaining participants retain secure connectivity
- **Traces to**: #14 (REQ-F-MKA-002), #16 (REQ-F-MKA-004)

## Security

### QA-SC-SEC-001: Key Material Never Exposed
- **Source**: Developer / tooling
- **Stimulus**: Inspection of logs, core dumps, or memory dumps
- **Artifact**: Crypto primitives, KaY, TLS
- **Environment**: All build configurations
- **Response**: CAK/SAK and derived keys are never written to logs or persistent storage in plaintext
- **Measure**: Zero occurrences of key material in `wpa_printf` output or crash artifacts
- **Traces to**: #2 (StR-002), #13 (REQ-F-MKA-001), #9 (REQ-F-PAE-005), #17 (REQ-F-MKA-005), #18 (REQ-NF-MKA-001)

### QA-SC-SEC-002: Cryptographic Correctness of Key Hierarchy
- **Source**: Protocol peer
- **Stimulus**: SAK/CAK derivation and distribution exchange
- **Artifact**: MKA key hierarchy
- **Environment**: 802.1X-2020 Clause 9.3
- **Response**: Derived keys match the spec-defined KDF at every hop; replayed or tampered MKPDUs are rejected
- **Measure**: 100% conformance with Clause 9.3 derivation; rejection on any ICV mismatch
- **Traces to**: #13 (REQ-F-MKA-001), #14 (REQ-F-MKA-002), #18 (REQ-NF-MKA-001)

## Testability

### QA-SC-TEST-001: State Machines Unit-Testable Without Hardware
- **Source**: Developer
- **Stimulus**: Run the PAE test suite
- **Artifact**: All state machines (PACP, KaY, CP, Logon)
- **Environment**: Host build, no network hardware
- **Response**: State machines are exercised via injected mock function tables and in-memory l2_packet
- **Measure**: ≥80% line coverage; all Clause-conformance TEST cases pass without hardware
- **Traces to**: #11 (REQ-NF-TEST-001), #19 (REQ-F-LOGON-001), #20 (REQ-F-LOGON-002), #21 (REQ-F-LOGON-003), #23 (REQ-NF-LOGON-001), #31 (StR-009), #26 (REQ-NF-COMPAT-003)

## Modifiability

### QA-SC-MOD-001: Add a New EAP Method Without Touching PAE Core
- **Source**: Developer
- **Stimulus**: Add support for a new EAP method
- **Artifact**: EAP peer layer, `src/eap_peer/`
- **Environment**: Build with `CONFIG_IEEE8021X_EAPOL=y`
- **Response**: A new method is added via the existing EAP method registration mechanism
- **Measure**: No edits to PACP/KaY/Logon core; method compiles and registers independently
- **Traces to**: #9 (REQ-F-PAE-005), #28 (StR-005), #47 (REQ-F-EAP-001)

### QA-SC-MOD-002: Toggle 2020 Features at Compile Time
- **Source**: Integrator
- **Stimulus**: Enable/disable `CONFIG_IEEE8021X_2020` and sub-flags
- **Artifact**: Build system
- **Environment**: Any platform
- **Response**: Build succeeds and produces a binary with/without 2020 features
- **Measure**: Non-opt-in build is behaviorally equivalent to baseline wpa_supplicant
- **Traces to**: #24 (REQ-NF-COMPAT-001), #25 (REQ-NF-COMPAT-002), #4 (StR-008)

## Interoperability

### QA-SC-IO-001: Interoperate With 2010-Era Authenticator
- **Source**: Legacy authenticator
- **Stimulus**: Standard MKA/EAPOL exchange
- **Artifact**: KaY, PACP
- **Environment**: 802.1X-2010 peer
- **Response**: Falls back to 2010-compatible behavior when 2020 features are not negotiated
- **Measure**: Successful MACsec session established with a 2010-only peer
- **Traces to**: #4 (StR-008), #12 (REQ-NF-PAE-COMPAT-001), #24 (REQ-NF-COMPAT-001)
