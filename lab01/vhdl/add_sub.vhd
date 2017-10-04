library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is
    port(
        a        : in  std_logic_vector(31 downto 0);
        b        : in  std_logic_vector(31 downto 0);
        sub_mode : in  std_logic;
        carry    : out std_logic;
        zero     : out std_logic;
        r        : out std_logic_vector(31 downto 0)
    );
end add_sub;

architecture synth of add_sub is
	signal r_out : std_logic_vector(32 downto 0);
	constant zeros : std_logic_vector(r_out'range) := (others => '0');
begin
	process(a, b, sub_mode)
	begin
		if(sub_mode = '0') then
			r_out <= '0' & std_logic_vector(signed(a) + signed(b));
		else
			r_out <= '0' & std_logic_vector(signed(a) - signed(b));
		end if;
		
		r <= r_out(31 downto 0);
		carry <= r_out(32);
		
		if(r_out(31 downto 0) = zeros) then
			zero <= '1';
		else
			zero <= '0';
		end if;
	end process;
end synth;
