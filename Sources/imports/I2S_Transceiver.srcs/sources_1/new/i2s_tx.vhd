LIBRARY ieee;
USE ieee.std_logic_1164.all;
 
ENTITY i2s_tx IS
  GENERIC(
    d_width       : INTEGER := 24;  -- number of valid audio data bits
    sclk_ws_ratio : INTEGER := 64   -- number of BCLK periods per stereo frame
  );
  PORT(
    reset_n      : IN  STD_LOGIC;   -- asynchronous active-low reset
    mclk         : IN  STD_LOGIC;   -- internal FPGA clock, e.g. 25.6 MHz
 
    ws           : IN  STD_LOGIC;   -- word select / LRCLK: '0' = left, '1' = right
    sclk_fall    : IN  STD_LOGIC;   -- one-mclk-cycle pulse on BCLK falling edge
    bit_index    : IN  INTEGER RANGE 0 TO sclk_ws_ratio-1;
 
    -- Frame-synchronous valid signal from i2s_timing
    -- This signal defines when a new sample may be loaded
    -- into the TX shift registers
    timing_sample_valid : IN STD_LOGIC;
 
    -- Valid signal from beamformer
    -- l_data_tx / r_data_tx contain a newly computed sample
    beamformer_valid : IN STD_LOGIC;
 
    l_data_tx    : IN  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
    r_data_tx    : IN  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
 
    sd_tx        : OUT STD_LOGIC    -- serial I2S data output
  );
END ENTITY;
 
 
ARCHITECTURE rtl OF i2s_tx IS
 
  -- One stereo frame has two slots
  -- With sclk_ws_ratio = 64:
  --   left slot  = bit_index 0..31
  --   right slot = bit_index 32..63
  CONSTANT slot_width : INTEGER := sclk_ws_ratio / 2;
 
  -- I2S has a one-bit delay after WS changes
  -- Therefore:
  --   left  valid bits = 1..d_width
  --   right valid bits = slot_width+1 .. slot_width+d_width
  CONSTANT left_first_bit  : INTEGER := 1;
  CONSTANT left_last_bit   : INTEGER := d_width;
 
  CONSTANT right_first_bit : INTEGER := slot_width + 1;
  CONSTANT right_last_bit  : INTEGER := slot_width + d_width;
 
  -- Internal transmit shift registers
  -- Data is transmitted MSB first
  SIGNAL l_shift : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL r_shift : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
 
  -- Buffer registers for completed beamformer output samples
  -- Samples are NOT transmitted immediately
  -- They wait here until the next I2S frame starts
  SIGNAL l_buffer : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL r_buffer : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');
 
  -- Indicates that the buffer contains a new sample
  -- that has not yet been loaded into the TX shift registers
  SIGNAL buffer_valid : STD_LOGIC := '0';
 
  
BEGIN
 
  PROCESS(mclk, reset_n)
  VARIABLE tx_bit_index : INTEGER RANGE 0 TO sclk_ws_ratio-1;
  BEGIN
 
    IF reset_n = '0' THEN
 
      -- Clear transmit shift registers
      l_shift <= (OTHERS => '0');
      r_shift <= (OTHERS => '0');
 
      -- Clear buffer registers
      l_buffer <= (OTHERS => '0');
      r_buffer <= (OTHERS => '0');
 
      buffer_valid <= '0';
      -- Drive serial output low during reset
      sd_tx <= '0';
 
 
    ELSIF rising_edge(mclk) THEN
        IF timing_sample_valid = '1' THEN
            IF buffer_valid = '1' THEN
                --------------------------------------------------------------------
                -- A previously buffered sample is waiting.
                -- Send that one now.
                --------------------------------------------------------------------
                l_shift <= l_buffer;
                r_shift <= r_buffer;

                --------------------------------------------------------------------
                -- If a new sample arrives in the same clock cycle, keep it buffered
                -- for the next frame instead of losing it.
                --------------------------------------------------------------------
                IF beamformer_valid = '1' THEN
                    l_buffer <= l_data_tx;
                    r_buffer <= r_data_tx;
                    buffer_valid <= '1';
                ELSE
                    buffer_valid <= '0';
                END IF;

            ELSIF beamformer_valid = '1' THEN
                --------------------------------------------------------------------
                -- No old buffered sample exists.
                -- Use the newly arriving sample directly.
                -- This is the important case for microphone test mode.
                --------------------------------------------------------------------
                l_shift <= l_data_tx;
                r_shift <= r_data_tx;
                buffer_valid <= '0';

            ELSE
                --------------------------------------------------------------------
                -- No audio sample available.
                --------------------------------------------------------------------
                l_shift <= (OTHERS => '0');
                r_shift <= (OTHERS => '0');
                buffer_valid <= '0';
            END IF;
 
      ------------------------------------------------------------------------
      -- Perform serial I2S transmission
      --
      -- Shifting is only allowed if no new frame is loaded during this
      -- mclk cycle.
      --
      -- This prevents simultaneous load/shift conflicts.
      ------------------------------------------------------------------------
      ELSIF sclk_fall='1' THEN
        IF bit_index = sclk_ws_ratio-1 THEN 
            tx_bit_index := 0;
        ELSE 
            tx_bit_index := bit_index+1;
        END IF;
        ----------------------------------------------------------------------
        -- LEFT CHANNEL SLOT
        ----------------------------------------------------------------------
        IF ws='0' THEN
          IF tx_bit_index>=left_first_bit AND tx_bit_index<=left_last_bit THEN
            -- Transmit MSB first
            sd_tx <= l_shift(d_width-1);
            -- Shift left
            l_shift <= l_shift(d_width-2 DOWNTO 0) & '0';
          ELSE
            -- Delay bit and padding bits
            sd_tx <= '0';
          END IF;
 
        ----------------------------------------------------------------------
        -- RIGHT CHANNEL SLOT
        ----------------------------------------------------------------------
        ELSE
          IF tx_bit_index>=right_first_bit AND tx_bit_index<=right_last_bit THEN
            -- Transmit MSB first
            sd_tx <= r_shift(d_width-1);
            -- Shift left
            r_shift <= r_shift(d_width-2 DOWNTO 0) & '0';
          ELSE
            -- Delay bit and padding bits
            sd_tx <= '0';
          END IF;
        END IF;
        
        IF beamformer_valid = '1' THEN
            l_buffer <= l_data_tx;
            r_buffer <= r_data_tx;
            buffer_valid <= '1';
        END IF;
        
  ------------------------------------------------------------------------
  -- A processed sample may arrive somewhere in the middle of an I2S frame.
  -- Buffer it until the next frame boundary.
  ------------------------------------------------------------------------
    ELSE
        IF beamformer_valid = '1' THEN
            l_buffer <= l_data_tx;
            r_buffer <= r_data_tx;
            buffer_valid <= '1';
        END IF;
    END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE;