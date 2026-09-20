----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.05.2026 18:44:46
-- Design Name: 
-- Module Name: clock_and_ram_TB - Behavioral
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

entity clock_and_ram_TB is
--  Port ( );
end clock_and_ram_TB;

architecture Behavioral of clock_and_ram_TB is

 -- Small generics for easy debugging
    constant DATA_WIDTH  : integer := 4;   -- data bus width  4 bits
    constant ADDR_WIDTH  : integer := 4;   -- address bus width 3 bits
    constant RAM_DEPTH   : integer := 16;   -- 4 words deep
    

    signal clk  : std_logic := '0';
    signal ena  : std_logic := '0';
    signal enb  : std_logic := '0';
    signal wea  : std_logic := '0';
    signal web  : std_logic := '0';
    signal addrb : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal dia  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal dib  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal doa  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dob  : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    
    
    -- Signals to connect to the UUT
    signal Reset       : std_logic := '0';
    signal evt         : std_logic := '0';
    signal write_addr : std_logic_vector(4 downto 0);
    
    
    
    
    -- Clock period
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Unit Under Test
    uut : entity work.rams_tdp_wf_wf
        generic map (
            data_width  => DATA_WIDTH,
            addr_width  => ADDR_WIDTH,
            ram_depth   => RAM_DEPTH
            )
        port map (
            clk   => clk,
            ena   => ena,
            enb   => enb,
            wea   => wea,
            web   => web,
            addra => write_addr (3 downto 0),
            addrb => addrb,
            dia   => dia,
            dib   => dib,
            doa   => doa,
            dob   => dob
        );
        
        
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
    wait until rising_edge(Clk);
    evt <= '0';
    wait for 9 * CLK_PERIOD;   -- 9 cycles low
  end process;

    -- Stimulus process: simple write/read to one address
    stimulus : process
        begin
        Reset <= '1';
        wait for 2*CLK_PERIOD;
                Reset <= '0';
        -- Enable both ports
        ena <= '1';
        enb <= '1';
        wea <= '1';
        
        wait for 10 ns;
        dia <= "1101";
        wait for 45 ns;
        wait until rising_edge(Clk);
        dia <= "0001";
        addrb <= "0100";
wait for 500 ns;
        
        wait;
    end process;


end Behavioral;
