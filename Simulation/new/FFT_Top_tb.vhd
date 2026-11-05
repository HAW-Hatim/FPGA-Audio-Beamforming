library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.FFT_package.ALL;

entity FFT_Top_tb is
end FFT_Top_tb;

architecture tb of FFT_Top_tb is

    constant CLK_PERIOD   : time    := 10 ns;
    constant VALID_PERIOD : integer := 2000;   -- 2000 * 10 ns = 20 us (50 kHz)

    signal clk        : std_logic := '0';
    signal reset_n    : std_logic := '0';
    signal das_valid  : std_logic := '0';
    signal das_audio  : std_logic_vector(23 downto 0);
    signal X_out      : sample;
    signal valid_out, fft_en, data_valid_s2p : std_logic;
begin

    ----------------------------------------------------------------------------
    -- Clock and reset
    ----------------------------------------------------------------------------
    clk      <= not clk after CLK_PERIOD/2;
    reset_n  <= '0', '1' after 5 * CLK_PERIOD;

    ----------------------------------------------------------------------------
    -- Stimulus: 50 kHz sample strobe + synchronous sine wave
    -- (no one-cycle delay - das_audio is stable when das_valid is high)
    ----------------------------------------------------------------------------
    p_stim : process
        variable k        : integer := 0;
        variable phase    : real;
        variable sin_val  : real;
        variable int_val  : integer;
        constant FS       : real := 50000.0;
        -- Change AMPL to 18000.0 to match the observed peak value
        constant AMPL     : real := 8192.0;    -- was 2.0**23 - 1.0
        constant N        : integer := 32;      -- one sine wave cycle per N samples
        -- Note: with N=32, the tone frequency is FS/N = 1562.5 Hz.
        -- If you need a 4 kHz tone, set N = 12 or 13 (e.g. 50000/12 ≈ 4167 Hz)
    begin
        -- Wait for reset to finish
        wait until reset_n = '1';
        wait until rising_edge(clk);   -- align with clock

        -- Generate samples forever
        loop
            -- Compute the next audio sample (natural order)
            phase   := 2.0 * MATH_PI * real(k mod N) / real(N); 
            sin_val := cos(phase) * AMPL;
            int_val := integer(round(sin_val));
            -- Clamping not strictly needed with AMPL=18000, kept for safety
            if int_val > 8388607 then
                int_val := 8388607;
            elsif int_val < -8388608 then
                int_val := -8388608;
            end if;

            -- Drive das_audio and das_valid together on the next rising edge
            wait until rising_edge(clk);
            das_valid <= '1';
            das_audio <= std_logic_vector(to_signed(int_val, 24));

            -- Next cycle: deassert das_valid
            wait until rising_edge(clk);
            das_valid <= '0';

            -- Wait for the remaining VALID_PERIOD-2 cycles
            for i in 1 to VALID_PERIOD-2 loop
                wait until rising_edge(clk);
            end loop;

            k := k + 1;
            if k = N then
                k := 0;
            end if;
        end loop;
    end process;

    ----------------------------------------------------------------------------
    -- DUT
    ----------------------------------------------------------------------------
    uut : entity work.FFT_Top
        port map (
            Clk       => clk,
            Reset_n   => reset_n,
            das_valid => das_valid,
            das_audio => das_audio,
            X_out     => X_out,
            fft_en    => fft_en,
            data_valid_s2p_out => data_valid_s2p, -- debug

            valid_out => valid_out
        );

    ----------------------------------------------------------------------------
    -- Simulation control
    ----------------------------------------------------------------------------
    p_watch : process
    begin
        wait until rising_edge(fft_en);
        report "First FFT frame completed." severity note;
        wait until rising_edge(valid_out);
        report "Second FFT frame completed." severity note;
        wait for 20 * CLK_PERIOD;
        report "Simulation finished. Inspect waveform for peaks around bins 2-3.";
        std.env.stop;
    end process;

end tb;