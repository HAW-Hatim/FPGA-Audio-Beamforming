library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity delay_and_sum_TB is
end delay_and_sum_TB;

architecture Behavioral of delay_and_sum_TB is

  constant BITS_AUDIO  : integer := 24;
  constant DELAY_WIDTH : integer := 5;
  constant RAM_DEPTH   : integer := 32;

  signal Clk       : std_logic := '0';
  signal Reset     : std_logic := '0';
  signal valid_in  : std_logic := '0';
  signal valid_out : std_logic;

  signal audio_mic_0 : std_logic_vector(BITS_AUDIO-1 downto 0) := (others => '0');
  signal audio_mic_1 : std_logic_vector(BITS_AUDIO-1 downto 0) := (others => '0');
  signal audio_mic_2 : std_logic_vector(BITS_AUDIO-1 downto 0) := (others => '0');
  signal audio_mic_3 : std_logic_vector(BITS_AUDIO-1 downto 0) := (others => '0');
  signal audio_mic_4 : std_logic_vector(BITS_AUDIO-1 downto 0) := (others => '0');

  signal delay_0 : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal delay_1 : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal delay_2 : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal delay_3 : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal delay_4 : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  
  signal addr_0_d : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal addr_1_d : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal addr_2_d : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal addr_3_d : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  signal addr_4_d : std_logic_vector(DELAY_WIDTH-1 downto 0) := (others => '0');
  
  
  signal valid_1, valid_2, valid_3, valid_4, valid_5, delay_valid: std_logic;
  
  signal audio_out : std_logic_vector(BITS_AUDIO-1 downto 0);

  constant CLK_PERIOD : time := 10 ns;

   
begin

  uut: entity work.delay_and_sum
    generic map (
      BITS_AUDIO  => BITS_AUDIO,
      DELAY_WIDTH => DELAY_WIDTH,
      RAM_DEPTH   => RAM_DEPTH
    )
    port map (
      Clk        => Clk,
      Reset      => Reset,
      valid_in   => valid_in,
      valid_out  => valid_out,
      audio_mic_0 => audio_mic_0,
      audio_mic_1 => audio_mic_1,
      audio_mic_2 => audio_mic_2,
      audio_mic_3 => audio_mic_3,
      audio_mic_4 => audio_mic_4,
      delay_0     => delay_0,
      delay_1     => delay_1,
      delay_2     => delay_2,
      delay_3     => delay_3,
      delay_4     => delay_4,
      audio_out   => audio_out
--      mic_0_delay_addr_d => addr_0_d,
--      mic_1_delay_addr_d => addr_1_d,
--      mic_2_delay_addr_d => addr_2_d,
--      mic_3_delay_addr_d => addr_3_d,
--      mic_4_delay_addr_d => addr_4_d
    );

  -- Clock
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
    valid_in <= '1';
    wait for CLK_PERIOD;
    wait until rising_edge(Clk);
    valid_in <= '0';
    wait for 9 * CLK_PERIOD;   -- 9 cycles low
  end process;

  -- Stimuli
  stimuli : process
  begin
    Reset <= '0';
    wait for 10 ns;
    wait until rising_edge(Clk);
    Reset <= '1';

    delay_0 <= (0 => '1', others => '0');   -- = 1
    delay_1 <= (0 => '1', others => '0');
    delay_2 <= (0 => '1', others => '0');
    delay_3 <= (0 => '1', others => '0');
    -- delay_4 stays 0

    audio_mic_0 <= (0 => '1', others => '0');
    audio_mic_1 <= (0 => '1', others => '0');
    audio_mic_2 <= (0 => '1', others => '0');
    audio_mic_3 <= (0 => '1', others => '0');

    wait for 100 ns;
    wait until rising_edge(Clk);
    audio_mic_0 <= (others => '0');
    audio_mic_1 <= (others => '0');
    audio_mic_2 <= (others => '0');
    audio_mic_3 <= (others => '0');
    audio_mic_4 <= (0 => '1', others => '0');
    wait for 105 ns;
    wait until rising_edge(Clk);
    audio_mic_4 <= (others => '0');
    wait for 500 ns;
    wait;
  end process;

end Behavioral;