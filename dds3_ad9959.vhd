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
			  
				
				SCLK, IOUPDATE, SDIO : out  STD_LOGIC_VECTOR(2 downto 0);
				CSB : out STD_LOGIC_VECTOR(2 downto 0) := "111";
				LED : out STD_LOGIC_VECTOR(7 downto 0) := "11111111"
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

	signal SYSCLK : std_logic;	

begin

   BUFG_inst : BUFG
   port map (
      O => SYSCLK, -- 1-bit output: Clock buffer output
      I => CLK10  -- 1-bit input: Clock buffer input
   );

	
process (SYSCLK, ep00wire) is 

	type state_type is (idle, load, writing, updating);
	variable state : state_type := idle;
	variable Ready : STD_LOGIC := '1';
	
	variable CurrentDDS : integer range 0 to 2 := 0;
	
	variable DATASET : std_logic := '0';
	variable nbit : integer range -1 to 87 := 87;
	variable IOCYCLE : integer range 0 to 40 := 40;
	
	variable DATA : std_logic_vector (87 downto 0);
	variable CSR_DATA : std_logic_vector (7 downto 0);
	variable FR1_DATA : std_logic_vector (23 downto 0);
	variable CFTW0_DATA : std_logic_vector (31 downto 0);
	
	constant CSR : std_logic_vector (7 downto 0) := "00000000";
	constant FR1 : std_logic_vector (7 downto 0) := "00000001";
	constant CFTW0 : std_logic_vector (7 downto 0) := "00000100";

begin 

	if rising_edge(SYSCLK) then 
		case state is 
			when idle => 
				if ep00wire(1 downto 0) = "00" then
					Ready := '1'; 
					LED <= "11111111";
				else
					if Ready = '1' then
						Ready := '0';
						state := load;
						CurrentDDS := to_integer(unsigned(ep00wire(1 downto 0))) - 1;
						LED(CurrentDDS) <= '0';
				
						FR1_DATA := ep00wire(2) & ep00wire(7 downto 3) & "00" & "00000000" & "00000000";
						CSR_DATA := ep00wire(15 downto 8);
						CFTW0_DATA := ep02wire & ep01wire;
						Data := CSR & CSR_DATA & FR1 & FR1_DATA & CFTW0 & CFTW0_DATA;
					end if;
				end if; 
				
			when load =>
				CSB(CurrentDDS) <= '0';
				state := writing;
			
			when writing =>
				
				if nbit > -1 then 
					if DATASET = '1' then 
						SCLK(CurrentDDS) <= '1';
						DATASET := '0';
						nbit := nbit - 1;
					elsif DATASET = '0' then 
						SCLK(CurrentDDS) <= '0';
						SDIO(CurrentDDS) <= Data(nbit);
						DATASET := '1';
					end if;
				elsif nbit = -1 then
					DATASET := '0';
					SCLK(CurrentDDS) <= '0';
					nbit := 87;
					state := updating;
				end if;
				
			when updating =>
				CSB(CurrentDDS) <= '1';
				if IOCYCLE > 0 then
					IOUPDATE(CurrentDDS) <= '1';
					IOCYCLE := IOCYCLE -1;
				else
					IOUPDATE(CurrentDDS) <= '0';
					IOCYCLE := 40;
					state := idle;
				end if;
			
			when others => 
				null;
			
		end case;
	end if;

end process; 


-- Instantiate the okHost and connect endpoints
okHI : okHost port map (hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout, ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);
okWO : okWireOR  generic map (N=>2) port map (ok2=>ok2, ok2s=>ok2s);
ep00 : okWireIn  port map (ok1=>ok1, ep_addr=>x"00", ep_dataout=>ep00wire);
ep01 : okWireIn  port map (ok1=>ok1, ep_addr=>x"01", ep_dataout=>ep01wire);
ep02 : okWireIn  port map (ok1=>ok1, ep_addr=>x"02", ep_dataout=>ep02wire);

--ep03 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"03", ep_dataout=>ep03wire);
--ep04 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"04", ep_dataout=>ep04wire);
--ep05 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"05", ep_dataout=>ep05wire);
--ep06 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"06", ep_dataout=>ep06wire);
--ep07 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"07", ep_dataout=>ep07wire);
--ep08 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"08", ep_dataout=>ep08wire);
--ep20 : okWireOut port map (ok1=>ok1, ok2=>ok2s(1*17-1 downto 0*17), ep_addr=>x"20", ep_datain=>ep20wire);
--ep80 : okPipeIn  port map (ok1=>ok1, ok2=>ok2s(2*17-1 downto 1*17), ep_addr=>x"80", ep_dataout=>ep80pipe, ep_write=>ep80write);

end Behavioral;
