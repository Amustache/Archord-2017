library ieee;
use ieee.std_logic_1164.all;

entity comparator is
    port(
        a_31    : in  std_logic;
        b_31    : in  std_logic;
        diff_31 : in  std_logic;
        carry   : in  std_logic;
        zero    : in  std_logic;
        op      : in  std_logic_vector(2 downto 0);
        r       : out std_logic
    );
end comparator;

architecture synth of comparator is
begin
	with op select r <=
		(not(a(31)) and b(31)) or (not(expected(31)) and (not(a(31)) xor b(31))) when "001",
		(a(31) and not(b(31))) or (expected(31) and (not(a(31)) xor b(31))) when "010",
		not(zero)	 when "011",
		zero when "100",
		carry when "101",
		not(carry) when "110";
end synth;
