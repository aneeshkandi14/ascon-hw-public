**Contents:**
- TI order = 1 (3 shares)
    - [`sbox1`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox1.v) and [`sbox2`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox2.v) satisfy non-completeness and uniformity; [`sbox3`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox3.v) need not satisfy uniformity
- TI order = 2 (4 shares)
    - [`sbox4`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox4.v) satisfies non-completeness and uniformity; [`sbox5`](https://github.com/aneeshkandi14/ascon-hw-public/blob/main/ascon_sbox_ti/sbox1.v) need not satisfy uniformity

The above coordinate functions are generated using in-house functions [[1]](https://eprint.iacr.org/2023/633.pdf) in sage. 
Link for the [codes](https://github.com/anubhab001/sbox-threshold-public/tree/main/without-decomposition)

**Known Issues:**
- According to [[2]](https://ascon.iaik.tugraz.at/files/asconv12-nist.pdf), in ASCON SBox, `x0` is the MSB bit and `x4` is the LSB bit. The sage functions use `x4` as the MSB bit and `x0` as the LSB bit
