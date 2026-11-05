library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.FFT_package.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- "das" refers to delay-and-sum
entity FFT_TOP is
generic(
    AUDIO_WIDTH              : integer:=24);
Port ( Clk : in STD_LOGIC;
       Reset_n : in STD_LOGIC;
       das_valid: in  std_logic; -- Is our sample_valid_out from beamformer
       das_audio: in  std_logic_vector(AUDIO_WIDTH-1 downto 0);
       X_out : out sample; -- Betragsquadrat out
       fft_en     : out std_logic; -- Held high after first pass through
       data_valid_s2p_out: out STD_LOGIC;
       valid_out : out STD_LOGIC); -- Gives out valid after we passed through all stages
end FFT_TOP;

architecture Behavioral of FFT_TOP is

-- Components

-- Calulcates FFT
component FFT_32 is
    Port ( Clk : in STD_LOGIC;
           Reset_n : in STD_LOGIC;
           X_in : in complex_array; -- Data in (DIT)
           X_out : out sample; -- Betragsquadrat out
           data_valid : in STD_LOGIC; -- Frequency of f_s = 50kHz
           fft_en     : out std_logic; 
           valid_out : out STD_LOGIC); -- Held high after first pass through
end component;

-- Serial to parallel data
component serial_to_parallel is
port (
  Clk                          : in  std_logic;
  Reset_n                         : in  std_logic;
  i_data_valid                     : in  std_logic; -- Is our sample_valid_out from beamformer
  i_data                         : in  std_logic_vector(AUDIO_WIDTH-1 downto 0);
  window_valid                   : out std_logic;
  o_data                         : out complex_array);
end component;


-------------
-- SIGNALS --
-------------

signal X_IN: complex_array;
signal data_valid_s2p: STD_LOGIC;

attribute MARK_DEBUG : string;
attribute MARK_DEBUG of X_IN : signal is "TRUE";
 
begin

FFT_0 : entity work.FFT_32
        port map (
            Clk            => Clk,
            Reset_n        => Reset_n,
            X_in           => X_in,
            X_out          => X_out,
            data_valid     => data_valid_s2p,
            fft_en    => fft_en,
            valid_out => valid_out
        );
        
S2P_0 : entity work.serial_to_parallel
 generic map (AUDIO_WIDTH => AUDIO_WIDTH)
        port map (
            Clk       => Clk,
            Reset_n     => Reset_n,
            i_data_valid  => das_valid,
            i_data      => das_audio,
            window_valid=> data_valid_s2p,
            o_data      => X_in
        );
        
data_valid_s2p_out <= data_valid_s2p;

end Behavioral;
