library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Clock has to react to rising edge

entity address_counter is
    Port ( Clk : in STD_LOGIC;
           Reset : in STD_LOGIC;
           counter_val : out STD_LOGIC_VECTOR (4 downto 0);
           evt : in STD_LOGIC);
end address_counter;

architecture Behavioral of address_counter is
signal Q: unsigned (4 downto 0);
signal prev_evt: STD_LOGIC;
begin

SW_Counter: process(Clk, Reset)
constant QEND: unsigned (4 downto 0) := TO_UNSIGNED(31, 5);
begin

if Reset = '0' then
            Q <= (others => '0');
            prev_evt <= '0';
elsif rising_edge(Clk) then
 
-- Check for rising edge

    if Q = QEND then
        Q <= (others => '0');
    else
    -- Check for rising_edge since valid_out of transmitter 
    --is being held high for multiple system clock cycles
        if prev_evt /= evt and evt ='1' then
            Q <= Q +1;
        end if;

    prev_evt <= evt;

    end if;
end if;

end process;
-- Nebenläufige Ausgabe
    counter_val <= std_logic_vector(Q);

end Behavioral;