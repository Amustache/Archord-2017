library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
    port(
        clk     : in  std_logic;
        reset_n : in  std_logic;
        en      : in  std_logic;
        sel_a   : in  std_logic;
        sel_imm : in  std_logic;
        add_imm : in  std_logic;
        imm     : in  std_logic_vector(15 downto 0);
        a       : in  std_logic_vector(15 downto 0);
        addr    : out std_logic_vector(31 downto 0)
    );
end PC;

architecture synth of PC is
	-- Data array
	signal current : std_logic_vector(31 downto 0);
begin
	process(clk, reset_n)
	begin
		if(reset_n = '0') then -- Sync reset
				current <= (others => '0');
		elsif(rising_edge(clk)) then -- Clock
			if(en = '1') then -- Next addr
				if(sel_a = '1') then
					current <= (31 downto 16 => '0') & a;
				elsif(sel_imm = '1') then
					current <= (31 downto 16 => '0') & std_logic_vector(
						shift_left(signed(imm), 2));
				elsif(add_imm = '1') then
					current <= std_logic_vector(signed(current) + signed(imm));
				else
					current <= std_logic_vector(unsigned(current) + 4);
				end if;
			end if;
		end if;
	end process;
	
	addr <= ((31 downto 16 => '0') & current(15 downto 0)) and
		((31 downto 2 => '1') & "00");
end synth;
