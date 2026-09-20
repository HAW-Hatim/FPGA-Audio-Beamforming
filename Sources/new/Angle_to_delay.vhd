library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Angle_to_delay is
    Port ( Clk : in STD_LOGIC;
           Angle : in STD_LOGIC_VECTOR (7 downto 0);
           delay_0 : out STD_LOGIC_VECTOR (4 downto 0);
           delay_1 : out STD_LOGIC_VECTOR (4 downto 0);
           delay_2 : out STD_LOGIC_VECTOR (4 downto 0);
           delay_3 : out STD_LOGIC_VECTOR (4 downto 0);
           delay_4 : out STD_LOGIC_VECTOR (4 downto 0);
           Z1 : out INTEGER range 0 to 11; -- Tausenderstelle
           Z2 : out INTEGER range 0 to 11; -- Sign;
           Z3 : out INTEGER range 0 to 11; -- Zehnerstelle
           Z4 : out INTEGER range 0 to 11; -- Einerstelle
           Reset_n : in STD_LOGIC);
end Angle_to_delay;

architecture Behavioral of Angle_to_delay is
signal ff1_angle, s_angle: std_logic_vector(7 downto 0);
signal next_delay_1,next_delay_2,next_delay_3,next_delay_4: std_logic_vector(4 downto 0);
signal  Z1_a, Z2_a, Z3_a, Z4_a: INTEGER range 0 to 11;



begin
Sw_Output: process(Clk, Reset_n)

begin
    if Reset_n = '0' then
            delay_0 <= (others => '0'); 
            delay_1 <= (others => '0'); 
            delay_2 <= (others => '0'); 
            delay_3 <= (others => '0'); 
            delay_4 <= (others => '0'); 
    
    elsif rising_edge(Clk) then
    
        --Synchronisation of input 2FF
        ff1_angle <= Angle;
        s_angle <= ff1_angle;
            
        -- Depending on if we come from left or right one is our reference microphone
        -- Positive angle means index 0 is reached first by the sound wave hence needing to be delayed
        -- the most time
        if s_angle(7) = '0' then
            delay_4 <= (others => '0');
            delay_3 <= next_delay_1;
            delay_2 <= next_delay_2;
            delay_1 <= next_delay_3;
            delay_0 <= next_delay_4;
            
            Z2 <= 11;
        else
            delay_4 <= next_delay_4;
            delay_3 <= next_delay_3;
            delay_2 <= next_delay_2;
            delay_1 <= next_delay_1;
            delay_0 <= (others => '0');
            
            Z2 <= 10;
        
        end if;  
        Z1 <= Z1_a;
        --Z2 <= Z2_a;
        Z3 <= Z3_a;
        Z4 <= Z4_a;
    end if;
end process;

SN_Delays: process(s_angle)

begin

-- default
next_delay_4 <= (others => '0');
        next_delay_3 <= (others => '0');
        next_delay_2 <= (others => '0');
        next_delay_1 <= (others => '0');
        Z1_a <= 11;
        Z2_a <= 11;
        Z3_a <= 0;
        Z4_a <= 0;


case s_angle(6 downto 0) is
     -- Angle 90
    when "1011010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 9;
        Z4_a <= 0;
    -- Angle 89
    when "1011001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 9;
    -- Angle 88
    when "1011000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 8;
    -- Angle 87
    when "1010111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 7;
    -- Angle 86
    when "1010110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 6;
    -- Angle 85
    when "1010101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 5;
    -- Angle 84
    when "1010100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 4;
    -- Angle 83
    when "1010011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 3;
    -- Angle 82
    when "1010010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 2;
    -- Angle 81
    when "1010001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(23,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 1;
    -- Angle 80
    when "1010000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 8;
        Z4_a <= 0;
    -- Angle 79
    when "1001111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 9;
    -- Angle 78
    when "1001110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 8;
    -- Angle 77
    when "1001101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 7;
    -- Angle 76
    when "1001100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 6;
    -- Angle 75
    when "1001011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 5;
    -- Angle 74
    when "1001010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 4;
    -- Angle 73
    when "1001001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 3;
    -- Angle 72
    when "1001000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 2;
    -- Angle 71
    when "1000111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(22,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 1;
    -- Angle 70
    when "1000110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(21,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 7;
        Z4_a <= 0;
    -- Angle 69
    when "1000101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(21,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 9;
    -- Angle 68
    when "1000100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(21,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 8;
    -- Angle 67
    when "1000011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(21,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 7;
    -- Angle 66
    when "1000010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(21,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 6;
    -- Angle 65
    when "1000001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(21,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 5;
    -- Angle 64
    when "1000000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(20,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 4;
    -- Angle 63
    when "0111111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(20,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 3;
    -- Angle 62
    when "0111110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(20,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 2;
    -- Angle 61
    when "0111101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(20,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 1;
    -- Angle 60
    when "0111100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(20,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(5,5));
        Z3_a <= 6;
        Z4_a <= 0;
    -- Angle 59
    when "0111011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(19,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 9;
    -- Angle 58
    when "0111010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(19,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 8;
    -- Angle 57
    when "0111001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(19,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 7;
    -- Angle 56
    when "0111000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(19,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 6;
    -- Angle 55
    when "0110111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(19,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 5;
    -- Angle 54
    when "0110110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(18,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 4;
    -- Angle 53
    when "0110101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(18,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 3;
    -- Angle 52
    when "0110100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(18,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 2;
    -- Angle 51
    when "0110011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(18,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 1;
    -- Angle 50
    when "0110010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 5;
        Z4_a <= 0;
    -- Angle 49
    when "0110001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 4;
        Z4_a <= 9;
    -- Angle 48
    when "0110000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 4;
        Z4_a <= 8;
    -- Angle 47
    when "0101111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(17,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 4;
        Z4_a <= 7;
    -- Angle 46
    when "0101110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 4;
        Z4_a <= 6;
    -- Angle 45
    when "0101101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 4;
        Z4_a <= 5;
    -- Angle 44
    when "0101100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(16,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(4,5));
        Z3_a <= 4;
        Z4_a <= 4;
    -- Angle 43
    when "0101011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 4;
        Z4_a <= 3;
    -- Angle 42
    when "0101010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 4;
        Z4_a <= 2;
    -- Angle 41
    when "0101001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(15,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 4;
        Z4_a <= 1;
    -- Angle 40
    when "0101000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 4;
        Z4_a <= 0;
    -- Angle in Degrees: 39
    when "0100111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 9;
    -- Angle in Degrees: 38
    when "0100110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 8;
    -- Angle in Degrees: 37
    when "0100101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(14,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 7;
    -- Angle in Degrees: 36
    when "0100100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 6;
    -- Angle in Degrees: 35
    when "0100011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 5;
    -- Angle in Degrees: 34
    when "0100010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(13,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 4;
    -- Angle in Degrees: 33
    when "0100001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 3;
    -- Angle in Degrees: 32
    when "0100000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 2;
    -- Angle in Degrees: 31
    when "0011111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(12,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(3,5));
        Z3_a <= 3;
        Z4_a <= 1;
    -- Angle in Degrees: 30
    when "0011110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 3;
        Z4_a <= 0;
    -- Angle in Degrees: 29
    when "0011101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(11,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 9;
    -- Angle in Degrees: 28
    when "0011100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 8;
    -- Angle in Degrees: 27
    when "0011011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 7;
    -- Angle in Degrees: 26
    when "0011010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(10,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 6;
    -- Angle in Degrees: 25
    when "0011001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 5;
    -- Angle in Degrees: 24
    when "0011000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 4;
    -- Angle in Degrees: 23
    when "0010111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(9,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 3;
    -- Angle in Degrees: 22
    when "0010110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 2;
    -- Angle in Degrees: 21
    when "0010101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(8,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(2,5));
        Z3_a <= 2;
        Z4_a <= 1;
    -- Angle in Degrees: 20
    when "0010100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 2;
        Z4_a <= 0;
    -- Angle in Degrees: 19
    when "0010011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 9;
    -- Angle in Degrees: 18
    when "0010010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(7,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 8;
    -- Angle in Degrees: 17
    when "0010001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 7;
    -- Angle in Degrees: 16
    when "0010000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 6;
    -- Angle in Degrees: 15
    when "0001111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(6,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 5;
    -- Angle in Degrees: 14
    when "0001110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 4;
    -- Angle in Degrees: 13
    when "0001101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(5,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 3;
    -- Angle in Degrees: 12
    when "0001100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 2;
    -- Angle in Degrees: 11
    when "0001011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 1;
    -- Angle in Degrees: 10
    when "0001010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(4,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(1,5));
        Z3_a <= 1;
        Z4_a <= 0;
    -- Angle in Degrees: 9
    when "0001001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 9;
    -- Angle in Degrees: 8
    when "0001000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(3,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 8;
    -- Angle in Degrees: 7
    when "0000111" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 7;
    -- Angle in Degrees: 6
    when "0000110" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 6;
    -- Angle in Degrees: 5
    when "0000101" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(2,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 5;
    -- Angle in Degrees: 4
    when "0000100" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 4;
    -- Angle in Degrees: 3
    when "0000011" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(1,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 3;
    -- Angle in Degrees: 2
    when "0000010" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 2;
    -- Angle in Degrees: 1
    when "0000001" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 1;
    -- Angle in Degrees: 0
    when "0000000" =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
        Z3_a <= 0;
        Z4_a <= 0;

        
    -- Default
    when others =>
        next_delay_4 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_3 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_2 <= std_logic_vector(TO_UNSIGNED(0,5));
        next_delay_1 <= std_logic_vector(TO_UNSIGNED(0,5));
end case;
    
end process;
end Behavioral;