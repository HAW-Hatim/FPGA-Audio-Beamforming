----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2026 13:17:00
-- Design Name: 
-- Module Name: ram_tdp_rf_rf_TB - Behavioral
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

entity ram_tdp_wf_wf_TB is
--  Port ( );
end ram_tdp_wf_wf_TB;

architecture Behavioral of ram_tdp_wf_wf_TB is

 -- Small generics for easy debugging
    constant DATA_WIDTH  : integer := 4;   -- data bus width  4 bits
    constant ADDR_WIDTH  : integer := 3;   -- address bus width 3 bits
    constant RAM_DEPTH   : integer := 4;   -- 4 words deep
    

    signal clk  : std_logic := '0';
    signal ena  : std_logic := '0';
    signal enb  : std_logic := '0';
    signal wea  : std_logic := '0';
    signal web  : std_logic := '0';
    signal addra : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal addrb : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal dia  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal dib  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal doa  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dob  : std_logic_vector(DATA_WIDTH-1 downto 0);

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
            addra => addra,
            addrb => addrb,
            dia   => dia,
            dib   => dib,
            doa   => doa,
            dob   => dob
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process: simple write/read to one address
    stimulus : process
        begin
        wait for 2*CLK_PERIOD;
        -- Enable both ports
        ena <= '1';
        enb <= '1';
        
        
        -- Port A Write and Port B Read
        -- Filling the RAM
        dia <= "1010";
        addra <= "001";
        wea <= '1';
                addrb <= "001";
        wait for 103 ns;
        wait until rising_edge(CLK);
                dia <= "0010";

                addra <= "010";
                        addrb <= "010";
                        wait for 102 ns;
                                wait until rising_edge(CLK);
                                wait for 10 ns;
                        wait until rising_edge(CLK);


wait for 500 ns;
        
        wait;
    end process;


end Behavioral;
