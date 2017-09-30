library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port(
        clk    : in  std_logic;
        aa     : in  std_logic_vector(4 downto 0);
        ab     : in  std_logic_vector(4 downto 0);
        aw     : in  std_logic_vector(4 downto 0);
        wren   : in  std_logic;
        wrdata : in  std_logic_vector(31 downto 0);
        a      : out std_logic_vector(31 downto 0);
        b      : out std_logic_vector(31 downto 0)
    );
end register_file;

architecture synth of register_file is
	-- Data array
	type reg_type is array(0 to 31) of std_logic_vector(31 downto 0);
	signal reg : reg_type;
	
	-- Data output
	signal a_out : std_logic_vector(31 downto 0);
	signal b_out : std_logic_vector(31 downto 0);
	
begin
	-- Read (aa)
	process(aa)
	begin
		if(aa = "00000") then
			a_out <= (others => '0');
		else
			a_out <= reg(to_integer(unsigned(aa)));
		end if;
	end process;
	
	-- Output (a)
	a <= a_out;
	
	-- Read (ab)
	process(ab)
	begin
		if(ab = "00000") then
			b_out <= (others => '0');
		else
			b_out <= reg(to_integer(unsigned(ab)));
		end if;
	end process;
	
	-- Output (b)
	b <= b_out;
	
	-- Write (aw)
	process(clk, aw, wren, wrdata)
	begin
		if(rising_edge(clk)) then
			if(wren = '1') then
				if(aw /= "00000") then
					reg(to_integer(unsigned(aw))) <= wrdata;
				end if;
			end if;
		end if;
	end process;
end synth;
