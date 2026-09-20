----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.05.2026 11:55:53
-- Design Name: 
-- Module Name: clock_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_tb is
--  Port ( );
end clock_tb;

architecture Behavioral of clock_tb is
 -- Signals to connect to the UUT
    signal Reset       : std_logic := '0';
    signal evt         : std_logic := '0';
    signal write_addr : std_logic_vector(4 downto 0);
        signal Clk       : std_logic := '0';

    
    
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

   
        
        
        -- counter
         counter: entity work.address_counter
        port map (
            Clk         => clk,
            Reset       => Reset,
            counter_val => write_addr,
            evt         => evt
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;
    
    
    -- Synchronous valid_in generator
  evt_process : process
  begin
    wait until rising_edge(Clk);
    evt <= '1';
    wait for 3 * CLK_PERIOD;   -- 9 cycles low
    wait until rising_edge(Clk);
    evt <= '0';
    wait for 19 * CLK_PERIOD;   -- 9 cycles low
  end process;
  
  
    -- Stimulus process: simple write/read to one address
    stimulus : process
        begin
        Reset <= '0';
        wait for 2*CLK_PERIOD;
                Reset <= '1';
        
wait for 500 ns;
        
        wait;
    end process;



end Behavioral;
