# nts_noncegen

Nonce generator for the NTS engine.


## Status
Completed. Verified and implemented in target FPGA. Ready for integration.


## Introduction
The nonce generator provides the NTS engine with 64-bit data words used
as nonce for cookies.

The gnerator is based on the
[SipHash](https://en.wikipedia.org/wiki/SipHash) PRF processing random
messages structured similar to
[CMAC_KDF](https://csrc.nist.gov/publications/detail/sp/800-108/final)
in CTR mode.

The host writes 256 bit random context and 128 bit random key. The
context is combined with a 32 bit counter (which is initialized by the
32 LSB of the context) to generate 256 bit messages. SiphHash is then
used to create a 64 bit MAC for the message using the key.


## Client API protocol
The client is expected to look at ready. If ready is set the core is
prepared to generate new nonces and will accept a get_nonce command
signal. When a nonce has been generated, both ready and nonce_valid will
be set.

If the core has been disabled and then enabled via the API,
ready will be set, but nonce_valid will be cleared. This indicates that
the core is ready to accept a new get_nonce command, but that no nonce
has been generated.


The client sequence:
1. Wait for ready to be set.
2. Assert get_nonce.
3. Wait for ready to be set again.
4. If ready and nonce_valid is set nonce contains a valid nonce.
5. If ready is set, but not nonce_valid, no valid nonce is available. Go
   to step 2.


## Implementation results
Device: Virtex-7 (xc7vx690tffg1761-2)
Regs: 982
LUTs: 1240
Fmax: 222 MHz
