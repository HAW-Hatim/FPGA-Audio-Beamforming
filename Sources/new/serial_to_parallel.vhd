library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use work.FFT_package.all;
 
entity serial_to_parallel is
	generic (
		AUDIO_WIDTH : integer := 24);
	port (
		Clk          : in  std_logic;
		Reset_n      : in  std_logic;
		i_data_valid : in  std_logic; -- Is our sample_valid_out from beamformer
		i_data       : in  std_logic_vector(AUDIO_WIDTH - 1 downto 0);
		window_valid : out std_logic;
		o_data       : out complex_array
	);
end serial_to_parallel;
 
architecture rtl of serial_to_parallel is
	signal o_data_valid_a, r_data_valid : std_logic; -- Async output
	-- Sample indexing: 0 oldest sample, FFT_LENGTH-1 newest sample
	signal samples, samples_a : sample :=
		(others => (others => '0'));
	signal r_count    : integer range 0 to FFT_LENGTH; -- Counts till 32
	signal count_plus : integer range 0 to  FFT_LENGTH;
	-- Control fsm
	type STATES is (IDLE, FILLING, VALID_OUT_ON, VALID_OUT_OFF);
	signal State, Next_State : STATES;
begin
	p_serial2parallel : process (Clk, Reset_n)
	begin
		if (Reset_n = '0') then
			r_data_valid <= '0';
			r_count      <= 0;
			samples      <= (others => (others => '0'));
			window_valid <= '0';
			State        <= IDLE;
			o_data       <= (others => (Real => (others => '0'), Imag => (others => '0')));
		elsif (rising_edge(Clk)) then
			r_data_valid <= o_data_valid_a;
			window_valid <= r_data_valid; -- window valid one cycle later since we have a registered output
			if r_data_valid = '1' then
				DIT : for i in 0 to FFT_LENGTH - 1 loop
					o_data(i) <= (Real => signed(samples(DIT_INDEX(i))), Imag => (others => '0'));
				end loop;
			end if;
			samples <= samples_a;
			State <= Next_State;
			r_count <= count_plus;
		end if;
	end process p_serial2parallel;
 
	fsm_control_comb : process ( i_data_valid, State, r_count)
	begin
		-- Default
		Next_State <= State;
		case State is
			when IDLE => 
				o_data_valid_a          <= '0';
				Next_State              <= FILLING;
			when FILLING =>
				o_data_valid_a <= '0';
				if r_count = FFT_LENGTH then
					Next_State <= VALID_OUT_ON;
				end if;
			when VALID_OUT_ON =>
				o_data_valid_a <= '1';
				Next_State     <= VALID_OUT_OFF;
			when VALID_OUT_OFF =>
				o_data_valid_a <= '0';
				if i_data_valid = '1' then
					Next_State <= FILLING;
				end if;
		end case;
	end process;

	SN_counter : process (r_count, i_data_valid, i_data, samples)
	begin
		-- Default
		count_plus <= 0;
		samples_a <= samples;
		if i_data_valid = '1' then
		-- Gather the samples, at the beginning we do zeropadding
				if r_count       <= FFT_LENGTH - 1 then
				-- Adjusted range 8 Bits from the middle bit 16 to 9 (index 15 to 8)
					samples_a(r_count) <= std_logic_vector(resize(shift_right(signed(i_data), DATA_WIDTH), DATA_WIDTH));
				else
				    samples_a(0) <= std_logic_vector(resize(shift_right(signed(i_data), DATA_WIDTH), DATA_WIDTH));
				end if;
		  -- When we are at the 32nd sample we write that sample into position one#
		  -- hence we need to write to index 1 to not overwrite one sample
		  if r_count = 32 then
		      count_plus <= 1;
		  else
		  count_plus <= r_count + 1;
		  end if;
		else
				count_plus <= r_count;
		end if;
	end process;
end rtl;