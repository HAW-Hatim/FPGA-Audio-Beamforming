-- Testbench for Angle_to_delay
-- Stimulus: only a clocked process (besides clock generation)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;   -- optional, for easier angle counting

entity tb_Angle_to_delay is
    -- Testbench has no ports
end tb_Angle_to_delay;

architecture sim of tb_Angle_to_delay is

    -- Component declaration of the Unit Under Test (UUT)
    component Angle_to_delay
        Port ( Clk    : in  STD_LOGIC;
               Angle  : in  STD_LOGIC_VECTOR (7 downto 0);
               delay_0 : out STD_LOGIC_VECTOR (4 downto 0);
               delay_1 : out STD_LOGIC_VECTOR (4 downto 0);
               delay_2 : out STD_LOGIC_VECTOR (4 downto 0);
               delay_3 : out STD_LOGIC_VECTOR (4 downto 0);
               delay_4 : out STD_LOGIC_VECTOR (4 downto 0);
               Reset  : in  STD_LOGIC);
    end component;

    -- Signals for connecting to UUT
    signal Clk    : STD_LOGIC := '0';
    signal Reset  : STD_LOGIC := '0';
    signal Angle  : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal delay_0, delay_1, delay_2, delay_3, delay_4 : STD_LOGIC_VECTOR (4 downto 0) := (others => '0');

    -- Clock period definition
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: Angle_to_delay
        port map (
            Clk     => Clk,
            Reset   => Reset,
            Angle   => Angle,
            delay_0 => delay_0,
            delay_1 => delay_1,
            delay_2 => delay_2,
            delay_3 => delay_3,
            delay_4 => delay_4
        );

    --------------------------------------------------------------------
    -- Clock process (independent from stimulus - generates free-running clock)
    --------------------------------------------------------------------
    clk_gen: process
    begin
        while now < 1 us loop   -- simulate for 1 µs (adjust as needed)
            Clk <= '0';
            wait for CLK_PERIOD / 2;
            Clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;   -- stop clock after simulation time is over
    end process;

    
    stim_proc: process
    begin
    Reset <= '1';
    wait for 20 ns;
        Reset <= '0';
wait for 100 ns;
    -- Test delay switch 3° and -3°
    Angle <= "00010011";
    wait for 500 ns;
        Angle <= "10000011";
    wait for 100 ns;
        Angle <= "00000011";
    wait for 100 ns;

    wait;
    
    end process;

end sim;