library ieee;
use ieee.std_logic_1164.all;

entity decoder is
    port(
        address : in  std_logic_vector(15 downto 0);
        cs_LEDS : out std_logic;
        cs_RAM  : out std_logic;
        cs_ROM  : out std_logic
    );
end decoder;

architecture synth of decoder is
begin
	process(address)
	begin
		cs_ROM <= '0';
		cs_RAM <= '0';
		cs_LEDS <= '0';
		
		if(to_integer(unsigned(address)) >= x"0000" and to_integer(unsigned(address)) <= x"0FFC") then
			cs_ROM <= '1';
			cs_RAM <= '0';
			cs_LEDS <= '0';
		end if;
		
		if(to_integer(unsigned(address)) >= x"1000" and to_integer(unsigned(address)) <= x"1FFC") then
			cs_ROM <= '0';
			cs_RAM <= '1';
			cs_LEDS <= '0';
		end if;
		
		if(to_integer(unsigned(address)) >= x"2000" and to_integer(unsigned(address)) <= x"200C") then
			cs_ROM <= '0';
			cs_RAM <= '0';
			cs_LEDS <= '1';
		end if;
	end process;
end synth;
