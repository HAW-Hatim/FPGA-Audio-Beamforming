library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.FFT_package.ALL;

entity tb_serial_to_parallel is
end tb_serial_to_parallel;

architecture tb of tb_serial_to_parallel is

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
    -- Stimulus: 68 samples of a 4 kHz sine wave (top 8 bits meaningful)
    ----------------------------------------------------------------------------
    p_stim : process
        variable k        : integer := 0;
        variable phase    : real;
        variable sin_val  : real;
        variable int_val  : integer;
        constant FS       : real := 50000.0;
        constant FTONE    : real := 4000.0;
        -- Full-scale 24-bit amplitude => after >>16, we get full 8-bit range
        constant AMPL     : real := 2.0**23 - 1.0;   -- 8,388,607
        constant LAST_SAMPLE : integer := 67;
    begin
        -- Wait for reset to finish
        wait until reset_n = '1';
        wait until rising_edge(clk);   -- align with clock

        -- Generate exactly 68 samples (0 .. 67)
        while k <= LAST_SAMPLE loop
            -- Compute the audio sample (natural order)
            phase   := 2.0 * MATH_PI *  real(k mod 32) / 32.0;
            sin_val := sin(phase) * AMPL;
            int_val := integer(round(sin_val));
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
        end loop;

        -- After the last sample, wait a little to observe final outputs
        wait for 20 * CLK_PERIOD;
        report "Simulation finished (68 samples sent). Check waveform for peaks at bins 2-3.";
        std.env.stop;
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
    -- Optional: print whenever a new FFT frame is valid
    ----------------------------------------------------------------------------
    p_report : process(clk)
    begin
        if rising_edge(clk) then
            if valid_out = '1' then
                report "FFT frame valid at time " & time'image(now);
            end if;
        end if;
    end process;

end tb;