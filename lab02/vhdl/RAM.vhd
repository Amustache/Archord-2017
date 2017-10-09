library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    port(
        clk     : in  std_logic;
        cs      : in  std_logic;
        read    : in  std_logic;
        write   : in  std_logic;
        address : in  std_logic_vector(9 downto 0);
        wrdata  : in  std_logic_vector(31 downto 0);
        rddata  : out std_logic_vector(31 downto 0));
end RAM;

architecture synth of RAM is
	type ram_mem is array(1023 downto 0) of std_logic_vector(31 downto 0);
	signal ram : ram_mem;
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
	process(ram, r_addr, r_read)
	begin
		rddata <= (others => 'Z');
		if(r_read = '1') then
			rddata <= ram(to_integer(unsigned(r_addr)));
		end if;
	end process;
	
	-- Write memory and output wrdata
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(cs = '1' and write = '1') then
				ram(to_integer(unsigned(address))) <= wrdata;
			end if;
		end if;
	end process;
		
end synth;
