library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.FFT_package.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP_BeamformAnalysis is
Port ( Clk : in STD_LOGIC;
       Reset_n : in STD_LOGIC;
       Angle : in STD_LOGIC_VECTOR ( 7 downto 0 );
       Test_Enable : in STD_LOGIC;
       Mic_Select  : in STD_LOGIC_VECTOR(2 downto 0);
       --    Test_Enable = 0  -> normaler Beamformer
       --    Test_Enable = 1  -> Mikrofon-Testmodus
       --    Mic_Select = 000 -> Mic 1
       --    Mic_Select = 001 -> Mic 2
       --    Mic_Select = 010 -> Mic 3
       --    Mic_Select = 011 -> Mic 4
       --    Mic_Select = 100 -> Mic 5
       i2s_sd_tx : out STD_LOGIC;
       mic_bclk : out STD_LOGIC;
       mic_bclk_PMOD : out STD_LOGIC;
       mic_dout_12 : in STD_LOGIC;
       mic_dout_34 : in STD_LOGIC;
       mic_dout_5 : in STD_LOGIC;
       mic_lrcl : out STD_LOGIC;
       mclk: out STD_LOGIC; -- I2S Pmod Mclk -> 25,6Mhz
       mic_lrcl_PMOD : out STD_LOGIC;

       -- VGA
       VGA_Fast_Update : in STD_LOGIC;
       hsync : out STD_LOGIC;
       vsync : out STD_LOGIC;
       red   : out STD_LOGIC_VECTOR(3 downto 0);
       green : out STD_LOGIC_VECTOR(3 downto 0);
       blue  : out STD_LOGIC_VECTOR(3 downto 0);
       
       Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0); -- Anodensignale
       LED_out : out STD_LOGIC_VECTOR (6 downto 0) -- Kathodenmuster 
);
end TOP_BeamformAnalysis;

architecture Behavioral of TOP_BeamformAnalysis is


-- Signals
signal fft_out: sample := (others => (others => '0'));
signal fft_valid, fft_en,das_valid, clk_25m6: std_logic;
signal das_audio: std_logic_vector(23 downto 0);
-- Internal i2s signals
signal mic_bclk_internal,mic_lrcl_internal : STD_LOGIC;


-- Mark it for debug
attribute MARK_DEBUG : string;
attribute MARK_DEBUG of das_audio : signal is "TRUE";
attribute MARK_DEBUG of das_valid : signal is "TRUE";
--attribute MARK_DEBUG of i2s_sd_tx : signal is "TRUE";
--attribute MARK_DEBUG of fft_out : signal is "TRUE";


-- Components

-- Beamforming and transceiver
component Top_Beamformer is
port (
    Angle : in STD_LOGIC_VECTOR ( 7 downto 0 );
    Clk : in STD_LOGIC;
    clk_25m6: out std_logic;
    Reset : in STD_LOGIC;
    Test_Enable : in STD_LOGIC;
    Mic_Select  : in STD_LOGIC_VECTOR(2 downto 0);
    i2s_sd_tx : out STD_LOGIC;
    mic_bclk : out STD_LOGIC;
    mic_dout_12 : in STD_LOGIC;
    mic_dout_34 : in STD_LOGIC;
    mic_dout_5 : in STD_LOGIC;
    mic_lrcl : out STD_LOGIC;
    das_valid: out std_logic;
    audio_out_DAS: out std_logic_vector(23 downto 0);
    Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0); -- Anodensignale
    LED_out : out STD_LOGIC_VECTOR (6 downto 0) -- Kathodenmuster 
  );
end component;

--VGA display spectrum
component vga_spectrum is
    Port (
        clk_25m6 : in  STD_LOGIC;
        reset    : in  STD_LOGIC;  -- active high reset

        -- 32 displayed FFT bins, usually FFT bins 1..32, already scaled to pixels.
        -- Values above PLOT_H are clipped internally.
        bin01 : in unsigned(7 downto 0);
        bin02 : in unsigned(7 downto 0);
        bin03 : in unsigned(7 downto 0);
        bin04 : in unsigned(7 downto 0);
        bin05 : in unsigned(7 downto 0);
        bin06 : in unsigned(7 downto 0);
        bin07 : in unsigned(7 downto 0);
        bin08 : in unsigned(7 downto 0);
        bin09 : in unsigned(7 downto 0);
        bin10 : in unsigned(7 downto 0);
        bin11 : in unsigned(7 downto 0);
        bin12 : in unsigned(7 downto 0);
        bin13 : in unsigned(7 downto 0);
        bin14 : in unsigned(7 downto 0);
        bin15 : in unsigned(7 downto 0);
        bin16 : in unsigned(7 downto 0);
        bin17 : in unsigned(7 downto 0);
        bin18 : in unsigned(7 downto 0);
        bin19 : in unsigned(7 downto 0);
        bin20 : in unsigned(7 downto 0);
        bin21 : in unsigned(7 downto 0);
        bin22 : in unsigned(7 downto 0);
        bin23 : in unsigned(7 downto 0);
        bin24 : in unsigned(7 downto 0);
        bin25 : in unsigned(7 downto 0);
        bin26 : in unsigned(7 downto 0);
        bin27 : in unsigned(7 downto 0);
        bin28 : in unsigned(7 downto 0);
        bin29 : in unsigned(7 downto 0);
        bin30 : in unsigned(7 downto 0);
        bin31 : in unsigned(7 downto 0);
        bin32 : in unsigned(7 downto 0);

        fps_fast : in  STD_LOGIC;
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        red   : out STD_LOGIC_VECTOR(3 downto 0);
        green : out STD_LOGIC_VECTOR(3 downto 0);
        blue  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end component;

-- FFT

component FFT_TOP is
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
end component;

begin

Top_Beamformer_0: component Top_Beamformer 
port map(
    Angle => Angle,
    Clk => Clk,
    clk_25m6=>clk_25m6 ,
    Reset => Reset_n,
    Test_Enable => Test_Enable,
    Mic_Select  => Mic_Select,
    i2s_sd_tx => i2s_sd_tx,
    mic_bclk => mic_bclk_internal,
    mic_dout_12 => mic_dout_12,
    mic_dout_34 => mic_dout_34,
    mic_dout_5 => mic_dout_5,
    mic_lrcl => mic_lrcl_internal,
    das_valid=> das_valid,
    audio_out_DAS=> das_audio,  
    Anode_Activate => Anode_Activate, -- Anodensignale
    LED_out => LED_out -- Kathodenmuster 
  );

FFT_0: component FFT_TOP

 Port map( Clk => clk_25m6,
           Reset_n => Reset_n,
           das_valid=> das_valid, -- Is our sample_valid_out from beamformer
           das_audio=> das_audio,
           X_out => fft_out, -- Betragsquadrat out
           fft_en     => fft_en, -- Held high after first pass through
           data_valid_s2p_out=> open,

           valid_out => open); -- Gives out valid after we passed through all stages

Spectrum_Display: component vga_spectrum 
    Port map (
        clk_25m6 => clk_25m6,
        reset    => Reset_n,  -- active low reset

        -- 32 displayed FFT bins, usually FFT bins 1..32, already scaled to pixels.
        -- Values above PLOT_H are clipped internally.
        bin01 => UNSIGNED(fft_out(0)),
        bin02 => unsigned(fft_out(1)),
        bin03 => unsigned(fft_out(2)),
        bin04 => unsigned(fft_out(3)),
        bin05 => unsigned(fft_out(4)),
        bin06 => unsigned(fft_out(5)),
        bin07 => unsigned(fft_out(6)),
        bin08 => unsigned(fft_out(7)),
        bin09 => unsigned(fft_out(8)),
        bin10 => unsigned(fft_out(9)),
        bin11 => unsigned(fft_out(10)),
        bin12 => unsigned(fft_out(11)),
        bin13 => unsigned(fft_out(12)),
        bin14 => unsigned(fft_out(13)),
        bin15 => unsigned(fft_out(14)),
        bin16 => unsigned(fft_out(15)),
        bin17 => unsigned(fft_out(16)),
        bin18 => unsigned(fft_out(17)),
        bin19 => unsigned(fft_out(18)),
        bin20 => unsigned(fft_out(19)),
        bin21 => unsigned(fft_out(20)),
        bin22 => unsigned(fft_out(21)),
        bin23 => unsigned(fft_out(22)),
        bin24 => unsigned(fft_out(23)),
        bin25 => unsigned(fft_out(24)),
        bin26 => unsigned(fft_out(25)),
        bin27 => unsigned(fft_out(26)),
        bin28 => unsigned(fft_out(27)),
        bin29 => unsigned(fft_out(28)),
        bin30 => unsigned(fft_out(29)),
        bin31 => unsigned(fft_out(30)),
        bin32 => unsigned(fft_out(31)),

        fps_fast => VGA_Fast_Update,
        hsync => hsync,
        vsync => vsync,
        red   => red,
        green => green,
        blue  => blue
    );
      
mclk <= clk_25m6;

mic_lrcl <= mic_lrcl_internal;
mic_lrcl_PMOD <= mic_lrcl_internal;

mic_bclk <= mic_bclk_internal;
mic_bclk_PMOD <= mic_bclk_internal;

end Behavioral;