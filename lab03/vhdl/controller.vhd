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
        -- immediate value sign eXtention
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
        -- multipleXers selections
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
	type state is (fetch1, fetch2, decode, r_op, store, break, load1, load2,
		i_op, branch, call, jmp, ri_op, ui_op);
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
		branch_op	<= '0'; -- Basically reset all
		imm_signed	<= '0'; -- Later I will explicitly write when we are using a
		ir_en			<= '0'; -- '0' bit on these outputs, but it is not necessary 
		pc_add_imm	<= '0'; -- as everything is set to '0' here. However I find 
		pc_en			<= '0'; -- it useful to quickly notice what we are talking a-
		pc_sel_a		<= '0'; -- bout
		pc_sel_imm	<= '0';
		rf_wren		<= '0';
		sel_addr		<= '0';
		sel_b			<= '0';
		sel_mem		<= '0';
		sel_pc		<= '0';
		sel_ra		<= '0';
		sel_rC		<= '0';
		read			<= '0';
		write			<= '0';
		nextState	<= fetch1;
		
		case currentState is
			when fetch1	=> -- First cycle, read is set
				read 			<= '1'; -- Start a read process
				nextState	<= fetch2;
			
			when fetch2 => -- Second cycle, instr is read and saved,
								-- neXt instruction set in PC
				pc_en			<= '1'; -- Enable PC
				ir_en			<= '1'; -- Enable IR
				nextState		<= decode;
			
			when decode	=> -- Third cycle, read opcode
				case ("00" & op) is
					-- R-type instruction format
					when X"3A"   =>
						case ("00" & opx) is
							when X"34"  => -- BREAK instruction
								nextState <= break;
							when X"0D"
								| X"05"  => -- JMP instruction
								nextState <= jmp;
							when X"1D"	=> -- CALL instruction
								nextState <= call;
							when X"12"
								| X"1A"
								| X"3A"
								| X"02"  => -- Immediate R_OP instruction
								nextState <= ri_op;
							when others => -- R_OP instruction
								nextState <= r_op;
						end case;
					-- I-type instruction format
					when X"17"  => -- LOAD instruction
						nextState <= load1;
					when X"15"  => -- STORE instruction
						nextState <= store;
					when X"06"
						| X"0E"
						| X"16"
						| X"1E"
						| X"26"
						| X"2E"
						| X"36"	=> -- BRANCH instruction
						nextState <= branch;
					when X"00"	=> -- CALL instruction
						nextState <= call;
					when X"01"	=> -- JUMP instruction
						nextState <= jmp;
					when X"04"
						| X"08"
						| X"10"
						| X"18"
						| X"20"  => -- I_OP instruction
						nextState <= i_op;
					when X"28"
						| X"30"
						| X"0C"
						| X"14"
						| X"1C"  => -- Unsigned I_OP instruction
						nextState <= ui_op;
					when others => -- Invalid
				end case;
			
			when i_op	=> -- Fourth cycle, I_OP
				rf_wren		<= '1'; -- Register File write enable
				imm_signed	<= '1'; -- Signed value
				
			when ui_op	=> -- Fourth cycle, UI_OP
				rf_wren		<= '1'; -- Register File write enable
				imm_signed	<= '0'; -- Unsigned value
			
			when r_op	=> -- Fourth cycle, R_OP
				rf_wren		<= '1'; -- Register File write enable
				sel_b			<= '1'; -- Register File 'b' selected
				sel_rC		<= '1'; -- Write address (aw) selected
				
			when ri_op	=> -- Fourth cycle, RI_OP
				rf_wren		<= '1'; -- Register File write enable
				sel_b			<= '0'; -- Immediate value selected
				sel_rC		<= '1'; -- Write address (aw) selected
			
			when load1	=> -- Fourth cycle, first part of load
				sel_addr		<= '1'; -- From ALU
				sel_b			<= '0'; -- From EXtend
				read			<= '1'; -- Start a read process
				imm_signed	<= '1'; -- Signed value
				nextState		<= load2;
			
			when load2	=> -- Fifth cycle, second part of load
				rf_wren		<= '1'; -- Register File write enable
				sel_mem		<= '1'; -- Write data from rddata
				sel_rC		<= '0'; -- Get data from IR
			
			when store	=>
				sel_addr		<= '1'; -- Select data from ALU
				sel_b			<= '0'; -- Select data from EXtend
				write			<= '1'; -- Start a write process
				imm_signed	<= '1'; -- Signed value
			
			when break	=> -- Fourth cycle, dead end
				nextState		<= break;
				
			when branch	=> -- Fourth cycle, BRANCH
				branch_op	<= '1'; -- Branch operation
				sel_b			<= '1'; -- Select data from Register File
				pc_add_imm	<= '1'; -- PC add imm and not 4
			
			when call	=> -- Fourth cycle, CALL
				rf_wren		<= '1'; -- Register File write enable
				sel_mem		<= '0'; -- Write data from PC
				pc_en			<= '1'; -- Next address in PC
				sel_pc		<= '1'; -- Is probably useful
				sel_ra		<= '1'; -- Select data from ra register
				sel_rC		<= '0'; -- Select data from ra register
				
				-- Handle of CALLR, because dammit
				if(("00" & op) = X"3A" and ("00" & opx) = X"1D") then
					pc_sel_imm	<= '0'; -- 4 and not PC add imm
					pc_sel_a	<= '1'; -- PC add value from a
				else
					pc_sel_imm	<= '1'; -- PC add imm and not 4
					pc_sel_a	<= '0'; -- PC no add value from a
				end if;
			
			when jmp		=> -- Fourth cycle, JMP
				pc_en			<= '1'; -- Next address in PC
				
				-- Handle of JMPI, because dammit
				if(("00" & op) = X"01") then
					pc_sel_imm	<= '1'; -- PC add imm and not 4
					pc_sel_a	<= '0'; -- PC no add value from a
				else
					pc_sel_imm	<= '0'; -- 4 and not PC add imm
					pc_sel_a	<= '1'; -- PC add value from a
				end if;
			
			when others	=> -- Invalid
		end case;
	end process;
	
	opaluctrl : process(op, opx) -- Separate process for op_alu (and imm_signed?)
	-- 000XXX	+
	-- 001XXX	-
	
	-- 011001	>=s
	-- 011010	<s
	-- 011011	/=
	-- 011100	=
	-- 011101	>=u
	-- 011110	<u
	
	-- 10XX00	nor
	-- 10XX01	and
	-- 10XX10	or
	-- 10XX11	xor
	
	-- 11X000	rol
	-- 11X001	ror
	-- 11X010	sll
	-- 11X011	srl
	-- 11X111	sra
	begin
		op_alu <= (others => 'X');
		
		case ("00" & op) is
			-- R_OP
			when X"3A" =>
				case ("00" & opx) is
					when X"0E" =>	-- and rC, rA, rB		: rC <- rA and rB
						op_alu <= "10XX01";
					when X"1B" =>	-- srl rC, rA, rB		: rC <- (u)rA >> rB(4..0)
						op_alu <= "11X011";
					when x"31" =>	-- add rC, rA, rB		: rC <- rA + rB
						op_alu <= "000XXX";
					when x"39" =>	-- sub rC, rA, rB		: rC <- rA - rB
						op_alu <= "001XXX";
					when x"08" =>	-- cmpge rC, rA, rB	: rC <- (rA >= rB)? 1 : 0
						op_alu <= "011001";
					when x"10" =>	-- cmplt rC, rA, rB	: rC <- (rA < rB)? 1 : 0
						op_alu <= "011010";
					when x"06" =>	-- nor rC, rA, rB		: rC <- rA nor rB
						op_alu <= "10XX00";
					when x"16" =>	-- or rC, rA, rB		: rC <- rA or rB
						op_alu <= "10XX10";
					when x"1E" =>	-- xor rC, rA, rB		: rC <- rA xor rB
						op_alu <= "10XX11";
					when x"13" =>	-- sll rC, rA, rB		: rC <- rA << rB(4..0)
						op_alu <= "11X010";
					when x"3B" =>	-- sra rC, rA, rB		: rC <- (s)rA >> rB(4..0)
						op_alu <= "11X111";
					when x"12" =>	-- slli rC, rA, imm	: rC <- rA << imm(4..0)
						op_alu <= "11X010";
					when x"1A" =>	-- srli rC, rA, imm	: rC <- (u)rA >> imm(4..0)
						op_alu <= "11X011";
					when x"3A" =>	-- srai rC, rA, imm	: rC <- (s)rA >> imm(4..0)
						op_alu <= "11X111";
					when X"18"	=>	-- cmpne rC, rA, rB	: rC <- (rA /= rB)? 1 : 0
						op_alu <= "011011";
					when X"20"	=>	-- cmpeq rC, rA, rB	: rC <- (rA = rB)? 1 : 0
						op_alu <= "011100";
					when X"28"	=>	-- cmpgeu rC, rA, rB	: rC <- ((u)rA >= (u)rB)? 1 : 0
						op_alu <= "011101";
					when X"30"	=>	-- cmpltu rC, rA, rB	: rC <- ((u)rA < (u)rB)? 1 : 0
						op_alu <= "011110";
					when X"03"	=>	-- rol rC, rA, rB		: rC <- rA rol rB(4..0)
						op_alu <= "11X000";
					when X"0B"	=>	-- ror rC, rA, rB		: rC <- rA ror rB(4..0)
						op_alu <= "11X001";
					when X"02"	=> -- roli rC, rA, imm	: rC <- rA rol imm(4..0)
						op_alu <= "11X000";
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
			when X"0E"	=>			-- bge rA, rB, label	: (s)rA >= (s)rB
				op_alu <= "011001";
			when X"16"	=>			-- blt rA, rB, label	: (s)rA < (s)rB
				op_alu <= "011010";
			when X"1E"	=>			-- bne rA, rB, label	: rA /= rB
				op_alu <= "011011";
			when X"26"	=>			-- beq rA, rB, label	: rA = rB
				op_alu <= "011100";
			when X"2E"	=>			-- bgeu rA, rB, label: (u)rA >= (u)rB
				op_alu <= "011101";
			when X"36"	=>			-- bltu rA, rB, label: (u)rA < (u)rB
				op_alu <= "011110";
			when X"0C"	=>			-- andi rB, rA, imm	: rB <- and + (u)imm
				op_alu <= "10XX01";
			when X"14"	=>			-- ori rB, rA, imm	: rB <- or + (u)imm
				op_alu <= "10XX10";
			when X"1C"	=>			-- xori rB, rA, imm	: rB <- xor + (u)imm
				op_alu <= "10XX11";
			when X"08"	=>			-- cmpgei rB, rA, imm: rB <- (rA >= (s)imm)? 1 : 0
				op_alu <= "011001";
			when X"10"	=>			-- cmplti rB, rA, imm: rB <- (rA < (s)imm)? 1 : 0
				op_alu <= "011010";
			when X"18"	=>			-- cmpnei rB, rA, imm: rB <- (rA /= (s)imm)? 1 : 0
				op_alu <= "011011";
			when X"20"	=>			-- cmpeqi rB, rA, imm: rB <- (rA = (s)imm)? 1 : 0
				op_alu <= "011100";
			when X"28"	=>			-- cmpgeui rB, rA, imm: rB <- (u)rA >= (u)imm
				op_alu <= "011101";
			when X"30"	=>			-- cmpltui rB, rA, imm: rB <- (u)rA < (u)imm
				op_alu <= "011110";
			when others =>			-- Invalid
				op_alu <= "XXXXXX";
		end case;
	end process;
end synth;
