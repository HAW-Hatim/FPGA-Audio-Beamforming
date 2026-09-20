LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY TB_Top_Beamformer IS
END ENTITY;

ARCHITECTURE sim OF TB_Top_Beamformer IS

  SIGNAL clk_100        : STD_LOGIC := '0';
  SIGNAL reset_n        : STD_LOGIC := '0';
  
  signal angle          : STD_LOGIC_VECTOR(7 downto 0) := "10000011"; -- -3°
  
  SIGNAL mic_dout_12    : STD_LOGIC := '0';
  SIGNAL mic_dout_34    : STD_LOGIC := '0';
  SIGNAL mic_dout_5     : STD_LOGIC := '0';

  SIGNAL mic_bclk       : STD_LOGIC;
  SIGNAL mic_lrcl       : STD_LOGIC;
  SIGNAL i2s_sd_tx      : STD_LOGIC;
    
  SIGNAL valid_out_das      : STD_LOGIC;
  SIGNAL valid_in_das      : STD_LOGIC;
    
    SIGNAL bit_count      : STD_LOGIC_VECTOR(6 downto 0);


  --SIGNAL sample_valid_o : STD_LOGIC;

  --SIGNAL mic1_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic2_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic3_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic4_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic5_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
    SIGNAL    audio_out_DAS: STD_LOGIC_VECTOR(23 DOWNTO 0);
  CONSTANT CLK100_HALF_PERIOD : TIME := 5 ns;
  
  
BEGIN

  ---------------------------------------------------------------------------
  -- 100 MHz Basys3 clock
  ---------------------------------------------------------------------------
  clk_100 <= NOT clk_100 AFTER CLK100_HALF_PERIOD;


  ---------------------------------------------------------------------------
  -- Device under test
  --
  -- The DUT contains the real Vivado-generated clk_wiz_I2S IP.
  -- Therefore, do NOT define a clk_wiz_I2S stub in this testbench.
  ---------------------------------------------------------------------------
  dut : ENTITY work.Top_Beamformer
    port map(
    Angle => angle,
    Clk => clk_100,
    Reset => Reset_n,
    i2s_sd_tx => i2s_sd_tx,
    mic_bclk => mic_bclk,
    mic_dout_12 => mic_dout_12,
    mic_dout_34 => mic_dout_34,
    mic_dout_5 => mic_dout_5,
    mic_lrcl => mic_lrcl,
    valid_out => valid_out_das,
    valid_in_delaysum => valid_in_das,
    audio_out_DAS => audio_out_DAS
  );


  ---------------------------------------------------------------------------
  -- Reset
  ---------------------------------------------------------------------------
  PROCESS
  BEGIN
    reset_n <= '0';
    WAIT FOR 2 us;

    reset_n <= '1';

    WAIT;
  END PROCESS;

PROCESS
  VARIABLE bit_cnt      : INTEGER RANGE 0 TO 63 := 0;
  VARIABLE sample_count : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
  VARIABLE current_left  : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
  VARIABLE current_right : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
  VARIABLE bit_pos : INTEGER;
BEGIN
  mic_dout_12 <= '0';
  WAIT UNTIL reset_n='1';
  WAIT UNTIL rising_edge(mic_bclk);
  LOOP
    WAIT UNTIL falling_edge(mic_bclk);

    IF bit_cnt = 63 THEN
      bit_cnt := 0;

      -- Schedule the sample for the NEXT frame.
      -- sample_count = 0  ->  frame 1 just ended, prepare frame 2 = impulse
      IF sample_count = 0 THEN
        current_left  := x"000001";
        current_right := x"000001";
      ELSE
        current_left  := x"000000";
        current_right := x"000000";
      END IF;

      sample_count := sample_count + 1;
    ELSE
      bit_cnt := bit_cnt + 1;
    END IF;

    -- Left slot
    IF bit_cnt >= 1 AND bit_cnt <= 24 THEN
      bit_pos := 24 - bit_cnt;
      mic_dout_12 <= current_left(bit_pos);       -- directly output the prepared sample

    -- Right slot
    ELSIF bit_cnt >= 33 AND bit_cnt <= 56 THEN
      bit_pos := 56 - bit_cnt;
      mic_dout_12 <= current_right(bit_pos);

    ELSE
      mic_dout_12 <= '0';
    END IF;
  END LOOP;
END PROCESS;
 
 
-------------------------------------------------------------------------------

-- Mic pair 2

--

-- Mic3 delayed by 1 sample

-- Mic4 delayed by 1 sample

-------------------------------------------------------------------------------

PROCESS
  VARIABLE bit_cnt      : INTEGER RANGE 0 TO 63 := 0;
  VARIABLE sample_count : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
  VARIABLE current_left  : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
  VARIABLE current_right : STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
  VARIABLE bit_pos : INTEGER;
BEGIN
  mic_dout_34 <= '0';
  WAIT UNTIL reset_n='1';
  WAIT UNTIL rising_edge(mic_bclk);
  LOOP
    WAIT UNTIL falling_edge(mic_bclk);

    IF bit_cnt = 63 THEN
      bit_cnt := 0;

      IF sample_count = 0 THEN
        current_left  := x"000001";
        current_right := x"000001";
      ELSE
        current_left  := x"000000";
        current_right := x"000000";
      END IF;

      sample_count := sample_count + 1;
    ELSE
      bit_cnt := bit_cnt + 1;
    END IF;

    IF bit_cnt >= 1 AND bit_cnt <= 24 THEN
      bit_pos := 24 - bit_cnt;
      mic_dout_34 <= current_left(bit_pos);
    ELSIF bit_cnt >= 33 AND bit_cnt <= 56 THEN
      bit_pos := 56 - bit_cnt;
      mic_dout_34 <= current_right(bit_pos);
    ELSE
      mic_dout_34 <= '0';
    END IF;
  END LOOP;
END PROCESS;
 
 
-------------------------------------------------------------------------------

-- Mic5

--

-- NO DELAY

--

-- Mic5 arrives first

-------------------------------------------------------------------------------

PROCESS
  VARIABLE bit_cnt      : INTEGER RANGE 0 TO 63 := 0;
  VARIABLE left_sample  : STD_LOGIC_VECTOR(23 DOWNTO 0) := x"000008";  -- impulse in first frame
  VARIABLE bit_pos      : INTEGER;
BEGIN
  mic_dout_5 <= '0';
  WAIT UNTIL reset_n = '1';
  WAIT UNTIL rising_edge(mic_bclk);
  LOOP
    WAIT UNTIL falling_edge(mic_bclk);

    IF bit_cnt = 63 THEN
      bit_cnt := 0;
      left_sample := x"000000";   -- all later samples are zero
    ELSE
      bit_cnt := bit_cnt + 1;
    END IF;

    -- left slot only
    IF bit_cnt >= 1 AND bit_cnt <= 24 THEN
      bit_pos := 24 - bit_cnt;
      mic_dout_5 <= left_sample(bit_pos);
    ELSE
      mic_dout_5 <= '0';
    END IF;
    bit_count <= std_logic_vector(to_unsigned(bit_cnt, bit_count'length));
  END LOOP;
END PROCESS;
 
 




  ---------------------------------------------------------------------------
  -- End simulation
  ---------------------------------------------------------------------------
  PROCESS
  BEGIN
    WAIT FOR 300 us;
    ASSERT false REPORT "Simulation finished." SEVERITY failure;
  END PROCESS;

END ARCHITECTURE;