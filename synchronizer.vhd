----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:04:44 04/16/2019 
-- Design Name: 
-- Module Name:    synchronizer - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity synchronizer is
	generic (
		N_BITS : integer
	);
	port (
		clk	: in std_logic;
		rst	: in std_logic;
		d		: in std_logic_vector(N_BITS - 1 downto 0);
		q		: out std_logic_vector(N_BITS - 1 downto 0) := (others => '0')
	);
end synchronizer;

architecture arch_synchronizer of synchronizer is

	attribute ASYNC_REG : string;
	attribute RLOC : string;
	
	signal temp : std_logic_vector(N_BITS - 1 downto 0) := (others => '0');
	attribute ASYNC_REG of temp : signal is "TRUE";
	attribute ASYNC_REG of q : signal is "TRUE";


begin
	
	process(clk, rst) is
	begin
		if rst = '1' then
			q <= (others => '0');
			temp <= (others => '0');
		elsif rising_edge(clk) then
			q <= temp;
			temp <= d;
		end if;
	end process;

end arch_synchronizer;

