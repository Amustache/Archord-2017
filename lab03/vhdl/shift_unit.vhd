library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_unit is
    port(
        a  : in  std_logic_vector(31 downto 0);
        b  : in  std_logic_vector(4 downto 0);
        op : in  std_logic_vector(2 downto 0);
        r  : out std_logic_vector(31 downto 0)
    );
end shift_unit;

architecture synth of shift_unit is
    signal rr, sl, ss : std_logic_vector(31 downto 0);
begin
    with op select r <=
        rr when "000",
		  rr when "001", -- rol, ror
        sl when "010", -- sll
        ss when "011",
		  ss when "111", -- srl, sra
        rr when others; -- error
    
	rol_ror : process(a, b, op) -- rotate left, rotate right
        variable v   : std_logic_vector(31 downto 0);
        variable bis : std_logic_vector(4 downto 0); -- a rol b === a ror (-b)
    begin
        v   := a;
        bis := std_logic_vector(signed(b xor (4 downto 0 => op(0))));
		  if(op(0) = '1') then
				bis := std_logic_vector(signed(bis) + 1); -- Yeah that's ugly af but welp it works at least.
		  end if;

        for i in 0 to 4 loop
            if(bis(i) = '1') then
                v := v(31 - (2 ** i) downto 0) & v(31 downto 32 - (2 ** i));
            end if;
        end loop;
        rr <= v;
    end process;
    
    sll_x : process(a, b, op) -- shift left logical
        variable v : std_logic_vector(31 downto 0);
    begin
        v := a;
        for i in 0 to 4 loop
            if(b(i) = '1') then
                v := v(31 - (2 ** i) downto 0) & ((2 ** i) - 1 downto 0 => '0');
            end if;
        end loop;
        sl <= v;
    end process;
    
    srl_sra : process(a, b, op) -- shift right logical, shift right arithmetic
        variable v   : std_logic_vector(31 downto 0);
        variable sign : std_logic; -- if op(2) = '1' then arithmetic else logical
    begin
        v    := a;
        sign := op(2) and a(31);
        for i in 0 to 4 loop
            if(b(i) = '1') then
                v := ((2**i)-1 downto 0 => sign) & v(31 downto 2**i);
            end if;
        end loop;
        ss <= v;
    end process;
    
end synth;
