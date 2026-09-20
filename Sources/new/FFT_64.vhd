library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.FFT_package.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
entity FFT_32 is
	port (
		Clk        : in  std_logic;
		Reset_n    : in  std_logic;
		X_in       : in  complex_array; -- Data in (DIT)
		X_out      : out sample;        -- Betragsquadrat out
		data_valid : in  std_logic;     -- Frequency of f_s = 50kHz
		fft_en     : out std_logic;     -- Stages full
		valid_out  : out std_logic);    -- Held high after first pass through
end FFT_32;
architecture Behavioral of FFT_32 is
	type stage_output_type is array (natural range <>) of complex_array;
	-- FFT_Stages+1 in total to have one input at index 0 and
	signal stage_output                : stage_output_type(0 to FFT_STAGES - 1); -- Calculation result (combinatorical)
	signal r_stages                    : stage_output_type(0 to FFT_STAGES - 1); -- Input of next stage (registered)
    signal r_valid_1, r_valid_2, r_valid_3, r_valid_4,r_valid_5 : std_logic;

	signal fft_ready_async, fft_valid_async, fft_ready_r : std_logic;
	-- Component (only Butterfly needed)
	component Butterfly is
		port (
			z1      : in  t_My_Complex_Type;
			z2      : in  t_My_Complex_Type;
			Z1_out  : out t_My_Complex_Type;
			Z2_out  : out t_My_Complex_Type;
			Twiddle : in  t_My_Complex_Type);
	end component;
begin
	p : process (clk, Reset_n)
	begin
		if Reset_n = '0' then
			-- Reset all our registers
			for k in 0 to FFT_STAGES - 1 loop
				r_stages(k) <= (others => (Real => (others => '0'), Imag => (others => '0')));
			end loop;
			X_out <= (others => (others => '0'));
			fft_en        <= '0';
						fft_ready_r <= '0';
										valid_out     <= '0';
		elsif rising_edge(clk) then
				r_stages(0) <= X_in;
				for k in 1 to FFT_STAGES - 1 loop
					r_stages(k) <= stage_output(k - 1);
				end loop;
				-- Output of our Betragsquadrat for spectrum
				X_out <= abs_squared(stage_output(FFT_STAGES - 1));

			r_valid_1 <= data_valid;
			r_valid_2 <= r_valid_1;
			r_valid_3 <= r_valid_2;
						r_valid_4 <= r_valid_3;
			r_valid_5 <= r_valid_4;
 
			valid_out <= r_valid_5;
            fft_en <= fft_ready_async;
            			fft_ready_r        <= fft_ready_async;
 
		end if;
	end process;
	-- combinatorical set fft_enable
	SN_enable : process (r_valid_5,fft_ready_r)
	begin
	-- Default
	fft_ready_async <= '0';
		if r_valid_5 = '1' then
		  fft_ready_async <= '1';
		  else fft_ready_async <= fft_ready_r;
		  end if;
	end process;
 
 
	-- Butterflies purely combinatorical
	-- Nested for generate loop to create our fft
	g_Stages : for i in 0 to FFT_STAGES - 1 generate
		-- 2**i -> Butterfly span
		-- j*2**(i+1) Offset for the groups
		g_groups : for j in 0 to (FFT_LENGTH/(2 ** (i + 1)) - 1) generate
			g_Butterflies : for k in 0 to 2 ** (i) - 1 generate
				Butterfly_test : component Butterfly
					port map(
						z1      => r_stages(i)(k + j * 2 ** (i + 1)),
						z2      => r_stages(i)(k + j * 2 ** (i + 1) + 2 ** i),
						Z1_out  => stage_output(i)(k + j * 2 ** (i + 1)),
						Z2_out  => stage_output(i)(k + j * 2 ** (i + 1) + 2 ** i),
						Twiddle => twiddle_factors((k * (FFT_LENGTH/(2 ** (i + 1)))) mod FFT_LENGTH)); --k*number of groups, wrap around
			end generate g_Butterflies;
		end generate g_groups;
	end generate g_Stages;
end Behavioral;