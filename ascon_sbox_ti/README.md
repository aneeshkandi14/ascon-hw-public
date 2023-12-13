# ASCON SBox Threshold

## Sharing
- TI order = 1 (3 shares)
    - [`sbox1`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox1.v) and [`sbox2`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox2.v) satisfy non-completeness and uniformity; [`sbox3`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox3.v) may not satisfy uniformity
- TI order = 2 (4 shares)
    - [`sbox4`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox4.v) satisfies non-completeness and uniformity; [`sbox5`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox1.v) may not satisfy uniformity


## Notes
- These coordinate functions are generated from the [codes](https://github.com/anubhab001/sbox-threshold-public/tree/main/without-decomposition) (see the [paper](https://eprint.iacr.org/2023/633.pdf)) in [Sage](https://www.sagemath.org/). 
- As per the [specification](https://ascon.iaik.tugraz.at/files/asconv12-nist.pdf) of the ASCON SBox, `x0` is the MSB bit and `x4` is the LSB bit; but the in-built Sage functions the other way around.
