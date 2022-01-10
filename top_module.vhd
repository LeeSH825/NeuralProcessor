library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module_test is
	generic(	NUM_MODULE		: integer := 1;
				WEIGHT_WIDTH	: integer := 6;
				TIME_WIDTH		: integer := 6;
				DATA_LENGTH		: integer := 5);
				
	port(		CLK				: in	STD_LOGIC;
				RST				: in	STD_LOGIC;
				
				--debug_out		: out	STD_LOGIC_VECTOR(2 downto 0);
				--debug_addr		: out	STD_LOGIC_VECTOR(DATA_LENGTH downto 0);
				-- debug_weight	: out	WEIGHT_T(DATA_LENGTH downto 0);
				-- debug_time		: out	TIME_T(DATA_LENGTH downto 0);
				
				--exp_en			: in	STD_LOGIC;
				--exp_possible	: out	STD_LOGIC;
				--exp_write_en_in	: in	STD_LOGIC;
				--exp_write_en_out	: out	STD_LOGIC;		
				--exp_clr_in		: in	STD_LOGIC;
				--exp_clr_out		: out	STD_LOGIC;
				
				--exp_is_data_in	: in	STD_LOGIC;
				--exp_is_data_out	: out	STD_LOGIC;
				--exp_weight_in	: in	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
				--exp_time_in		: in	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0);
				--exp_weight_out	: out	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
				--exp_time_out	: out	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0);
				
				NEURON_SEL_IN		: in	STD_LOGIC_VECTOR(NUM_MODULE downto 0);
				NEURON_SEL_OUT		: in	STD_LOGIC_VECTOR(NUM_MODULE downto 0);
				
				--synapse_en		: in	STD_LOGIC;
				--synapse_clr		: out	STD_LOGIC;
				WEIGHT_IN		: in	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
				TIME_IN			: in	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0);
				
				--soma_en			: in	STD_LOGIC;
				--soma_clr		: out	STD_LOGIC;
				WEIGHT_OUT		: out	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
				TIME_OUT		: out	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0));
end top_module_test;

architecture Behavioral of top_module_test is

	component synapse_bridge_test
		port(		clk				: in	STD_LOGIC;
					rst				: in	STD_LOGIC;
					
					debug_out		: out	STD_LOGIC_VECTOR(2 downto 0);
					debug_addr		: out	STD_LOGIC_VECTOR(DATA_LENGTH downto 0);
					-- debug_weight	: out	WEIGHT_T(DATA_LENGTH downto 0);
					-- debug_time		: out	TIME_T(DATA_LENGTH downto 0);
					
					exp_en			: in	STD_LOGIC;
					exp_possible	: out	STD_LOGIC;
					exp_write_en_in	: in	STD_LOGIC;
					exp_write_en_out	: out	STD_LOGIC;		
					exp_clr_in		: in	STD_LOGIC;
					exp_clr_out		: out	STD_LOGIC;
					
					exp_is_data_in	: in	STD_LOGIC;
					exp_is_data_out	: out	STD_LOGIC;
					exp_weight_in	: in	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
					exp_time_in		: in	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0);
					exp_weight_out	: out	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
					exp_time_out	: out	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0);
					
					
					synapse_en		: in	STD_LOGIC;
					synapse_clr		: out	STD_LOGIC;
					weight_in		: in	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
					time_in			: in	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0);
					
					soma_en			: in	STD_LOGIC;
					soma_clr		: out	STD_LOGIC;
					weight_out		: out	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
					time_out		: out	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0));
	end component;
	
	type W_T is array(natural range 0 to NUM_MODULE-1) of STD_LOGIC_VECTOR(WEIGHT_WIDTH - 1 downto 0);
	type T_T is array(natural range 0 to NUM_MODULE-1) of STD_LOGIC_VECTOR(TIME_WIDTH - 1 downto 0);
	
	type D_A_T is array(natural range 0 to NUM_MODULE-1) of STD_LOGIC_VECTOR(DATA_LENGTH downto 0);
	type D_O_T is array(natural range 0 to NUM_MODULE-1) of STD_LOGIC_VECTOR(2 downto 0);
	
	signal	sys_rst			: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	sys_debug_out		: D_O_T;
	signal	sys_debug_addr		: D_A_T;
	
	signal	exp_en_sig		: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	exp_write_en	: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	exp_clr			: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	exp_is_data		: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	exp_weight		: W_T;
	signal	exp_time		: T_T;
	
	signal	sys_synapse_en	: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	sys_synapse_clr	: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	sys_weight_in	: W_T;
	signal	sys_time_in		: T_T;
	
	signal	sys_soma_en		: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	sys_soma_clr	: STD_LOGIC_VECTOR(NUM_MODULE-1 downto 0);
	signal	sys_weight_out	: W_T;
	signal	sys_time_out	: T_T;
	
begin

CONNECT_MODULE:
	for i in 0 to NUM_MODULE-1 generate
			-- sbt : synapse_bridge_test port map(	clk => CLK,
										-- rst => RST,
										-- debug_out => sys_debug_out(i),
										-- debug_addr => sys_debug_addr(i),
										-- -- debug_weight	: out	WEIGHT_T(DATA_LENGTH downto 0);
										-- -- debug_time		: out	TIME_T(DATA_LENGTH downto 0);
										-- exp_en => exp_en_sig(i),
										-- exp_possible => exp_en_sig(i-1) when i > 0 else exp_en_sig(NUM_MODULE-1),
										-- exp_write_en_in => exp_write_en(i),
										-- exp_write_en_out =>exp_write_en(i-1) when i > 0 else exp_write_en(NUM_MODULE-1),
										-- exp_clr_in => exp_clr(i),
										-- exp_clr_out => exp_clr(i-1) when i > 0 else exp_clr(NUM_MODULE-1),
										-- exp_is_data_in => exp_is_data(i),
										-- exp_is_data_out => exp_is_data(i-1) when i > 0 else exp_is_data(NUM_MODULE-1),
										-- exp_weight_in => exp_weight(i),
										-- exp_time_in => exp_time(i),
										-- exp_weight_out => exp_weight(i-1) when i > 0 else exp_weight(NUM_MODULE-1),
										-- exp_time_out => exp_time(i-1) when i > 0 else exp_time(NUM_MODULE-1),
										-- synapse_en => sys_synapse_en(i),
										-- synapse_clr => sys_synapse_clr(i),
										-- weight_in => sys_weight_in(i),
										-- time_in => sys_time_in(i),
										-- soma_en => sys_soma_en(i),
										-- soma_clr => sys_soma_clr(i),
										-- weight_out => sys_weight_out(i),
										-- time_out => sys_time_out(i));
	aa1: if (i = 0) generate
		sbt : synapse_bridge_test port map(	clk => CLK,
										rst => sys_rst(i),
										debug_out => sys_debug_out(i),
										debug_addr => sys_debug_addr(i),
										-- debug_weight	: out	WEIGHT_T(DATA_LENGTH downto 0);
										-- debug_time		: out	TIME_T(DATA_LENGTH downto 0);
										exp_en => exp_en_sig(i),
										exp_possible => exp_en_sig(NUM_MODULE-1),
										exp_write_en_in => exp_write_en(i),
										exp_write_en_out => exp_write_en(NUM_MODULE-1),
										exp_clr_in => exp_clr(i),
										exp_clr_out => exp_clr(NUM_MODULE-1),
										exp_is_data_in => exp_is_data(i),
										exp_is_data_out => exp_is_data(NUM_MODULE-1),
										exp_weight_in => exp_weight(i),
										exp_time_in => exp_time(i),
										exp_weight_out => exp_weight(NUM_MODULE-1),
										exp_time_out => exp_time(NUM_MODULE-1),
										synapse_en => sys_synapse_en(i),
										synapse_clr => sys_synapse_clr(i),
										weight_in => sys_weight_in(i),
										time_in => sys_time_in(i),
										soma_en => sys_soma_en(i),
										soma_clr => sys_soma_clr(i),
										weight_out => sys_weight_out(i),
										time_out => sys_time_out(i));
	end generate aa1;
	aa2: if (i > 0) generate
		sbt2 : synapse_bridge_test port map(	clk => CLK,
										rst => sys_rst(i),
										debug_out => sys_debug_out(i),
										debug_addr => sys_debug_addr(i),
										-- debug_weight	: out	WEIGHT_T(DATA_LENGTH downto 0);
										-- debug_time		: out	TIME_T(DATA_LENGTH downto 0);
										exp_en => exp_en_sig(i),
										exp_possible => exp_en_sig(i-1),
										exp_write_en_in => exp_write_en(i),
										exp_write_en_out =>exp_write_en(i-1),
										exp_clr_in => exp_clr(i),
										exp_clr_out => exp_clr(i-1),
										exp_is_data_in => exp_is_data(i),
										exp_is_data_out => exp_is_data(i-1),
										exp_weight_in => exp_weight(i),
										exp_time_in => exp_time(i),
										exp_weight_out => exp_weight(i-1),
										exp_time_out => exp_time(i-1),
										synapse_en => sys_synapse_en(i),
										synapse_clr => sys_synapse_clr(i),
										weight_in => sys_weight_in(i),
										time_in => sys_time_in(i),
										soma_en => sys_soma_en(i),
										soma_clr => sys_soma_clr(i),
										weight_out => sys_weight_out(i),
										time_out => sys_time_out(i));	
	end generate aa2;
	end generate CONNECT_MODULE;
	
	process(CLK, RST, NEURON_SEL_IN, NEURON_SEL_OUT, WEIGHT_IN, TIME_IN)
	begin
	if (RST = '1') then
		for i in 0 to NUM_MODULE-1 loop
			sys_rst(i) <= '1';
		end loop;
		
	elsif rising_edge(CLK) then
		for i in 0 to NUM_MODULE-1 loop
			sys_rst(i) <= '0';
		end loop;		if ((to_integer(signed(NEURON_SEL_IN))) > 0) then
		sys_weight_in(to_integer(signed(NEURON_SEL_IN)) - 1) <= WEIGHT_IN;
		sys_time_in(to_integer(signed(NEURON_SEL_IN)) - 1) <= TIME_IN;
		for i in 0 to NUM_MODULE-1 loop
			if (i = (to_integer(signed(NEURON_SEL_IN)) - 1)) then
				sys_synapse_en(i) <= '1';
			else
				sys_synapse_en(i) <= '0';
			end if;
		end loop;
		end if;
		if ((to_integer(signed(NEURON_SEL_OUT))) > 0) then
		for i in 0 to NUM_MODULE-1 loop
			if (i = (to_integer(signed(NEURON_SEL_OUT)) - 1)) then
				sys_soma_en(i) <= '1';
			else
				sys_soma_en(i) <= '0';
			end if;
		end loop;
		
		WEIGHT_OUT <= sys_weight_out(to_integer(signed(NEURON_SEL_OUT)) - 1);
		TIME_OUT <= sys_time_out(to_integer(signed(NEURON_SEL_OUT)) - 1);
		end if;
	
	end if;
		
	
	end process;
	
end Behavioral;