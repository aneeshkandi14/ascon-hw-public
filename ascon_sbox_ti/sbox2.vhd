library ieee;
use ieee.std_logic_1164.all;

entity ascon_sbox_ti is port(
	A00, A01, A02, A10, A11, A12, A20, A21, A22, A30, A31, A32, A40, A41, A42 : in  std_ulogic;
	Y00, Y01, Y02, Y10, Y11, Y12, Y20, Y21, Y22, Y30, Y31, Y32, Y40, Y41, Y42 : out std_ulogic
);
end entity;

architecture ti of ascon_sbox_ti is
begin

    Y00 <= (A01 and A30) xor (A01 and A31) xor (A01 and A32) xor A01 xor (A02 and A30) xor (A02 and A31) xor (A02 and A32) xor A02 xor A11 xor A12 xor (A30 and A40) xor (A30 and A41) xor (A30 and A42) xor A30 xor (A31 and A40) xor (A31 and A41) xor (A31 and A42) xor A31 xor (A32 and A40) xor (A32 and A41) xor (A32 and A42) xor A32;    
    Y01 <= (A00 and A30) xor (A00 and A31) xor (A00 and A32) xor A00;
    Y02 <= A10;
    
    Y10 <= (A01 and A40) xor (A01 and A41) xor (A01 and A42) xor A01 xor (A02 and A40) xor (A02 and A41) xor (A02 and A42) xor A02 xor (A11 and A40) xor (A11 and A41) xor (A11 and A42) xor A11 xor (A12 and A40) xor (A12 and A41) xor (A12 and A42) xor A12 xor A21 xor A22 xor A30 xor A31 xor A32 xor A40 xor A41 xor A42;
    Y11 <= (A00 and A40) xor (A00 and A41) xor (A00 and A42) xor A00 xor (A10 and A40) xor (A10 and A41) xor (A10 and A42) xor A10;
    Y12 <= A20;
    
    Y20 <= (A01 and A11) xor (A01 and A12) xor A01 xor (A02 and A11) xor (A02 and A12) xor A02 xor A21 xor A22 xor A30 xor A31 xor A32 xor '1';
    Y21 <= (A00 and A10) xor (A00 and A12) xor A00 xor (A02 and A10) xor A20;
    Y22 <= (A00 and A11) xor (A01 and A10);

    Y30 <= A01 xor A02 xor (A11 and A21) xor (A11 and A22) xor (A11 and A30) xor (A11 and A31) xor (A11 and A32) xor A11 xor (A12 and A21) xor (A12 and A22) xor (A12 and A30) xor (A12 and A31) xor (A12 and A32) xor A12 xor (A21 and A30) xor (A21 and A31) xor (A21 and A32) xor A21 xor (A22 and A30) xor (A22 and A31) xor (A22 and A32) xor A22 xor A30 xor A31 xor A32 xor A40 xor A41 xor A42;
    Y31 <= A00 xor (A10 and A20) xor (A10 and A22) xor (A10 and A30) xor (A10 and A31) xor (A10 and A32) xor A10 xor (A12 and A20) xor (A20 and A30) xor (A20 and A31) xor (A20 and A32) xor A20;
    Y32 <= (A10 and A21) xor (A11 and A20);

    Y40 <= (A01 and A30) xor (A01 and A31) xor (A01 and A32) xor (A02 and A30) xor (A02 and A31) xor (A02 and A32) xor A11 xor A12 xor (A21 and A30) xor (A21 and A31) xor (A21 and A32) xor A21 xor (A22 and A30) xor (A22 and A31) xor (A22 and A32) xor A22 xor (A30 and A40) xor (A30 and A41) xor (A30 and A42) xor A30 xor (A31 and A40) xor (A31 and A41) xor (A31 and A42) xor A31 xor (A32 and A40) xor (A32 and A41) xor (A32 and A42) xor A32 xor A40 xor A41 xor A42;
    Y41 <= (A00 and A30) xor (A00 and A31) xor (A00 and A32) xor A10 xor (A20 and A30) xor (A20 and A31) xor (A20 and A32);
    Y42 <= A20;

end architecture;
