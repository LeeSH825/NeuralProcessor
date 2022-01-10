library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity synapse_bridge_test_re is
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
				soma_clr		: in	STD_LOGIC;
				weight_out		: out	STD_LOGIC_VECTOR(WEIGHT_WIDTH-1 downto 0);
				time_out		: out	STD_LOGIC_VECTOR(TIME_WIDTH-1 downto 0));
end synapse_bridge_test_re;

architecture Unit_Behavioral of synapse_bridge_test_re is

begin
	
STATE_CONFIGURE:
	process(clk, rst, synapse_en, soma_en, weight_in, time_in)
	
		type WEIGHT_TABLE is array(natural range 0 to DATA_LENGTH) of STD_LOGIC_VECTOR(WEIGHT_WIDTH - 1 downto 0);
		variable	WEIGHT_DATA		: WEIGHT_TABLE := (others => STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH)));
		type TIME_TABLE is array(natural range 0 to DATA_LENGTH) of STD_LOGIC_VECTOR(TIME_WIDTH - 1 downto 0);
		variable	TIME_DATA		: TIME_TABLE := (others => STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH)));
		
		variable	data_write		: STD_LOGIC := '0';
		
		variable	address			: integer range 0 to DATA_LENGTH + 1 := 0;
		
		variable	min_time		: integer range 0 to TIME_WIDTH := TIME_WIDTH;

		variable	data_available		: integer range 0 to DATA_LENGTH := 0;
	
	begin
	if (rst = '1') then
		debug_out <= "000";
		debug_addr <= STD_LOGIC_VECTOR(to_signed(0, DATA_LENGTH+1));	
		
		exp_possible <= '1';
		data_available := 0;
		address := 0;
		exp_clr_out <= '0';
		exp_is_data_out <= '0';
		exp_possible <= '1';
		synapse_clr <= '0';
		--soma_clr <= '0';
		
		min_time := TIME_WIDTH;
		weight_out <= STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
		time_out <= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
		for i in 0 to DATA_LENGTH loop
			WEIGHT_DATA(i) := STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			TIME_DATA(i) := STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
		end loop;
	
	elsif rising_edge(clk) then
		-- if (soma_clr ='1' or exp_clr_in = '1') then
			-- WEIGHT_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			-- TIME_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			-- data_available := data_available - 1;
			-- if (data_available < 1) then
				-- exp_possible <= '1';
			-- else
				-- exp_possible <= '0';
			-- end if;
		-- else
			-- WEIGHT_DATA(address) := WEIGHT_DATA(address);
			-- TIME_DATA(address) := TIME_DATA(address);
			-- data_available := data_available;
			-- if (data_available < 1) then
				-- exp_possible <= '1';
			-- else
				-- exp_possible <= '0';
			-- end if;
		-- end if;
		if (synapse_en = '1' and soma_en = '1') then
		-- synapse/soma/min_find working separately
		
			-- part from synapse_en
			debug_out <= "001";
			exp_possible <= '0';
			for addr1 in 0 to DATA_LENGTH loop
				if (TIME_DATA(addr1) = STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH))) then
					WEIGHT_DATA(addr1) := weight_in;
					TIME_DATA(addr1) := time_in;
					data_write := '1';
					synapse_clr <= '1';
					data_available := data_available + 1;
					debug_addr <= STD_LOGIC_VECTOR(to_unsigned(addr1, debug_addr'length));
					exit;
				else
					data_write := '0';
					synapse_clr <= '0';
				end if;
			end loop;
			
			--using expand mode
			if (data_write = '0') then
				if (exp_en = '1') then
					synapse_clr <= '1';
					exp_weight_out <= weight_in;
					exp_time_out <= time_in;
					exp_write_en_out <= '1';		-- make '0' elsewhere
				else
					-- if expand mode not possible, request hub to wait
					exp_write_en_out <= '0';
					synapse_clr <= '0';
				end if;
			end if;
			
			-- part from soma_en
			if (data_available > 0) then
				if (address < DATA_LENGTH + 1) then
					-- found from inside
					weight_out <= WEIGHT_DATA(address);
					time_out <= TIME_DATA(address);
					
					-- WEIGHT_DATA(address) := 0;			-- can keep this value if soma request this value on next clock?
					WEIGHT_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
					TIME_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
					data_available := data_available - 1;
				else
					-- found from outside(expand_slave)
					weight_out <= exp_weight_in;
					time_out <= exp_time_in;
					exp_clr_out <= '1';
				end if;
				if (data_available = 0) then
					exp_possible <= '1';
				else	
					exp_possible <= '0';
				end if;
			else
				exp_possible <= '1';
			end if;
		elsif (synapse_en = '1') then
			debug_out <= "010";
			weight_out <= STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			time_out <= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			exp_possible <= '0';
			for addr2 in 0 to DATA_LENGTH loop
				if (TIME_DATA(addr2) = STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH))) then
					WEIGHT_DATA(addr2) := weight_in;
					TIME_DATA(addr2) := time_in;
					data_write := '1';
					synapse_clr <= '1';
					data_available := data_available + 1;
					debug_addr <= STD_LOGIC_VECTOR(to_unsigned(addr2, debug_addr'length));
					exit;
				else
					data_write := '0';
					synapse_clr <= '0';
				end if;
			end loop;
			
			--using expand mode
			if (data_write = '0') then
				if (exp_en = '1') then
					synapse_clr <= '1';
					exp_weight_out <= weight_in;
					exp_time_out <= time_in;
					exp_write_en_out <= '1';
				else
					-- if expand mode not possible, request hub to wait
					exp_write_en_out <= '1';
					synapse_clr <= '0';
				end if;
			end if;
			
		elsif (exp_write_en_in = '1') then
			debug_out <= "011";
			weight_out <= STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			time_out <= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			exp_is_data_out <= '1';
			
			for addr3 in 0 to DATA_LENGTH loop
				if (TIME_DATA(addr3) = STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH))) then
					WEIGHT_DATA(addr3) := exp_weight_in;
					TIME_DATA(addr3) := exp_time_in;
					data_available := data_available + 1;
					synapse_clr <= '1';
					data_write := '1';
					debug_addr <= STD_LOGIC_VECTOR(to_unsigned(addr3, debug_addr'length));
					exit;
				else
					data_write := '0';
					synapse_clr <= '0';
				end if;
			end loop;
			
			--using expand mode
			if (data_write = '0') then
				if (exp_en = '1') then
					synapse_clr <= '1';
					exp_weight_out <= weight_in;
					exp_time_out <= time_in;
					exp_write_en_out <= '1';
				else
					-- if expand mode not possible, request expand master to wait
					exp_write_en_out <= '1';
					synapse_clr <= '0';
				end if;
			end if;
			
			
		elsif (soma_en = '1') then
			debug_out <= "100";
			synapse_clr <= '0';

			--soma_clr <= '0';
			if (data_available > 0) then
				if (address < DATA_LENGTH + 1) then
					weight_out <= WEIGHT_DATA(address);
					time_out <= TIME_DATA(address);
					WEIGHT_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
					TIME_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
					data_available := data_available - 1;
					debug_addr <= STD_LOGIC_VECTOR(to_unsigned(address, debug_addr'length));
				else
					weight_out <= exp_weight_in;
					time_out <= exp_time_in;
					exp_clr_out <= '1';
				end if;
				if (data_available = 0) then
					exp_possible <= '1';
				else
					exp_possible <= '0';
				end if;
			else
				exp_possible <= '1';
			end if;
			
		elsif (exp_clr_in = '1') then
			debug_out <= "101";
			WEIGHT_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			TIME_DATA(address) := STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			data_available := data_available - 1;
			if (data_available < 1) then
				exp_possible <= '1';
			else
				exp_possible <= '0';
			end if;
			
			--if DATA_TABLE is empty, needs to be deactivated & make expandable
				
			
		else
			debug_out <= "110";
			synapse_clr <= '0';

			-- soma_clr <= not soma_clr;
			
			--check if expand mode is available
			if (exp_is_data_in = '1') then
				min_time := to_integer(signed(exp_time_in));
				address := DATA_LENGTH + 1;
			else
				min_time := TIME_WIDTH;
				address := 0;
			end if;
			for i in 0 to DATA_LENGTH loop
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
			weight_out <= STD_LOGIC_VECTOR(to_signed(0, WEIGHT_WIDTH));
			time_out <= STD_LOGIC_VECTOR(to_signed(0, TIME_WIDTH));
			debug_addr 	<= STD_LOGIC_VECTOR(to_unsigned(address, debug_addr'length));
		end if;		
	end if;	
	end process;

end Unit_Behavioral;
