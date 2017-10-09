library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        rddata  : out std_logic_vector(31 downto 0)
    );
end ROM;

architecture synth of ROM is
	type rom_mem is array(1023 downto 0) of std_logic_vector(31 downto 0);
	signal rom : rom_mem;
	signal r_addr : std_logic_vector(9 downto 0);
	signal r_read : std_logic;
	
begin

	-- the registered adress selects the corresponding line in the memory
	process(clk)
	begin
		if (rising_edge(clk)) then
			r_addr <= address;
			r_read <= cs and read;
		end if;
	end process;
	
	-- Read memory and output rddata
	process(rom, r_addr, r_read)
	begin
		rddata <= (others => 'Z');
		if (r_read = '1') then
			rddata <= rom(to_integer(unsigned(r_addr)));
		end if;
	end process;
	
end synth;
