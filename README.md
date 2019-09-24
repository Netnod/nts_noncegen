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
context is combined with a 32 bit coubter (which is initialized by the
32 LSB of the context) to generate 256 bit messages. SiphHash is then
used to create a 64 bit MAC for the message using the key.


## Implementation results
Device: Virtex-7 (xc7vx690tffg1761-2)
Regs: 982
LUTs: 1240
Fmax: 222 MHz
