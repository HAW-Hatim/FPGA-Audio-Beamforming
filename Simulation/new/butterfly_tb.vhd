library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.FFT_package.ALL;

entity butterfly_tb is
end butterfly_tb;

architecture behavior of butterfly_tb is

    component Butterfly
        Port ( Clk     : in  STD_LOGIC;
               z1      : in  t_My_Complex_Type;
               z2      : in  t_My_Complex_Type;
               Twiddle : in  t_My_Complex_Type;
               Z1_out  : out t_My_Complex_Type;
               Z2_out  : out t_My_Complex_Type );
    end component;

    -- Signals
    signal Clk     : STD_LOGIC := '0';
    signal z1      : t_My_Complex_Type;
    signal z2      : t_My_Complex_Type;
    signal Twiddle : t_My_Complex_Type;
    signal Z1_out  : t_My_Complex_Type;
    signal Z2_out  : t_My_Complex_Type;

    constant clk_period : time := 10 ns;

begin

    uut: Butterfly
        port map (
            Clk     => Clk,
            z1      => z1,
            z2      => z2,
            Twiddle => Twiddle,
            Z1_out  => Z1_out,
            Z2_out  => Z2_out
        );

    -- Clock process
    clk_process : process
    begin
        Clk <= '0';
        wait for clk_period/2;
        Clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus
    stim_proc : process
    begin
        -- Initial values (not strictly needed, but safe)
        z1      <= (Real => (others => '0'), Imag => (others => '0'));
        z2      <= (Real => (others => '0'), Imag => (others => '0'));
        Twiddle <= (Real => (others => '0'), Imag => (others => '0'));
        wait for clk_period;

        -- Apply test: z1 = -0.5, z2 = 0, Twiddle = 1.0
        -- Q1.23 representation:
        --   -0.5  = "110000000000000000000000"  (0xC00000)
        --    1.0  = "011111111111111111111111"  (0x7FFFFF)
        z1      <= (Real => (others => '0'), Imag => (others => '0'));
        z2      <= (Real => (others => '0'), Imag => (others => '0'));
        Twiddle <= (Real => "011111111111111111111111", Imag => (others => '0'));

        -- Wait for one clock so the output registers capture the result
        wait for clk_period;
        -- Z1_out and Z2_out are now valid.
        -- (You can check their values in the waveform or add a simple report)

        wait for clk_period; -- extra time for viewing
        report "Simulation finished. Check Z1_out and Z2_out in waveform."
            severity note;
        wait;
    end process;

end behavior;