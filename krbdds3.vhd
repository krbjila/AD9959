----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:16:41 10/27/2017 
-- Design Name: 
-- Module Name:    krbdds3 - Behavioral 
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
use work.FRONTPANEL.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity krbdds3 is
    Port ( 
			hi_in     : in    std_logic_vector(7 downto 0);
			hi_out    : out   std_logic_vector(1 downto 0);
			hi_inout  : inout std_logic_vector(15 downto 0);
			hi_muxsel : out   std_logic := '0';
	 
			CLK10 : in  STD_LOGIC);
end krbdds3;

architecture Behavioral of krbdds3 is

	--opalkelly stuff
	signal ti_clk   : std_logic; -- 48MHz clk. USB data is sync'd to this.
	signal ok1      : std_logic_vector(30 downto 0);
	signal ok2      : std_logic_vector(16 downto 0);
	signal ok2s     : std_logic_vector(17*2-1 downto 0);
	
	signal ep00wire : std_logic_vector(15 downto 0);

begin



-- Instantiate the okHost and connect endpoints
okHI : okHost port map (hi_in=>hi_in, hi_out=>hi_out, hi_inout=>hi_inout, ti_clk=>ti_clk, ok1=>ok1, ok2=>ok2);
okWO : okWireOR  generic map (N=>2) port map (ok2=>ok2, ok2s=>ok2s);
ep00 : okWireIn  port map (ok1=>ok1,                                
									ep_addr=>x"00", 
									ep_dataout=>ep00wire);

--ep01 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"01", ep_dataout=>ep01wire);
--ep02 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"02", ep_dataout=>ep02wire);
--ep03 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"03", ep_dataout=>ep03wire);
--ep04 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"04", ep_dataout=>ep04wire);
--ep05 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"05", ep_dataout=>ep05wire);
--ep06 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"06", ep_dataout=>ep06wire);
--ep07 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"07", ep_dataout=>ep07wire);
--ep08 : okWireIn  port map (ok1=>ok1,                                ep_addr=>x"08", ep_dataout=>ep08wire);
--ep20 : okWireOut port map (ok1=>ok1, ok2=>ok2s(1*17-1 downto 0*17), ep_addr=>x"20", ep_datain=>ep20wire);
--ep80 : okPipeIn  port map (ok1=>ok1, ok2=>ok2s(2*17-1 downto 1*17), ep_addr=>x"80", ep_dataout=>ep80pipe, ep_write=>ep80write);

end Behavioral;

