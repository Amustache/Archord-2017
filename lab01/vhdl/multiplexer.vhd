library ieee;
use ieee.std_logic_1164.all;

entity multiplexer is
    port(
        i0  : in  std_logic_vector(31 downto 0);
        i1  : in  std_logic_vector(31 downto 0);
        i2  : in  std_logic_vector(31 downto 0);
        i3  : in  std_logic_vector(31 downto 0);
        sel : in  std_logic_vector(1 downto 0);
        o   : out std_logic_vector(31 downto 0)
    );
end multiplexer;

architecture synth of multiplexer is
begin
	with sel select o <=
		i0 when "00", -- add/sub
		i1 when "01", -- comparator
		i2 when "10", -- logical unit
		i3 when "11", -- shift/rotate unit
		i0 when others; -- Undefined
end synth;
