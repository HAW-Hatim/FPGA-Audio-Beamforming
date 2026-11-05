library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity delay_and_sum is
generic(
    BITS_AUDIO : integer := 24;
    DELAY_WIDTH : integer := 5;
    RAM_DEPTH: integer := 32);
    Port ( audio_mic_0 : in STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
           audio_mic_1 : in STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
           audio_mic_2 : in STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
           audio_mic_3 : in STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
           audio_mic_4 : in STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
           Clk : in STD_LOGIC;
           Reset : in STD_LOGIC;
           valid_in : in STD_LOGIC;
           delay_0 : in STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
           delay_1 : in STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
           delay_2 : in STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
           delay_3 : in STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
           delay_4 : in STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
           audio_out : out STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
           valid_out : out STD_LOGIC--;
--           debug_valid_r1 : out STD_LOGIC;
--           debug_valid_r2 : out STD_LOGIC;
--           debug_valid_r3 : out STD_LOGIC;
--           debug_valid_r4 : out STD_LOGIC;
--           debug_valid_r5 : out STD_LOGIC;
--           debug_delay_valid: out STD_LOGIC
--           mic_0_delay_addr_d : out STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
--           mic_1_delay_addr_d : out STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
--           mic_2_delay_addr_d : out STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
--           mic_3_delay_addr_d : out STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0);
--           mic_4_delay_addr_d : out STD_LOGIC_VECTOR ((DELAY_WIDTH - 1) downto 0)          
           );
end delay_and_sum;

architecture Behavioral of delay_and_sum is

-- Audio read from our RAMS
signal audio_mic_out_0, audio_mic_out_1, audio_mic_out_2, audio_mic_out_3, audio_mic_out_4: STD_LOGIC_VECTOR ((BITS_AUDIO - 1) downto 0);
signal audio_sum : signed ((BITS_AUDIO +  1) downto 0) := TO_SIGNED(0, (BITS_AUDIO + 2));

signal delay_valid: STD_LOGIC; -- Signal to specifiy that we have enough samples to perform a delay
signal prev_delay_0, prev_delay_1, prev_delay_2, prev_delay_3, prev_delay_4: STD_LOGIC_VECTOR((DELAY_WIDTH - 1) downto 0);

-- Signal used to get maximum delay for current angle
signal max_delay: STD_LOGIC_VECTOR((DELAY_WIDTH - 1) downto 0);

signal sample_counter: unsigned (DELAY_WIDTH-1 downto 0) := TO_UNSIGNED(0, DELAY_WIDTH);


--Registers to delay our valid_out to account for all latencies
signal valid_r1, valid_r2, valid_r3, valid_r4, valid_r5, valid_r6: STD_LOGIC;

-- Delay  addresses for mics
signal mic_0_delay_addr, mic_1_delay_addr, mic_2_delay_addr, mic_3_delay_addr, mic_4_delay_addr: STD_LOGIC_VECTOR((DELAY_WIDTH - 1) downto 0);

-- Output of our counter
signal write_addr: STD_LOGIC_VECTOR((DELAY_WIDTH - 1) downto 0);

signal prev_valid_in:STD_LOGIC;

-- Address counter component
component address_counter is
    Port ( Clk : in STD_LOGIC;
           Reset : in STD_LOGIC;
           counter_val : out STD_LOGIC_VECTOR (4 downto 0);
           evt : in STD_LOGIC);
end component;


-- RAM component
component rams_tdp_wf_wf is
generic(
    data_width : integer;
    addr_width : integer;
    ram_depth: integer);
port(
    clk : in std_logic; -- Clock
    ena : in std_logic; -- Enable Port A
    enb : in std_logic; -- Enable Port B
    wea : in std_logic; -- Write Enable Port A
    web : in std_logic; -- Write Enable Port B
    addra : in std_logic_vector(addr_width-1 downto 0); -- Address Port A
    addrb : in std_logic_vector(addr_width-1 downto 0); -- Address Port B
    dia : in std_logic_vector(data_width-1 downto 0); -- Data in Port A
    dib : in std_logic_vector(data_width-1 downto 0); -- Data in Port B
    doa : out std_logic_vector(data_width-1 downto 0); -- Data out Port A
    dob : out std_logic_vector(data_width-1 downto 0) -- Data out Port B
);
end component;


begin

-- Counter signal mapping

Addres_counter_0: address_counter
    Port map( Clk => Clk,
           Reset => Reset,
           counter_val => write_addr,
           evt => valid_in);


-- RAM configuration Port A only for writing, Port B only for reading, both ports always on

-- RAM instance 0
Ram_0: component rams_tdp_wf_wf
generic map(
    data_width => BITS_AUDIO,
    addr_width => DELAY_WIDTH,
    ram_depth => RAM_DEPTH
)
port map(
    clk => Clk,
    ena => '1',
    enb => '1',
    wea => '1',
    web => '0',
    addra => write_addr,
    addrb => mic_0_delay_addr,
    dia => audio_mic_0,
    dib => (others => '0'),
    doa => open,
    dob => audio_mic_out_0
);

-- RAM instance 1
Ram_1: component rams_tdp_wf_wf
generic map(
    data_width => BITS_AUDIO,
    addr_width => DELAY_WIDTH,
    ram_depth => RAM_DEPTH
)
port map(
    clk => Clk,
    ena => '1',
    enb => '1',
    wea => '1',
    web => '0',
    addra => write_addr,
    addrb => mic_1_delay_addr,
    dia => audio_mic_1,
    dib => (others => '0'),
    doa => open,
    dob => audio_mic_out_1
);

-- RAM instance 2
Ram_2: component rams_tdp_wf_wf
generic map(
    data_width => BITS_AUDIO,
    addr_width => DELAY_WIDTH,
    ram_depth => RAM_DEPTH
)
port map(
    clk => Clk,
    ena => '1',
    enb => '1',
    wea => '1',
    web => '0',
    addra => write_addr,
    addrb => mic_2_delay_addr,
    dia => audio_mic_2,
    dib => (others => '0'),
    doa => open,
    dob => audio_mic_out_2
);

-- RAM instance 3
Ram_3: component rams_tdp_wf_wf
generic map(
    data_width => BITS_AUDIO,
    addr_width => DELAY_WIDTH,
    ram_depth => RAM_DEPTH
)
port map(
    clk => Clk,
    ena => '1',
    enb => '1',
    wea => '1',
    web => '0',
    addra => write_addr,
    addrb => mic_3_delay_addr,
    dia => audio_mic_3,
    dib => (others => '0'),
    doa => open,
    dob => audio_mic_out_3
);

-- RAM instance 4
Ram_4: component rams_tdp_wf_wf
generic map(
    data_width => BITS_AUDIO,
    addr_width => DELAY_WIDTH,
    ram_depth => RAM_DEPTH
)
port map(
    clk => Clk,
    ena => '1',
    enb => '1',
    wea => '1',
    web => '0',
    addra => write_addr,
    addrb => mic_4_delay_addr,
    dia => audio_mic_4,
    dib => (others => '0'),
    doa => open,
    dob => audio_mic_out_4
);


SW: process(Clk, Reset)
begin

    if(Reset = '0') then
        audio_out <= (others => '0');
        valid_r1<= '0';
        valid_r2 <= '0';
        valid_r3 <= '0';
        valid_r4 <= '0';
        sample_counter <= (others => '0');
        delay_valid <= '0';
    elsif rising_edge(Clk) then
        if ((prev_delay_0 /= delay_0) or (prev_delay_1 /= delay_1) or (prev_delay_2 /= delay_2) or (prev_delay_3 /= delay_3) or  (prev_delay_4 /= delay_4)) then
            audio_out <= (others => '0');
            valid_r1<= '0';
            valid_r2 <= '0';
            valid_r3 <= '0';
            valid_r4 <= '0';
            delay_valid <= '0';
        else
            
            if (valid_in = '1' and prev_valid_in = '0') and sample_counter <= unsigned(max_delay) then
                sample_counter <= sample_counter + 1;
            end if;
            
            if sample_counter > unsigned(max_delay) then
                delay_valid <= '1';
            else
                delay_valid <= '0';
            end if;
       
            -- 2 delays read latency , 1 delay shift latency, 1 delay summation, 1 delay valid_in -> write_address, 
            -- Summation of audio -> avoiding of overflow by adding 2 bits for worst case scenario
            -- Shift our audio sum by 2 bits to the right (arithmetically) to have 24 bit audio again
            -- First to unsigned so information on left is just cutoff
            
            -- Summing audio input
            audio_sum <= RESIZE(signed(audio_mic_out_0), BITS_AUDIO+2) + RESIZE(signed(audio_mic_out_1),BITS_AUDIO+2)  + RESIZE(signed(audio_mic_out_2), BITS_AUDIO+2) + RESIZE(signed(audio_mic_out_3), BITS_AUDIO+2) + RESIZE(signed(audio_mic_out_4), BITS_AUDIO+2);
        
            audio_out <= STD_LOGIC_VECTOR(RESIZE(shift_right(audio_sum, 2),24));
            
            valid_r1 <= valid_in;
            valid_r2 <= valid_r1;
            valid_r3 <= valid_r2;
                
                
            if valid_r3 = '1' and delay_valid = '1' then
                valid_r4 <= '1';
            else
                valid_r4 <= '0';
            end if;
            valid_out <= valid_r4;
        end if;
     
        prev_delay_0 <= delay_0;
        prev_delay_1 <= delay_1;
        prev_delay_2 <= delay_2;
        prev_delay_3 <= delay_3;
        prev_delay_4 <= delay_4;
        
        prev_valid_in <= valid_in;
        
    end if;
end process;

SN: process(write_addr, mic_0_delay_addr, mic_1_delay_addr, mic_2_delay_addr,
            mic_3_delay_addr, mic_4_delay_addr,
            delay_0, delay_1, delay_2, delay_3, delay_4,
            prev_delay_0, prev_delay_1, prev_delay_2, prev_delay_3, prev_delay_4,
             delay_valid, valid_r5, valid_r6)
begin

-- Calculate address for the delayed sample we want
mic_0_delay_addr <= std_logic_vector(unsigned(write_addr) - unsigned(delay_0) - 1);
mic_1_delay_addr <= std_logic_vector(unsigned(write_addr) - unsigned(delay_1) - 1);
mic_2_delay_addr <= std_logic_vector(unsigned(write_addr) - unsigned(delay_2) - 1);
mic_3_delay_addr <= std_logic_vector(unsigned(write_addr) - unsigned(delay_3) - 1);
mic_4_delay_addr <= std_logic_vector(unsigned(write_addr) - unsigned(delay_4) - 1);

-- Get max_delay
if delay_0 > delay_4 then
    max_delay <= delay_0;
else
    max_delay <= delay_4;
end if;

end process;

--debug_valid_r1 <= valid_r1;
--debug_valid_r2 <= valid_r2;
--debug_valid_r3 <= valid_r3;
--debug_valid_r4 <= valid_r4;
--debug_valid_r5 <= valid_r5;
--debug_delay_valid <= delay_valid;

--mic_0_delay_addr_d <= mic_0_delay_addr;
--mic_1_delay_addr_d <= mic_1_delay_addr;
--mic_2_delay_addr_d <= mic_2_delay_addr;
--mic_3_delay_addr_d <= mic_3_delay_addr;
--mic_4_delay_addr_d <= mic_4_delay_addr;


end Behavioral;