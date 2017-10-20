library ieee;
use ieee.std_logic_1164.all;

entity controller is
    port(
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        -- instruction opcode
        op         : in  std_logic_vector(5 downto 0);
        opx        : in  std_logic_vector(5 downto 0);
        -- activates branch condition
        branch_op  : out std_logic;
        -- immediate value sign extention
        imm_signed : out std_logic;
        -- instruction register enable
        ir_en      : out std_logic;
        -- PC control signals
        pc_add_imm : out std_logic;
        pc_en      : out std_logic;
        pc_sel_a   : out std_logic;
        pc_sel_imm : out std_logic;
        -- register file enable
        rf_wren    : out std_logic;
        -- multiplexers selections
        sel_addr   : out std_logic;
        sel_b      : out std_logic;
        sel_mem    : out std_logic;
        sel_pc     : out std_logic;
        sel_ra     : out std_logic;
        sel_rC     : out std_logic;
        -- write memory output
        read       : out std_logic;
        write      : out std_logic;
        -- alu op
        op_alu     : out std_logic_vector(5 downto 0)
    );
end controller;

architecture synth of controller is
	type state is (fetch1, fetch2, decode, r_op, store, break, load1, load2, i_op);
	signal currentState, nextState : state;
begin
	clk_rst : process(clk, reset_n, nextState)
	begin
		if(reset_n = '0') then -- Async reset
			currentState <= fetch1;
		elsif(rising_edge(clk)) then -- Clock
			currentState <= nextState;
		end if;
	end process;
	
	ctrl : process(currentState, op, opx) -- FSM
	begin
		branch_op  <= '0'; -- Basically reset all
		imm_signed <= '0';
		ir_en      <= '0';
		pc_add_imm <= '0';
		pc_en      <= '0';
		pc_sel_a   <= '0';
		pc_sel_imm <= '0';
		rf_wren    <= '0';
		sel_addr   <= '0';
		sel_b      <= '0';
		sel_mem    <= '0';
		sel_pc     <= '0';
		sel_ra     <= '0';
		sel_rC     <= '0';
		read       <= '0';
		write      <= '0';
		
		case currentState is
			when fetch1	=> -- First cycle, read is set
				read 			<= '1'; -- Start a read process
				nextState	<= fetch2;
			
			when fetch2 => -- Second cycle, instr is read and saved, next instruction set in PC
				pc_en			<= '1'; -- Enable PC
				ir_en			<= '1'; -- Enable IR
				nextState		<= decode;
			
			when decode	=> -- Third cycle, read opcode
				case ("00" & op) is
					when X"04" => -- I_OP instructions, can have more than one
						nextState <= i_op;
					when X"3A" => 
						if(("00" & opx) = X"34") then
							nextState <= break; -- BREAK instruction
						else
							nextState <= r_op; -- R_OP instruction
						end if;
					when X"17" => -- LOAD instruction
						nextState <= load1;
					when X"15" => -- STORE instruction
						nextState <= store;
					when others => -- Invalid
						nextState <= fetch1;
				end case;
			
			when i_op	=> -- Fourth instruction, I_OP
				rf_wren		<= '1'; -- Register File write enable
				imm_signed	<= '1'; -- Signed value
				
				case ("00" & opx) is
					when X"04" => -- addi rB, rA, imm	: rB <- rA + (s)imm
						-- ???
					when others => -- Invalid
						-- /
				end case;
				
				nextState		<= fetch1;
			
			when r_op	=> -- Fourth instruction, R_OP
				rf_wren		<= '1'; -- Register File write enable
				sel_b			<= '1'; -- Register File 'b' or immediate value selected
				sel_rC		<= '1'; -- Write address (aw) selected
				
				case ("00" & opx) is
					when X"0E" => -- and rC, rA, rB		: rC <- rA AND rB
						-- ???
					when X"1B" => -- srl rC, rA, rB		: rC <- (u)rA>>rB(4..0)
						imm_signed	<= '0'; -- Unsigned value
					when others => -- Invalid
						-- /
				end case;
				
				nextState		<= fetch1;
			
			when load1	=> -- Fourth instruction, first part of load
				sel_addr		<= '1'; -- From ALU
				sel_b			<= '0'; -- From Extend
				read			<= '1'; -- Start a read process
				imm_signed	<= '1'; -- Signed value
				nextState		<= load2;
			
			when load2	=> -- Fifth instruction, second part of load
				rf_wren		<= '1'; -- Register File write enable
				sel_mem		<= '1'; -- Write data from rddata
				sel_rC		<= '0'; -- Get data from IR
				nextState		<= fetch1;
			
			when store	=>
				sel_addr		<= '1'; -- Select data from ALU
				sel_b			<= '0'; -- Select data from Extend
				write			<= '1'; -- Start a write process
				imm_signed	<= '1'; -- Signed value
				nextState		<= fetch1;
			
			when break	=> -- Fourth instruction, dead end
				nextState		<= break;
			
			when others	=> -- Invalid
				nextState		<= fetch1;
		end case;
	end process;
	
	opaluctrl : process(op, opx) -- Separate process for op_alu (and imm_signed?)
	-- 000xxx	+
	-- 001xxx	-
	
	-- 001001	>=s
	-- 001010	<s
	-- 001011	/=
	-- 001100	=
	-- 001101	>=u
	-- 001110	<u
	
	-- 10xx00	nor
	-- 10xx01	and
	-- 10xx10	or
	-- 10xx11	xor
	
	-- 11x000	rol
	-- 11x001	ror
	-- 11x010	sll
	-- 11x011	srl
	-- 11x111	sra
	begin
		op_alu     <= (others => 'X');
		
		case ("00" & op) is
			-- R_OP
			when X"3A" =>
				case ("00" & opx) is
					when X"0E" => -- and rC, rA, rB		: rC <- rA AND rB
						op_alu <= "10XX01";
					when X"1B" => -- srl rC, rA, rB		: rC <- (u)rA>>rB(4..0)
						op_alu <= "11X011";
					when X"34" => -- break					: (unused)
						op_alu <= "XXXXXX";
					when others => -- Invalid
						op_alu <= "XXXXXX";
				end case;
			-- I_OP
			when X"04" =>			-- addi rB, rA, imm	: rB <- rA + (s)imm
				op_alu <= "000XXX";
			when X"17" =>			-- ldw rB, imm(rA)	: rB <- Mem[rA + (s)imm]
				op_alu <= "000XXX";
			when X"15" =>			-- stw rB, imm(rA)	: Mem[rA + (s)imm] <- rB
				op_alu <= "000XXX";
			when others =>			-- Invalid
				op_alu <= "XXXXXX";
		end case;
	end process;
end synth;
