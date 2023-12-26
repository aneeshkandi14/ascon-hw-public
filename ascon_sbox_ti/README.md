# ASCON SBox Threshold

## Sharing
- TI order = 1 (3 shares)
    - `ti_1_sbox1` ... `ti_1_sbox5` satisfy non-completeness and uniformity; [`ti_1_sbox6`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/ti_1_sbox6.v) need not satisfy uniformity
- TI order = 2 (4 shares)
    - [`ti_2_sbox1`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/ti_2_sbox1.v) satisfies non-completeness and uniformity; [`ti_2_sbox2`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/ti_2_sbox2.v) need not satisfy uniformity

The above coordinate functions are generated using in-house functions [[1]](https://eprint.iacr.org/2023/633.pdf) in sage. 
Link for the [codes](https://github.com/anubhab001/sbox-threshold-public/tree/main/without-decomposition)

Note that, `ti_1_sbox3` sharing is used in the Ascon permutation implementation.

**Non-Completeness for sbox3:**

## Notes
- These coordinate functions are generated from the [codes](https://github.com/anubhab001/sbox-threshold-public/tree/main/without-decomposition) (see the [paper](https://eprint.iacr.org/2023/633.pdf)) in [Sage](https://www.sagemath.org/). 
- As per the [specification](https://ascon.iaik.tugraz.at/files/asconv12-nist.pdf) of the ASCON SBox, `x0` is the MSB bit and `x4` is the LSB bit; but it is the other way around in the in-built Sage functions.
