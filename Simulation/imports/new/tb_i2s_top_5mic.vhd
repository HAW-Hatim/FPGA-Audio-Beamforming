LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY tb_i2s_top_5mic IS
END ENTITY;

ARCHITECTURE sim OF tb_i2s_top_5mic IS

  SIGNAL clk_100        : STD_LOGIC := '0';
  SIGNAL reset_n        : STD_LOGIC := '0';
  
  signal angle          : STD_LOGIC_VECTOR(7 downto 0) := "00000011";
  
  SIGNAL mic_dout_12    : STD_LOGIC := '0';
  SIGNAL mic_dout_34    : STD_LOGIC := '0';
  SIGNAL mic_dout_5     : STD_LOGIC := '0';

  SIGNAL mic_bclk       : STD_LOGIC;
  SIGNAL mic_lrcl       : STD_LOGIC;
  SIGNAL i2s_sd_tx      : STD_LOGIC;

  --SIGNAL sample_valid_o : STD_LOGIC;

  --SIGNAL mic1_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic2_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic3_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic4_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);
  --SIGNAL mic5_o         : STD_LOGIC_VECTOR(23 DOWNTO 0);

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
    mic_lrcl => mic_lrcl
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


 -------------------------------------------------------------------------------
-- Mic pair 1
--
-- Mic1 delayed by 1 sample
-- Mic2 delayed by 1 sample
-------------------------------------------------------------------------------
PROCESS
 
  VARIABLE bit_cnt      : INTEGER RANGE 0 TO 63 := 0;
  VARIABLE sample_count : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
 
  VARIABLE current_left  :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
  VARIABLE current_right :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
 
  VARIABLE delayed_left :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
  VARIABLE delayed_right :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
  VARIABLE bit_pos : INTEGER;
 
BEGIN
 
  mic_dout_12 <= '0';
 
  WAIT UNTIL reset_n='1';
 
  WAIT UNTIL rising_edge(mic_bclk);
 
  LOOP
 
      WAIT UNTIL falling_edge(mic_bclk);
 
 
      IF bit_cnt=63 THEN
 
          bit_cnt:=0;
 
 
          -------------------------------------------------------------------
          -- delay by one sample
          -------------------------------------------------------------------
 
          delayed_left := current_left;
 
          delayed_right := current_right;
 
 
          -------------------------------------------------------------------
          -- create new sample
          -------------------------------------------------------------------
 
          current_left :=
          x"000000" OR
          STD_LOGIC_VECTOR(
          resize(sample_count,24));
 
          current_right :=
          x"000000" OR
          STD_LOGIC_VECTOR(
          resize(sample_count,24));
 
 
          sample_count :=
          sample_count+1;
 
      ELSE
 
          bit_cnt:=bit_cnt+1;
 
      END IF;
 
 
      -----------------------------------------------------------------------
      -- left slot
      -----------------------------------------------------------------------
 
      IF bit_cnt>=1 AND bit_cnt<=24 THEN
 
          bit_pos:=24-bit_cnt;
 
          mic_dout_12 <=
          delayed_left(bit_pos);
 
 
      -----------------------------------------------------------------------
      -- right slot
      -----------------------------------------------------------------------
 
      ELSIF bit_cnt>=33 AND bit_cnt<=56 THEN
 
          bit_pos:=56-bit_cnt;
 
          mic_dout_12 <=
          delayed_right(bit_pos);
 
      ELSE
 
          mic_dout_12<='0';
 
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
 
  VARIABLE current_left :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
  VARIABLE current_right :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
 
  VARIABLE delayed_left :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
  VARIABLE delayed_right :
  STD_LOGIC_VECTOR(23 DOWNTO 0) := (OTHERS=>'0');
 
  VARIABLE bit_pos : INTEGER;
 
BEGIN
 
  mic_dout_34 <= '0';
 
  WAIT UNTIL reset_n='1';
 
  WAIT UNTIL rising_edge(mic_bclk);
 
  LOOP
 
      WAIT UNTIL falling_edge(mic_bclk);
 
      IF bit_cnt=63 THEN
 
          bit_cnt:=0;
 
 
          delayed_left := current_left;
 
          delayed_right := current_right;
 
 
          current_left :=
          x"000000" OR
          STD_LOGIC_VECTOR(
          resize(sample_count,24));
 
          current_right :=
          x"000000" OR
          STD_LOGIC_VECTOR(
          resize(sample_count,24));
 
 
          sample_count :=
          sample_count+1;
 
      ELSE
 
          bit_cnt:=bit_cnt+1;
 
      END IF;
 
 
      IF bit_cnt>=1 AND bit_cnt<=24 THEN
 
          bit_pos:=24-bit_cnt;
 
          mic_dout_34 <=
          delayed_left(bit_pos);
 
 
      ELSIF bit_cnt>=33 AND bit_cnt<=56 THEN
 
          bit_pos:=56-bit_cnt;
 
          mic_dout_34 <=
          delayed_right(bit_pos);
 
      ELSE
 
          mic_dout_34<='0';
 
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
 
  VARIABLE bit_cnt      : INTEGER RANGE 0 TO 63 :=0;
 
  VARIABLE sample_count :
  UNSIGNED(7 DOWNTO 0):=(OTHERS=>'0');
 
  VARIABLE left_sample :
  STD_LOGIC_VECTOR(23 DOWNTO 0);
 
  VARIABLE bit_pos : INTEGER;
 
BEGIN
 
  mic_dout_5<='0';
 
  WAIT UNTIL reset_n='1';
 
  WAIT UNTIL rising_edge(mic_bclk);
 
  LOOP
 
      WAIT UNTIL falling_edge(mic_bclk);
 
 
      IF bit_cnt=63 THEN
 
          bit_cnt:=0;
 
          left_sample :=
          x"000000" OR
          STD_LOGIC_VECTOR(
          resize(sample_count,24));
 
          sample_count :=
          sample_count+1;
 
      ELSE
 
          bit_cnt:=bit_cnt+1;
 
      END IF;
 
 
      -----------------------------------------------------------------------
      -- left slot only
      -----------------------------------------------------------------------
 
      IF bit_cnt>=1 AND bit_cnt<=24 THEN
 
          bit_pos:=24-bit_cnt;
 
          mic_dout_5 <=
          left_sample(bit_pos);
 
      ELSE
 
          mic_dout_5<='0';
 
      END IF;
 
  END LOOP;
 
END PROCESS;


  ---------------------------------------------------------------------------
  -- Monitor
  ---------------------------------------------------------------------------
  PROCESS
  BEGIN
    WAIT UNTIL sample_valid_o = '1';

    REPORT "New 5-mic sample set:";
    REPORT "Mic1 = " & INTEGER'image(to_integer(unsigned(mic1_o)));
    REPORT "Mic2 = " & INTEGER'image(to_integer(unsigned(mic2_o)));
    REPORT "Mic3 = " & INTEGER'image(to_integer(unsigned(mic3_o)));
    REPORT "Mic4 = " & INTEGER'image(to_integer(unsigned(mic4_o)));
    REPORT "Mic5 = " & INTEGER'image(to_integer(unsigned(mic5_o)));

    WAIT;
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