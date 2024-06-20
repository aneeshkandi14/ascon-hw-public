# ASCON SBox Threshold

## Sharing
- TI order = 1 (3 shares)
    - [`ti_1_sbox1`](./ti_1_sbox1.v), [`ti_1_sbox2`](./ti_1_sbox2.v), [`ti_1_sbox3`](./ti_1_sbox3.v), [`ti_1_sbox4`](./ti_1_sbox4.v), [`ti_1_sbox5`](./ti_1_sbox5.v) satisfy non-completeness and uniformity; [`ti_1_sbox6`](./ti_1_sbox6.v) may not satisfy uniformity
- TI order = 2 (4 shares)
    - [`ti_2_sbox1`](./ti_2_sbox1.v) satisfies non-completeness and uniformity; [`ti_2_sbox2`](./ti_2_sbox2.v) may not satisfy uniformity

## Notes
- [`ti_1_sbox3`](./ti_1_sbox3.v) sharing is used in the Ascon permutation implementation.
- These coordinate functions are generated from the [codes](https://github.com/anubhab001/sbox-threshold-public/tree/main/without-decomposition) (see the [paper](https://eprint.iacr.org/2023/633.pdf)) in [Sage](https://www.sagemath.org/). 
- As per the [specification](https://ascon.iaik.tugraz.at/files/asconv12-nist.pdf) of the ASCON SBox, `x0` is the MSB bit and `x4` is the LSB bit; but it is the other way around in the in-built Sage functions.

## Non-Completeness for `ti_1_sbox3`
The condition for a coordinate function to satisfy "non-completeness" is that atleast one variable from `{xi_0, xi_1, xi_2}` is missing in each of `yj_0, yj_1, yj_2` for all `i,j = {0,1,2,3,4}`. For instance,
```python
y0_0 = x4_0*x1_2 + x4_2*x1_0 + x4_2*x1_2 + x3_2 + x2_0*x1_2 + x2_0 + x2_2*x1_0 + x2_2*x1_2 + x2_2 + x1_0*x0_0 + x1_0*x0_2 + x1_0 + x1_2*x0_0 + x1_2
```
One can note that all `xi_1` variables are missing in `y0_0` thereby satisfying non-completeness. A similar conclusion can be made for all the coordinate functions `yi_j` where `i,j={0...4}`.

**Missing variables in each of the coordinate functions:**
```python
y0_0: {x0_1, x1_1, x2_1, x3_1, x3_0, x4_1}
y0_1: {x0_2, x1_2, x2_2, x3_1, x3_2, x4_2}
y0_2: {x0_0, x1_0, x2_0, x3_0, x3_2, x4_0}

y1_0: {x0_2, x0_1, x0_0, x1_0, x2_0, x3_0, x4_1, x4_0}
y1_1: {x0_2, x1_2, x2_2, x3_2, x4_0, x4_2}
y1_2: {x0_0, x0_1, x1_1, x2_1, x3_1, x4_1, x4_2}

y2_0: {x0_2, x0_1, x0_0, x1_1, x1_0, x2_1, x2_0, x3_1, x4_1}
y2_1: {x0_2, x0_1, x0_0, x1_2, x1_0, x2_2, x2_0, x3_0, x4_0}
y2_2: {x0_2, x0_1, x0_0, x1_2, x1_1, x2_1, x2_2, x3_2, x4_2}

y3_0: {x0_2, x1_2, x1_0, x2_2, x2_0, x3_2, x4_2}
y3_1: {x0_1, x1_2, x1_1, x2_1, x3_1, x4_1}
y3_2: {x0_0, x1_1, x1_0, x2_1, x2_2, x2_0, x3_0, x4_0}

y4_0: {x0_1, x1_1, x2_1, x2_2, x2_0, x3_1, x3_0, x4_1}
y4_1: {x0_0, x1_0, x2_1, x2_2, x2_0, x3_0, x3_2, x4_0}
y4_2: {x0_2, x1_2, x2_1, x2_2, x2_0, x3_1, x3_2, x4_2}
```
