library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.FFT_package.ALL;

entity FFT_32_tb is
end FFT_32_tb;

architecture tb of FFT_32_tb is

    -- Clock: 100 MHz (period = 10 ns)
    constant CLK_PERIOD    : time    := 10 ns;
    -- 50 kHz sample rate => valid every 20 µs = 2000 clock cycles
    constant VALID_PERIOD  : integer := 2000;

    signal clk             : std_logic := '0';
    signal reset_n         : std_logic := '0';
    signal data_valid      : std_logic := '0';
    signal data_valid_out  : std_logic;
    signal X_in            : complex_array;
    signal X_out           : sample;

    -- Natural-order cosine frame (781.25 Hz, 1 cycle over 64 samples)
    function generate_cosine_frame return complex_array is
        variable ret      : complex_array;
        variable phase    : real;
        constant MAX_VAL  : real := 2.0**23 - 1.0;   -- 8388607.0
        constant MIN_VAL  : real := -2.0**23;         -- -8388608.0
        variable val_real : real;
        variable int_val  : integer;
    begin
        for i in 0 to 31 loop
            phase := 2.0 * MATH_PI * real(i) / 32.0;
            val_real := cos(phase) * MAX_VAL;
            -- Clamp to 24-bit signed range
            if val_real > MAX_VAL then
                int_val := integer(MAX_VAL);
            elsif val_real < MIN_VAL then
                int_val := integer(MIN_VAL);
            else
                int_val := integer(round(val_real));
            end if;
            ret(i).Real := to_signed(int_val, 8);
            ret(i).Imag := to_signed(0, 8);
        end loop;
        return ret;
    end function;

    constant NATURAL_COSINE : complex_array := generate_cosine_frame;

    -- Reorder natural frame to DIT (bit-reversed) order using DIT_INDEX from package
    function reorder_to_dit(input_frame : complex_array) return complex_array is
        variable result : complex_array;
    begin
        for i in 0 to 31 loop
            result(i) := input_frame(DIT_INDEX(i));
        end loop;
        return result;
    end function;

    constant DIT_COSINE_FRAME : complex_array := reorder_to_dit(NATURAL_COSINE);

begin

    ----------------------------------------------------------------------------
    -- Clock and reset generation
    ----------------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;
    reset_n <= '0', '1' after 5 * CLK_PERIOD;

    ----------------------------------------------------------------------------
    -- data_valid strobe: one cycle high every VALID_PERIOD clock cycles
    ----------------------------------------------------------------------------
    p_valid : process(clk)
        variable v_count : integer := 0;
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                data_valid <= '0';
                v_count := 0;
            else
                if v_count = VALID_PERIOD - 1 then
                    data_valid <= '1';
                    v_count := 0;
                else
                    data_valid <= '0';
                    v_count := v_count + 1;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Apply DIT-ordered cosine frame whenever data_valid is active
    ----------------------------------------------------------------------------
    p_input : process(clk)
    begin
        if rising_edge(clk) then
            if data_valid = '1' then
                X_in <= DIT_COSINE_FRAME;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Device Under Test
    ----------------------------------------------------------------------------
    uut : entity work.FFT_32
        port map (
            Clk            => clk,
            Reset_n        => reset_n,
            X_in           => X_in,
            X_out          => X_out,
            data_valid     => data_valid,
            data_valid_out => data_valid_out
        );

    
end tb;