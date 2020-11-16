----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:32:29 11/01/2017 
-- Design Name: 
-- Module Name:    dds3_ad9959 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

use work.FRONTPANEL.all;

Library UNISIM;
use UNISIM.vcomponents.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dds3_ad9959 is
    Port ( 
				hi_in     : in    std_logic_vector(7 downto 0);
				hi_out    : out   std_logic_vector(1 downto 0);
				hi_inout  : inout std_logic_vector(15 downto 0);
				hi_muxsel : out   std_logic := '0';
	 
				CLK10 : in  STD_LOGIC; --10 MHz from OK VCO
			  
				sclk_out, IOUPDATE, SDIO : inout  STD_LOGIC_VECTOR(2 downto 0);
				CSB : inout STD_LOGIC_VECTOR(2 downto 0) := "111";
				LED : inout STD_LOGIC_VECTOR(7 downto 0) := "11111111"
				);
	 
	 
end dds3_ad9959;

architecture Behavioral of dds3_ad9959 is

	--opalkelly stuff
	signal ti_clk   : std_logic; -- 48MHz clk. USB data is sync'd to this.
	signal ok1      : std_logic_vector(30 downto 0);
	signal ok2      : std_logic_vector(16 downto 0);
	signal ok2s     : std_logic_vector(17*2-1 downto 0);
	
	signal ep00wire : std_logic_vector(15 downto 0);
	signal ep01wire : std_logic_vector(15 downto 0);
	signal ep02wire : std_logic_vector(15 downto 0);
	
	-- before synchronizer for clock domain crossing
	signal ep00wire_unsync : std_logic_vector(15 downto 0);
	signal ep01wire_unsync : std_logic_vector(15 downto 0);
	signal ep02wire_unsync : std_logic_vector(15 downto 0);

	signal SYSCLK, SYSCLK_INV, SYSCLK_x2 : std_logic := '0';
	signal ce : std_logic_vector(2 downto 0);
	
	signal ce_r, ioupdate_r, sdio_r : STD_LOGIC_VECTOR(2 downto 0);
	signal csb_r : STD_LOGIC_VECTOR(2 downto 0) := "111";
	signal led_r : STD_LOGIC_VECTOR(7 downto 0) := "11111111";
	
	-- fsm --
	type state_type is (idle, load, writing, updating);
	signal pr_state, nx_state : state_type := idle;
	
	signal ready, ready_r : std_logic;
	signal current_dds, current_dds_r : integer range 0 to 2 := 0;
	signal data, data_r : std_logic_vector (87 downto 0) := (others => '0');
	
	signal counter, counter_r : integer range -1 to 87 := 87;
	signal iocycle, iocycle_r : integer range 0 to 40 := 40;
	signal data_set, data_set_r : std_logic := '0';
	
	-- constants for DDS communication --
	constant CSR : std_logic_vector (7 downto 0) := "00000000";
	constant FR1 : std_logic_vector (7 downto 0) := "00000001";
	constant CFTW0 : std_logic_vector (7 downto 0) := "00000100";
	
	component synchronizer is
	generic (
		N_BITS : integer
	);
	port (
		clk	: in std_logic;
		rst	: in std_logic;
		d		: in std_logic_vector(N_BITS - 1 downto 0);
		q		: out std_logic_vector(N_BITS - 1 downto 0) := (others => '0')
	);
	end component;

begin
	sysclk_inv <= not sysclk;
	
	div2 : process(SYSCLK_x2) is
		variable counter : integer range 0 to 3 := 0;
	begin
		if rising_edge(SYSCLK_x2) then
			if counter < 2 then
				counter := counter + 1;
				SYSCLK <= '1';
			elsif counter = 2 then
				counter := counter + 1;
				SYSCLK <= '0';
			elsif counter = 3 then
				counter := 0;
				SYSCLK <= '0';
			end if;
		end if;
	end process;
	
	clocked : process(SYSCLK) is
	begin
		if rising_edge(SYSCLK) then
			pr_state <= nx_state;
			
			ce <= ce_r; ioupdate <= ioupdate_r;
			sdio <= sdio_r; csb <= csb_r;
			led <= led_r;
	
			ready <= ready_r;
			current_dds <= current_dds_r;
			data <= data_r; data_set <= data_set_r;
			counter <= counter_r; iocycle <= iocycle_r;
		end if;
	end process;
	
	comb : process (pr_state, led,
							ready, current_dds, data,
							counter, iocycle, data_set,
							ep00wire, ep01wire, ep02wire) is
		variable dds_index : integer range 0 to 2 := 0;
		variable csr_data : std_logic_vector (7 downto 0);
		variable fr1_data : std_logic_vector (23 downto 0);
		variable cftw0_data : std_logic_vector (31 downto 0);
	begin 
		nx_state <= pr_state;
		
		ce_r <= (others => '0'); ioupdate_r <= (others => '0');
		sdio_r <= (others => '0'); csb_r <= (others => '1');
		led_r <= led;
		
		ready_r <= ready;
		current_dds_r <= current_dds;
		data_r <= data; data_set_r <= data_set;
		counter_r <= counter; iocycle_r <= iocycle;

		case pr_state is 
			when idle => 
				if ep00wire(1 downto 0) = "00" then
					ready_r <= '1'; 
					led_r <= "11111111";
				else
					if ready = '1' then
						ready_r <= '0';
						nx_state <= load;
						dds_index := to_integer(unsigned(ep00wire(1 downto 0))) - 1;
						
						current_dds_r <= dds_index;
						LED_r(dds_index) <= '0';
				
						fr1_data := ep00wire(2) & ep00wire(7 downto 3) & "00" & "00000000" & "00000000";
						csr_data := ep00wire(15 downto 8);
						cftw0_data := ep02wire & ep01wire;
						data_r <= CSR & CSR_DATA & FR1 & FR1_DATA & CFTW0 & CFTW0_DATA;
					end if;
				end if; 
			when load =>
				csb_r(current_dds) <= '0';
				nx_state <= writing;
			when writing =>
				csb_r(current_dds) <= '0';
				if counter > -1 then
					ce_r(current_dds) <= '1';
					sdio_r(current_dds) <= data(counter);
					counter_r <= counter - 1;
				elsif counter = -1 then
					counter_r <= 87;
					nx_state <= updating;
				end if;
			when updating =>
				if iocycle > 0 then
					ioupdate_r(current_dds) <= '1';
					iocycle_r <= IOCYCLE -1;
				else
					ioupdate_r(current_dds) <= '0';
					iocycle_r <= 40;
					nx_state <= idle;
				end if;
			when others => 
				null;			
		end case;
	end process; 

-- Instantiate the okHost and connect endpoints
okHI : okHost port map (hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout, ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);
okWO : okWireOR  generic map (N=>2) port map (ok2=>ok2, ok2s=>ok2s);
ep00 : okWireIn  port map (ok1=>ok1, ep_addr=>x"00", ep_dataout=>ep00wire_unsync);
ep01 : okWireIn  port map (ok1=>ok1, ep_addr=>x"01", ep_dataout=>ep01wire_unsync);
ep02 : okWireIn  port map (ok1=>ok1, ep_addr=>x"02", ep_dataout=>ep02wire_unsync);

	GEN_ODDR2: for I in 0 to 2 generate
		ODDR2_clkout_0 : ODDR2
		generic map(
			DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
			INIT => '0', -- Sets initial state of the Q output to '0' or '1'
			SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
		port map (
			Q => sclk_out(I), -- 1-bit output data
			C0 => SYSCLK, -- 1-bit clock input
			C1 => SYSCLK_INV, -- 1-bit clock input
			CE => ce(I),  -- 1-bit clock enable input
			D0 => '0',   -- 1-bit data input (associated with C0)
			D1 => '1',   -- 1-bit data input (associated with C1)
			R => '0',    -- 1-bit reset input
			S => '0'     -- 1-bit set input
		);
	end generate GEN_ODDR2;
	
	sync_00 : synchronizer
	generic map (
		N_BITS => 16
	)
	port map (
		clk => SYSCLK,
		rst => '0',
		d => ep00wire_unsync,
		q => ep00wire
	);
	
	sync_01 : synchronizer
	generic map (
		N_BITS => 16
	)
	port map (
		clk => SYSCLK,
		rst => '0',
		d => ep01wire_unsync,
		q => ep01wire
	);
	
	sync_02 : synchronizer
	generic map (
		N_BITS => 16
	)
	port map (
		clk => SYSCLK,
		rst => '0',
		d => ep02wire_unsync,
		q => ep02wire
	);
	
   BUFG_inst : BUFG
   port map (
      O => SYSCLK_x2, -- 1-bit output: Clock buffer output
      I => CLK10  -- 1-bit input: Clock buffer input
   );
		
end Behavioral;

