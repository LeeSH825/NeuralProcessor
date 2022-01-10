library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity synapse_bridge_re_fsm is
	generic(	WEIGHT_WIDTH	: integer := 6;
				TIME_WIDTH		: integer := 6;
				DATA_LENGTH		: integer := 5);
				
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
end synapse_bridge_re_fsm;

architecture Unit_Behavioral of synapse_bridge_re_fsm is

type state_type is (idle, master_mode, slave_mode);
signal state : state_type;

begin
-- STATE_INITIALIZING:
	-- process(clk, rst, synapse_en, exp_write_en_in)
	-- begin
	-- if (rst = '1') then
		-- state <= idle;
	-- elsif rising_edge(clk) then
		-- if (synapse_en = '1') then
			-- state <= master_mode;
		-- elsif (exp_write_en_in = '1') then
			-- state <= slave_mode;
		-- else
			-- state <= state;
		-- end if;
	-- end if;
	-- end process STATE_INITIALIZING;

STATE_BEHAVIOR:
	process(	clk, rst,
				exp_en, exp_weight_in, exp_clr_in, exp_is_data_in,
				exp_weight_in, exp_time_in, weight_in, time_in,
				synapse_en, soma_en)
		type WEIGHT_TABLE is array(natural range 0 to DATA_LENGTH) of STD_LOGIC_VECTOR(WEIGHT_WIDTH - 1 downto 0);
		variable	WEIGHT_DATA		: WEIGHT_TABLE := (others => STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH)));
		type TIME_TABLE is array(natural range 0 to DATA_LENGTH) of STD_LOGIC_VECTOR(TIME_WIDTH - 1 downto 0);
		variable	TIME_DATA		: TIME_TABLE := (others => STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH)));
		
		variable	data_write		: STD_LOGIC := '0';
		-- address(0~DATA_LENGTH): address of minimum time value| address(DATA_LENGTH+1): minimum time value from slave
		variable	address			: integer range 0 to DATA_LENGTH + 1 := 0;
		
		variable	min_time		: integer range 0 to TIME_WIDTH := TIME_WIDTH;

		variable	data_available		: integer range 0 to DATA_LENGTH := 0;
	begin
	if (rst = '1') then
		state <= idle;
	elsif rising_edge(clk) then
		case state is
		
		when idle =>
			debug_out <= "010";
			exp_possible <= '1';
			exp_clr_out <= '0';
			exp_is_data_out <='0';
			exp_weight_out <= STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			exp_time_out <= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			weight_out <= STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			time_out <= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			synapse_clr <= '0';
			soma_clr <= '0';
			if (synapse_en = '1') then
				state <= master_mode;
			elsif (exp_write_en_in = '1') then
				state <= slave_mode;
			else
				state <= state;
			end if;
			
		
		when master_mode =>
		-- receive synapse value --
			if (synapse_en = '1') then
			-- debug session --
				debug_out <= "101";
			--------------------
			-- internal parameters --
				exp_possible <= '0';
			--------------------------
			-- save value --
			-- try internal memory --
				for addr in 0 to DATA_LENGTH loop
					if (TIME_DATA(addr) = STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH)) and WEIGHT_DATA(addr) = STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH))) then			-- can be optimized : compare only time_data
						WEIGHT_DATA(addr) := weight_in;
						TIME_DATA(addr) := time_in;
					-- set parameters --
						data_write := '1';
						synapse_clr <= '1';
						data_available := data_available + 1;
					---------------------
					-- debug session --
						debug_addr <= STD_LOGIC_VECTOR(to_signed(addr, debug_addr'length));
					--------------------
						exit;
					else
					-- set parameters --
						data_write := '0';
						synapse_clr <= '0';
						data_available := data_available;
					---------------------
					end if;
				end loop;
			----------------------------
			-- try external_memory (expand_mode) --
				if (data_write = '0') then
					if (exp_en = '1') then														-- how to check if value is sended properly to slave??
						exp_weight_out <= weight_in;											--
						exp_time_out <= time_out;												--
					-- set parameters --
						exp_write_en_out <= '1';
					---------------------
					else
					-- set parameters --
						exp_write_en_out <= '0';
						synapse_clr <= '0';
					---------------------
					end if;
				end if;
			end if;
		----------------------------
		-- find minimum time value and set address (always) --
		-- debug session --
			debug_out <= "111";
		--------------------
		-- if slave exists, count slave --
			if (exp_is_data_in = '1') then
				min_time := to_integer(signed(exp_time_in));
				address := DATA_LENGTH+1;
			else
				min_time := TIME_WIDTH;
				address := 0;
			end if;
		-- find minimum time value -
			for i in 0 to DATA_LENGTH loop
			-- only for presence value --
				if (TIME_DATA(i) /= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH))) then
					if (min_time > to_integer(signed(TIME_DATA(i)))) then
						min_time := to_integer(signed(TIME_DATA(i)));
						address := i;
					else
						min_time := min_time;
						address := address;
					end if;
				end if;
			end loop;
		------------------------------------------------------
		-- send synapse value --
			if (soma_en ='1') then
			-- debug session --
				debug_out <= "110";
			-------------------
			-- values from internal memory --
				if (address < DATA_LENGTH+1) then
					weight_out <= WEIGHT_DATA(address);
					time_out <= TIME_DATA(address);
				-- refresh memory --
					WEIGHT_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
					TIME_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
				---------------------
				-- set parameters --
				data_available := data_available - 1;
				--------------------
				-- debug session --
				debug_addr <= STD_LOGIC_VECTOR(to_signed(address, debug_addr'length));
				-------------------
			-- values from external memory (expand_mode) --
				else																			-- how to check?
					weight_out <= exp_weight_in;												--
					time_out <= exp_time_out;													--
				end if;
			end if;
		------------------------
		-- if empty -> get back to idle state --
			if (data_available > 0) then
			-- set parameters --
				exp_possible <= '0';
				state <= state;
			---------------------
			else
			-- set parameters --
				exp_possible <= '1';
				state <= idle;
			end if;
		----------------------------------------
		
		when slave_mode =>
		-- receive from master --
			if (exp_write_en_in = '1') then
			-- debug session --
				debug_out <= "001";
			-------------------
			-- set parameters --
				exp_possible <= '1';
			--------------------
			-- save value --
			-- try internal memory --
				for addr in 0 to DATA_LENGTH loop
					if (TIME_DATA(addr) = STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH)) and WEIGHT_DATA(addr) = STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH))) then			-- can be optimized : compare only time_data
						WEIGHT_DATA(addr) := exp_weight_in;
						TIME_DATA(addr) := exp_time_in;
					-- set parameters --
						data_write := '1';
						exp_clr_out <= '1';
						data_available := data_available + 1;
					---------------------
					-- debug session --
						debug_addr <= STD_LOGIC_VECTOR(to_signed(addr, debug_addr'length));
					--------------------
						exit;
					else
					-- set parameters --
						data_write := '0';
						exp_clr_out <= '0';
						data_available := data_available;
					---------------------
					end if;
				end loop;
			-------------------------
			end if;
		-------------------------
		-- find minimum time value and set address (always) --
		-- debug session --
			debug_out <= "111";
		--------------------
		-- if slave exists, count slave --
			if (exp_is_data_in = '1') then
				min_time := to_integer(signed(exp_time_in));
				address := DATA_LENGTH+1;
			else
				min_time := TIME_WIDTH;
				address := 0;
			end if;
		-- find minimum time value -
			for i in 0 to DATA_LENGTH loop
			-- only for presence value --
				if (TIME_DATA(i) /= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH))) then
					if (min_time > to_integer(signed(TIME_DATA(i)))) then
						min_time := to_integer(signed(TIME_DATA(i)));
						address := i;
					else
						min_time := min_time;
						address := address;
					end if;
				end if;
			end loop;
		------------------------------------------------------
		-- sending minimum time value (always)
			exp_weight_out <= WEIGHT_DATA(address);
			exp_time_out <= TIME_DATA(address);
		--------------------------------------
		end case;
	end if;
	end process STATE_BEHAVIOR;
	
end Unit_Behavioral;