library ieee;
use ieee.std_logic_1164.all;

entity decoder is
    port(
        address     : in  std_logic_vector(15 downto 0);
        cs_LEDS     : out std_logic;
        cs_RAM      : out std_logic;
        cs_ROM      : out std_logic;
        cs_buttons  : out std_logic
    );
end decoder;

architecture synth of decoder is
begin

	-- select the signal depending on the adress
	process(address)
	begin
		cs_LEDS     <= '0';
		cs_RAM      <= '0';
		cs_ROM      <= '0';
        cs_buttons  <= '0';
        
		if (address < X"1000") then
			cs_ROM <= '1';
		end if;
        
		if (address >= X"1000" and address < X"2000") then
			cs_RAM <= '1';
		end if;
        
		if (address >= X"2000" and address < X"2010") then
			cs_LEDS <= '1';
		end if;
        
		if (address >= X"2030" and address < X"2034") then
			cs_buttons <= '1';
		end if;
	end process;
		
end synth;
