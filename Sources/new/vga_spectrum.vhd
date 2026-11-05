----------------------------------------------------------------------------------
-- Module Name: vga_spectrum
-- Description:
--   VGA output for a 32 (mirrored)/64-point real FFT spectrum display.
--   Displays bins 1..32 as a bar chart with axes, ticks and labels.
--
-- Notes:
--   - Input clock is expected to be ~25.6 MHz.
--   - VGA timing is 640x480 style timing. With 25.6 MHz pixel clock the refresh
--     rate is about 60.95 Hz instead of the classical 59.94/60 Hz.
--   - bin values are 8-bit FFT magnitudes. They are scaled to the plot height
--     by scale_8bit_to_plot() and clipped by clip_height().
--   - RGB output is 4 bit per color.
-- Main structure:
--   1) VGA timing counters generate h_count/v_count and sync pulses.
--   2) FFT bin inputs are copied into a frame-stable display buffer.
--   3) The pixel renderer decides the color of each pixel for grid, bars, axes,
--      ticks and text labels.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_spectrum is
    Port (
        clk_25m6 : in  STD_LOGIC;
        reset    : in  STD_LOGIC;  -- active low reset

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

        -- Display update-rate select. The VGA scanout always runs continuously,
        -- but the displayed FFT values are refreshed either every frame or every
        -- 10 frames.
        fps_fast : in STD_LOGIC;   -- 0 = ~ 6 FPS, 1 = ~ 61 FPS

        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        red   : out STD_LOGIC_VECTOR(3 downto 0);
        green : out STD_LOGIC_VECTOR(3 downto 0);
        blue  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end vga_spectrum;

architecture Behavioral of vga_spectrum is

    --------------------------------------------------------------------
    -- VGA timing, 640x480 style
    --------------------------------------------------------------------
    constant H_VISIBLE : integer := 640;
    constant H_FRONT   : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BACK    : integer := 48;
    constant H_TOTAL   : integer := H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    constant V_VISIBLE : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BACK    : integer := 33;
    constant V_TOTAL   : integer := V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    --------------------------------------------------------------------
    -- Plot geometry
    -- PLOT_X0/PLOT_Y0 define the upper-left corner of the graph area.
    -- PLOT_X1/PLOT_Y1 define the lower-right corner. The chart is drawn inside
    -- this rectangle, while labels are placed around it.
    --------------------------------------------------------------------
    constant PLOT_X0 : integer := 70;
    constant PLOT_X1 : integer := 620;
    constant PLOT_Y0 : integer := 40;
    constant PLOT_Y1 : integer := 420;
    constant PLOT_W  : integer := PLOT_X1 - PLOT_X0 + 1;
    constant PLOT_H  : integer := PLOT_Y1 - PLOT_Y0 + 1;

    constant N_BINS       : integer := 32;
    constant BAR_SLOT_W   : integer := 17; -- 32 * 17 = 544 px, fits inside plot width 551
    constant BAR_DRAW_W   : integer := 13; -- 13 px bar, 4 px gap
    constant BAR_AREA_W   : integer := N_BINS * BAR_SLOT_W;
    constant BAR_X_OFFSET : integer := (PLOT_W - BAR_AREA_W) / 2;

    --------------------------------------------------------------------
    -- Aktualisierungsrate der angezeigten Daten
    -- fps_fast = '0': ~6 FPS
    -- fps_fast = '1': ~61 FPS
    --------------------------------------------------------------------
    constant FRAME_DIV_SLOW : integer := 10;
    
    signal frame_counter : integer range 0 to FRAME_DIV_SLOW-1 := 0;
    
    signal fps_fast_meta : STD_LOGIC := '0';
    signal fps_fast_sync : STD_LOGIC := '0';
    --------------------------------------------------------------------
    -- Pixel counters
    --------------------------------------------------------------------
    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

    signal r, g, b : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

    ----------------------------------------------------------------------------
    -- Frame-stable display buffer
    -- The incoming FFT bins may change at any time. These display registers are
    -- only updated at the beginning of selected VGA frames, so every bar remains
    -- stable during a full frame scan and no half-updated spectrum is displayed.
    ----------------------------------------------------------------------------
    signal disp_bin01 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin02 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin03 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin04 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin05 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin06 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin07 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin08 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin09 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin10 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin11 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin12 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin13 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin14 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin15 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin16 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin17 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin18 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin19 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin20 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin21 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin22 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin23 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin24 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin25 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin26 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin27 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin28 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin29 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin30 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin31 : unsigned(7 downto 0) := (others => '0');
    signal disp_bin32 : unsigned(7 downto 0) := (others => '0');

    --------------------------------------------------------------------
    -- Colors, 12-bit RGB, 4 bit per channel
    --------------------------------------------------------------------
    constant BLACK_R : STD_LOGIC_VECTOR(3 downto 0) := x"0";
    constant BLACK_G : STD_LOGIC_VECTOR(3 downto 0) := x"0";
    constant BLACK_B : STD_LOGIC_VECTOR(3 downto 0) := x"0";

    constant WHITE_R : STD_LOGIC_VECTOR(3 downto 0) := x"F";
    constant WHITE_G : STD_LOGIC_VECTOR(3 downto 0) := x"F";
    constant WHITE_B : STD_LOGIC_VECTOR(3 downto 0) := x"F";

    constant GRID_R  : STD_LOGIC_VECTOR(3 downto 0) := x"3";
    constant GRID_G  : STD_LOGIC_VECTOR(3 downto 0) := x"3";
    constant GRID_B  : STD_LOGIC_VECTOR(3 downto 0) := x"3";

    constant BAR_R   : STD_LOGIC_VECTOR(3 downto 0) := x"0";
    constant BAR_G   : STD_LOGIC_VECTOR(3 downto 0) := x"D";
    constant BAR_B   : STD_LOGIC_VECTOR(3 downto 0) := x"4";

    constant TEXT_R  : STD_LOGIC_VECTOR(3 downto 0) := x"F";
    constant TEXT_G  : STD_LOGIC_VECTOR(3 downto 0) := x"F";
    constant TEXT_B  : STD_LOGIC_VECTOR(3 downto 0) := x"0";

    --------------------------------------------------------------------
    -- Helper functions
    --------------------------------------------------------------------

    -- Limit a computed bar height to the drawable plot range.
    -- This protects the renderer from negative values or values above PLOT_H.
    function clip_height(value : integer) return integer is
    begin
        if value < 0 then
            return 0;
        elsif value > PLOT_H then
            return PLOT_H;
        else
            return value;
        end if;
    end function;

    -- Scale one 8-bit bin value to a vertical bar height.
    --
    -- The multiplication uses unsigned arithmetic. The selected output bits act
    -- like a right shift, avoiding division hardware in the synthesized design.
    -- The current bit slice intentionally adds gain compared with /256 so that
    -- smaller FFT magnitudes remain visible.
    function scale_8bit_to_plot(
        value : unsigned(7 downto 0)
    ) return integer is
        variable mult : unsigned(16 downto 0);
    begin
        -- value: 0..255
        -- PLOT_H = 381
        -- Ergebnis ungefähr: value * 381 / 256
        -- mult(16 downto 8) entspricht >> 8
        -- mult(16 downto 5) entspricht Verstärkung 8
        mult := value * to_unsigned(PLOT_H, 9);
    
        return to_integer(mult(16 downto 5));
    end function;


    -- 5x7 bitmap font. cx selects a column 0..4 and cy selects a row 0..6.
    -- The function returns true when that character pixel should be lit.
    -- Characters not defined return blank.
    function font5x7(ch : character; cx : integer; cy : integer) return boolean is
        variable row : std_logic_vector(4 downto 0);
    begin
        row := "00000";

        case ch is
            when '0' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10001";
                    when 2 => row := "10011";
                    when 3 => row := "10101";
                    when 4 => row := "11001";
                    when 5 => row := "10001";
                    when 6 => row := "01110";
                    when others => row := "00000";
                end case;
            when '1' =>
                case cy is
                    when 0 => row := "00100";
                    when 1 => row := "01100";
                    when 2 => row := "00100";
                    when 3 => row := "00100";
                    when 4 => row := "00100";
                    when 5 => row := "00100";
                    when 6 => row := "01110";
                    when others => row := "00000";
                end case;
            when '2' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10001";
                    when 2 => row := "00001";
                    when 3 => row := "00010";
                    when 4 => row := "00100";
                    when 5 => row := "01000";
                    when 6 => row := "11111";
                    when others => row := "00000";
                end case;
            when '3' =>
                case cy is
                    when 0 => row := "11110";
                    when 1 => row := "00001";
                    when 2 => row := "00001";
                    when 3 => row := "01110";
                    when 4 => row := "00001";
                    when 5 => row := "00001";
                    when 6 => row := "11110";
                    when others => row := "00000";
                end case;
            when '4' =>
                case cy is
                    when 0 => row := "00010";
                    when 1 => row := "00110";
                    when 2 => row := "01010";
                    when 3 => row := "10010";
                    when 4 => row := "11111";
                    when 5 => row := "00010";
                    when 6 => row := "00010";
                    when others => row := "00000";
                end case;
            when '5' =>
                case cy is
                    when 0 => row := "11111";
                    when 1 => row := "10000";
                    when 2 => row := "10000";
                    when 3 => row := "11110";
                    when 4 => row := "00001";
                    when 5 => row := "00001";
                    when 6 => row := "11110";
                    when others => row := "00000";
                end case;
            when '6' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10000";
                    when 2 => row := "10000";
                    when 3 => row := "11110";
                    when 4 => row := "10001";
                    when 5 => row := "10001";
                    when 6 => row := "01110";
                    when others => row := "00000";
                end case;
            when '7' =>
                case cy is
                    when 0 => row := "11111";
                    when 1 => row := "00001";
                    when 2 => row := "00010";
                    when 3 => row := "00100";
                    when 4 => row := "01000";
                    when 5 => row := "01000";
                    when 6 => row := "01000";
                    when others => row := "00000";
                end case;
            when '8' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "01110";
                    when 4 => row := "10001";
                    when 5 => row := "10001";
                    when 6 => row := "01110";
                    when others => row := "00000";
                end case;
            when '9' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "01111";
                    when 4 => row := "00001";
                    when 5 => row := "00001";
                    when 6 => row := "01110";
                    when others => row := "00000";
                end case;
            when 'A' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "11111";
                    when 4 => row := "10001";
                    when 5 => row := "10001";
                    when 6 => row := "10001";
                    when others => row := "00000";
                end case;
			when 'C' =>
				case cy is
					when 0 => row := "01110";
					when 1 => row := "10001";
					when 2 => row := "10000";
					when 3 => row := "10000";
					when 4 => row := "10000";
					when 5 => row := "10001";
					when 6 => row := "01110";
					when others => row := "00000";
				end case;
            when 'E' =>
                case cy is
                    when 0 => row := "11111";
                    when 1 => row := "10000";
                    when 2 => row := "10000";
                    when 3 => row := "11110";
                    when 4 => row := "10000";
                    when 5 => row := "10000";
                    when 6 => row := "11111";
                    when others => row := "00000";
                end case;
            when 'F' =>
                case cy is
                    when 0 => row := "11111";
                    when 1 => row := "10000";
                    when 2 => row := "10000";
                    when 3 => row := "11110";
                    when 4 => row := "10000";
                    when 5 => row := "10000";
                    when 6 => row := "10000";
                    when others => row := "00000";
                end case;
            when 'G' =>
                case cy is
                    when 0 => row := "01110";
                    when 1 => row := "10001";
                    when 2 => row := "10000";
                    when 3 => row := "10111";
                    when 4 => row := "10001";
                    when 5 => row := "10001";
                    when 6 => row := "01110";
                    when others => row := "00000";
                end case;
            when 'H' =>
                case cy is
                    when 0 => row := "10001";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "11111";
                    when 4 => row := "10001";
                    when 5 => row := "10001";
                    when 6 => row := "10001";
                    when others => row := "00000";
                end case;
            when 'K' =>
                case cy is
                    when 0 => row := "10001";
                    when 1 => row := "10010";
                    when 2 => row := "10100";
                    when 3 => row := "11000";
                    when 4 => row := "10100";
                    when 5 => row := "10010";
                    when 6 => row := "10001";
                    when others => row := "00000";
                end case;
            when 'M' =>
                case cy is
                    when 0 => row := "10001";
                    when 1 => row := "11011";
                    when 2 => row := "10101";
                    when 3 => row := "10101";
                    when 4 => row := "10001";
                    when 5 => row := "10001";
                    when 6 => row := "10001";
                    when others => row := "00000";
                end case;
			when 'O' =>
				case cy is
					when 0 => row := "01110";
					when 1 => row := "10001";
					when 2 => row := "10001";
					when 3 => row := "10001";
					when 4 => row := "10001";
					when 5 => row := "10001";
					when 6 => row := "01110";
					when others => row := "00000";
				end case;
            when 'P' =>
                case cy is
                    when 0 => row := "11110";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "11110";
                    when 4 => row := "10000";
                    when 5 => row := "10000";
                    when 6 => row := "10000";
                    when others => row := "00000";
                end case;
			when 'Q' =>
				case cy is
					when 0 => row := "01110";
					when 1 => row := "10001";
					when 2 => row := "10001";
					when 3 => row := "10001";
					when 4 => row := "10101";
					when 5 => row := "10010";
					when 6 => row := "01101";
					when others => row := "00000";
				end case;
            when 'R' =>
                case cy is
                    when 0 => row := "11110";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "11110";
                    when 4 => row := "10100";
                    when 5 => row := "10010";
                    when 6 => row := "10001";
                    when others => row := "00000";
                end case;
            when 'S' =>
                case cy is
                    when 0 => row := "01111";
                    when 1 => row := "10000";
                    when 2 => row := "10000";
                    when 3 => row := "01110";
                    when 4 => row := "00001";
                    when 5 => row := "00001";
                    when 6 => row := "11110";
                    when others => row := "00000";
                end case;
            when 'T' =>
                case cy is
                    when 0 => row := "11111";
                    when 1 => row := "00100";
                    when 2 => row := "00100";
                    when 3 => row := "00100";
                    when 4 => row := "00100";
                    when 5 => row := "00100";
                    when 6 => row := "00100";
                    when others => row := "00000";
                end case;
			when 'U' =>
				case cy is
					when 0 => row := "10001";
					when 1 => row := "10001";
					when 2 => row := "10001";
					when 3 => row := "10001";
					when 4 => row := "10001";
					when 5 => row := "10001";
					when 6 => row := "01110";
					when others => row := "00000";
				end case;
            when 'W' =>
                case cy is
                    when 0 => row := "10001";
                    when 1 => row := "10001";
                    when 2 => row := "10001";
                    when 3 => row := "10101";
                    when 4 => row := "10101";
                    when 5 => row := "10101";
                    when 6 => row := "01010";
                    when others => row := "00000";
                end case;
            when 'Y' =>
                case cy is
                    when 0 => row := "10001";
                    when 1 => row := "10001";
                    when 2 => row := "01010";
                    when 3 => row := "00100";
                    when 4 => row := "00100";
                    when 5 => row := "00100";
                    when 6 => row := "00100";
                    when others => row := "00000";
                end case;
            when 'Z' =>
                case cy is
                    when 0 => row := "11111";
                    when 1 => row := "00001";
                    when 2 => row := "00010";
                    when 3 => row := "00100";
                    when 4 => row := "01000";
                    when 5 => row := "10000";
                    when 6 => row := "11111";
                    when others => row := "00000";
                end case;
            when '%' =>
                case cy is
                    when 0 => row := "11001";
                    when 1 => row := "11010";
                    when 2 => row := "00100";
                    when 3 => row := "01000";
                    when 4 => row := "10011";
                    when 5 => row := "00011";
                    when 6 => row := "00000";
                    when others => row := "00000";
                end case;
            when '.' =>
                case cy is
                    when 0 => row := "00000";
                    when 1 => row := "00000";
                    when 2 => row := "00000";
                    when 3 => row := "00000";
                    when 4 => row := "00000";
                    when 5 => row := "01100";
                    when 6 => row := "01100";
                    when others => row := "00000";
                end case;
            when '-' =>
                case cy is
                    when 0 => row := "00000";
                    when 1 => row := "00000";
                    when 2 => row := "00000";
                    when 3 => row := "11111";
                    when 4 => row := "00000";
                    when 5 => row := "00000";
                    when 6 => row := "00000";
                    when others => row := "00000";
                end case;
            when others =>
                row := "00000";
        end case;

        if cx < 0 or cx > 4 or cy < 0 or cy > 6 then
            return false;
        else
            -- cx=0 is left pixel, row(4) is left bit
            return row(4 - cx) = '1';
        end if;
    end function;


    -- Return true when local text coordinates px/py hit a lit pixel of one of
    -- the fixed labels. text_id selects which label string is drawn.
    function text_pixel(text_id : integer; px : integer; py : integer) return boolean is
        -- Each character: 5x7 pixels scaled by 2, plus 1 blank column scaled by 2.
        constant SCALE  : integer := 2;
        constant CHAR_W : integer := 6 * SCALE;
        constant CHAR_H : integer := 7 * SCALE;
        variable char_idx : integer;
        variable lx       : integer;
        variable ly       : integer;
        variable cx       : integer;
        variable cy       : integer;
        variable ch       : character;
    begin
        if px < 0 or py < 0 or py >= CHAR_H then
            return false;
        end if;

        char_idx := px / CHAR_W;
        lx       := px mod CHAR_W;
        ly       := py;
        cx       := lx / SCALE;
        cy       := ly / SCALE;

        if cx > 4 then
            return false; -- spacing column
        end if;

        ch := ' ';
        case text_id is
            when 0 => -- "FFT SPECTRUM"
                case char_idx is
                    when 0 => ch := 'F';
                    when 1 => ch := 'F';
                    when 2 => ch := 'T';
                    when 3 => ch := ' ';
                    when 4 => ch := 'S';
                    when 5 => ch := 'P';
                    when 6 => ch := 'E';
                    when 7 => ch := 'C'; 
                    when 8 => ch := 'T';
                    when 9 => ch := 'R';
                    when 10 => ch := 'U'; 
                    when 11 => ch := 'M';
                    when others => ch := ' ';
                end case;
            when 1 => -- "POWER %"
                case char_idx is
                    when 0 => ch := 'P';
                    when 1 => ch := 'O'; 
                    when 2 => ch := 'W';
                    when 3 => ch := 'E';
                    when 4 => ch := 'R';
                    when 5 => ch := ' ';
                    when 6 => ch := '%';
                    when others => ch := ' ';
                end case;
            when 2 => -- "FREQ KHZ"
                case char_idx is
                    when 0 => ch := 'F';
                    when 1 => ch := 'R';
                    when 2 => ch := 'E';
                    when 3 => ch := 'Q'; 
                    when 4 => ch := ' ';
                    when 5 => ch := 'K';
                    when 6 => ch := 'H';
                    when 7 => ch := 'Z';
                    when others => ch := ' ';
                end case;
            when 3 => -- "0"
                case char_idx is
                    when 0 => ch := '0';
                    when others => ch := ' ';
                end case;
            when 4 => -- "25"
                case char_idx is
                    when 0 => ch := '2';
                    when 1 => ch := '5';
                    when others => ch := ' ';
                end case;
            when 5 => -- "50"
                case char_idx is
                    when 0 => ch := '5';
                    when 1 => ch := '0';
                    when others => ch := ' ';
                end case;
            when 6 => -- "75"
                case char_idx is
                    when 0 => ch := '7';
                    when 1 => ch := '5';
                    when others => ch := ' ';
                end case;
            when 7 => -- "100"
                case char_idx is
                    when 0 => ch := '1';
                    when 1 => ch := '0';
                    when 2 => ch := '0';
                    when others => ch := ' ';
                end case;
            when 8 => -- "6.25 12.5"
                case char_idx is
                    when 0 => ch := '1';
                    when 1 => ch := '2';
                    when 2 => ch := '.';
                    when 3 => ch := '5';
                    when others => ch := ' ';
                end case;
            when 9 => -- "12.5 25.0"
                case char_idx is
                    when 0 => ch := '2';
                    when 1 => ch := '5';
                    when 2 => ch := '.';
                    when 3 => ch := '0';
                    when others => ch := ' ';
                end case;
            when 10 => -- "18.75 37.5"
                case char_idx is
                    when 0 => ch := '3';
                    when 1 => ch := '7';
                    when 2 => ch := '.';
                    when 3 => ch := '5';
                    --when 4 => ch := '5';
                    when others => ch := ' ';
                end case;
            when 11 => -- "50"
                case char_idx is
                    when 0 => ch := '5';
                    when 1 => ch := '0';
                    when others => ch := ' ';
                end case;
            when others =>
                ch := ' ';
        end case;


        return font5x7(ch, cx, cy);
    end function;

    -- Convert absolute screen coordinates to local label coordinates and test
    -- whether the current pixel belongs to the selected text label.
    function label_hit(x : integer; y : integer; x0 : integer; y0 : integer; text_id : integer) return boolean is
    begin
        return text_pixel(text_id, x - x0, y - y0);
    end function;

begin

    --------------------------------------------------------------------
    -- Pixel and line counters
    -- h_count advances every pixel clock. At the end of a line it wraps to 0
    -- and v_count advances. At the end of the frame both counters wrap.
    -- This process also synchronizes the fps_fast input.
    --------------------------------------------------------------------
    process(clk_25m6)
    begin
        if rising_edge(clk_25m6) then
            if reset = '0' then
                h_count <= 0;
                v_count <= 0;
                fps_fast_meta <= '0';
                fps_fast_sync <= '0';
            else
                fps_fast_meta <= fps_fast;
                fps_fast_sync <= fps_fast_meta;
                if h_count = H_TOTAL - 1 then
                    h_count <= 0;
                    if v_count = V_TOTAL - 1 then
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Copy input bins only at start of a VGA frame
    -- This creates a simple double-buffer behavior: the renderer reads disp_binXX
    -- while the upstream FFT block may update binXX independently. A new set of
    -- values is accepted only when h_count = 0 and v_count = 0.
    ----------------------------------------------------------------------------
    process(clk_25m6)
    begin
        if rising_edge(clk_25m6) then
            if reset = '0' then
                frame_counter <= 0;
                disp_bin01 <= (others => '0');
                disp_bin02 <= (others => '0');
                disp_bin03 <= (others => '0');
                disp_bin04 <= (others => '0');
                disp_bin05 <= (others => '0');
                disp_bin06 <= (others => '0');
                disp_bin07 <= (others => '0');
                disp_bin08 <= (others => '0');
                disp_bin09 <= (others => '0');
                disp_bin10 <= (others => '0');
                disp_bin11 <= (others => '0');
                disp_bin12 <= (others => '0');
                disp_bin13 <= (others => '0');
                disp_bin14 <= (others => '0');
                disp_bin15 <= (others => '0');
                disp_bin16 <= (others => '0');
                disp_bin17 <= (others => '0');
                disp_bin18 <= (others => '0');
                disp_bin19 <= (others => '0');
                disp_bin20 <= (others => '0');
                disp_bin21 <= (others => '0');
                disp_bin22 <= (others => '0');
                disp_bin23 <= (others => '0');
                disp_bin24 <= (others => '0');
                disp_bin25 <= (others => '0');
                disp_bin26 <= (others => '0');
                disp_bin27 <= (others => '0');
                disp_bin28 <= (others => '0');
                disp_bin29 <= (others => '0');
                disp_bin30 <= (others => '0');
                disp_bin31 <= (others => '0');
                disp_bin32 <= (others => '0');
    
            elsif h_count = 0 and v_count = 0 then
                if fps_fast_sync = '1' then
                    ----------------------------------------------------------------
                    -- Fast mode: update every VGA frame, about 61 FPS
                    ----------------------------------------------------------------
                    frame_counter <= 0;
                    
                    disp_bin01 <= bin01;
                    disp_bin02 <= bin02;
                    disp_bin03 <= bin03;
                    disp_bin04 <= bin04;
                    disp_bin05 <= bin05;
                    disp_bin06 <= bin06;
                    disp_bin07 <= bin07;
                    disp_bin08 <= bin08;
                    disp_bin09 <= bin09;
                    disp_bin10 <= bin10;
                    disp_bin11 <= bin11;
                    disp_bin12 <= bin12;
                    disp_bin13 <= bin13;
                    disp_bin14 <= bin14;
                    disp_bin15 <= bin15;
                    disp_bin16 <= bin16;
                    disp_bin17 <= bin17;
                    disp_bin18 <= bin18;
                    disp_bin19 <= bin19;
                    disp_bin20 <= bin20;
                    disp_bin21 <= bin21;
                    disp_bin22 <= bin22;
                    disp_bin23 <= bin23;
                    disp_bin24 <= bin24;
                    disp_bin25 <= bin25;
                    disp_bin26 <= bin26;
                    disp_bin27 <= bin27;
                    disp_bin28 <= bin28;
                    disp_bin29 <= bin29;
                    disp_bin30 <= bin30;
                    disp_bin31 <= bin31;
                    disp_bin32 <= bin32;
                else
                    ----------------------------------------------------------------
                    -- Slow mode: update every 10 VGA frames, about 6.1 FPS
                    ----------------------------------------------------------------
                    if frame_counter = FRAME_DIV_SLOW-1 then
                        frame_counter <= 0;
    
                        disp_bin01 <= bin01;
                        disp_bin02 <= bin02;
                        disp_bin03 <= bin03;
                        disp_bin04 <= bin04;
                        disp_bin05 <= bin05;
                        disp_bin06 <= bin06;
                        disp_bin07 <= bin07;
                        disp_bin08 <= bin08;
                        disp_bin09 <= bin09;
                        disp_bin10 <= bin10;
                        disp_bin11 <= bin11;
                        disp_bin12 <= bin12;
                        disp_bin13 <= bin13;
                        disp_bin14 <= bin14;
                        disp_bin15 <= bin15;
                        disp_bin16 <= bin16;
                        disp_bin17 <= bin17;
                        disp_bin18 <= bin18;
                        disp_bin19 <= bin19;
                        disp_bin20 <= bin20;
                        disp_bin21 <= bin21;
                        disp_bin22 <= bin22;
                        disp_bin23 <= bin23;
                        disp_bin24 <= bin24;
                        disp_bin25 <= bin25;
                        disp_bin26 <= bin26;
                        disp_bin27 <= bin27;
                        disp_bin28 <= bin28;
                        disp_bin29 <= bin29;
                        disp_bin30 <= bin30;
                        disp_bin31 <= bin31;
                        disp_bin32 <= bin32;
                    else
                        frame_counter <= frame_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- VGA sync, active low
    --------------------------------------------------------------------
    hsync <= '0' when (h_count >= H_VISIBLE + H_FRONT and
                       h_count <  H_VISIBLE + H_FRONT + H_SYNC) else '1';

    vsync <= '0' when (v_count >= V_VISIBLE + V_FRONT and
                       v_count <  V_VISIBLE + V_FRONT + V_SYNC) else '1';

    --------------------------------------------------------------------
    -- Pixel renderer
    -- For every pixel, this process determines which graphical elements overlap
    -- the current h_count/v_count position. It then assigns one RGB color based
    -- on a priority order: background, grid, bars, axes/ticks, text.
    --------------------------------------------------------------------
    process(clk_25m6)
        variable rr, gg, bb       : STD_LOGIC_VECTOR(3 downto 0);
        variable visible          : boolean;
        variable in_plot          : boolean;
        variable rel_x            : integer;
        variable rel_y            : integer;
        variable bin_idx          : integer;
        variable slot_x           : integer;
        variable bar_height       : integer;
        variable bar_top_y        : integer;
        variable is_grid          : boolean;
        variable is_axis          : boolean;
        variable is_tick          : boolean;
        variable is_bar           : boolean;
        variable is_text          : boolean;
    begin
        if rising_edge(clk_25m6) then
            rr := BLACK_R;
            gg := BLACK_G;
            bb := BLACK_B;

            visible := (h_count < H_VISIBLE and v_count < V_VISIBLE);
            in_plot := (h_count >= PLOT_X0 and h_count <= PLOT_X1 and
                        v_count >= PLOT_Y0 and v_count <= PLOT_Y1);

            -- Element flags for the current pixel. These are recomputed for
            -- every pixel and later translated into a final color.
            is_grid := false;
            is_axis := false;
            is_tick := false;
            is_bar  := false;
            is_text := false;

            if visible then
                ----------------------------------------------------------------
                -- Grid lines: 25%, 50%, 75%, 100% and frequency tick grid
                ----------------------------------------------------------------
                if in_plot then
                    if v_count = PLOT_Y0 or
                       v_count = PLOT_Y1 - PLOT_H / 4 or
                       v_count = PLOT_Y1 - PLOT_H / 2 or
                       v_count = PLOT_Y1 - (3 * PLOT_H) / 4 then
                        is_grid := true;
                    end if;

                    if h_count = PLOT_X0 + PLOT_W / 4 or
                       h_count = PLOT_X0 + PLOT_W / 2 or
                       h_count = PLOT_X0 + (3 * PLOT_W) / 4 or
                       h_count = PLOT_X1 then
                        is_grid := true;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Bars
                ----------------------------------------------------------------
                if in_plot then
                    -- Convert the current screen x-coordinate to an x-position
                    -- inside the centered bar area.
                    rel_x := h_count - PLOT_X0 - BAR_X_OFFSET;
                    rel_y := v_count - PLOT_Y0;

                    if rel_x >= 0 and rel_x < BAR_AREA_W then
                        -- bin_idx selects which FFT bin this x-position belongs
                        -- to. slot_x distinguishes the filled bar pixels from
                        -- the gap pixels inside each slot.
                        bin_idx := rel_x / BAR_SLOT_W;
                        slot_x  := rel_x mod BAR_SLOT_W;

                        if bin_idx >= 0 and bin_idx < N_BINS and slot_x < BAR_DRAW_W then
                            case bin_idx is
                                when 0  => bar_height := clip_height(scale_8bit_to_plot(disp_bin01));
                                when 1  => bar_height := clip_height(scale_8bit_to_plot(disp_bin02));
                                when 2  => bar_height := clip_height(scale_8bit_to_plot(disp_bin03));
                                when 3  => bar_height := clip_height(scale_8bit_to_plot(disp_bin04));
                                when 4  => bar_height := clip_height(scale_8bit_to_plot(disp_bin05));
                                when 5  => bar_height := clip_height(scale_8bit_to_plot(disp_bin06));
                                when 6  => bar_height := clip_height(scale_8bit_to_plot(disp_bin07));
                                when 7  => bar_height := clip_height(scale_8bit_to_plot(disp_bin08));
                                when 8  => bar_height := clip_height(scale_8bit_to_plot(disp_bin09));
                                when 9  => bar_height := clip_height(scale_8bit_to_plot(disp_bin10));
                                when 10 => bar_height := clip_height(scale_8bit_to_plot(disp_bin11));
                                when 11 => bar_height := clip_height(scale_8bit_to_plot(disp_bin12));
                                when 12 => bar_height := clip_height(scale_8bit_to_plot(disp_bin13));
                                when 13 => bar_height := clip_height(scale_8bit_to_plot(disp_bin14));
                                when 14 => bar_height := clip_height(scale_8bit_to_plot(disp_bin15));
                                when 15 => bar_height := clip_height(scale_8bit_to_plot(disp_bin16));
                                when 16 => bar_height := clip_height(scale_8bit_to_plot(disp_bin17));
                                when 17 => bar_height := clip_height(scale_8bit_to_plot(disp_bin18));
                                when 18 => bar_height := clip_height(scale_8bit_to_plot(disp_bin19));
                                when 19 => bar_height := clip_height(scale_8bit_to_plot(disp_bin20));
                                when 20 => bar_height := clip_height(scale_8bit_to_plot(disp_bin21));
                                when 21 => bar_height := clip_height(scale_8bit_to_plot(disp_bin22));
                                when 22 => bar_height := clip_height(scale_8bit_to_plot(disp_bin23));
                                when 23 => bar_height := clip_height(scale_8bit_to_plot(disp_bin24));
                                when 24 => bar_height := clip_height(scale_8bit_to_plot(disp_bin25));
                                when 25 => bar_height := clip_height(scale_8bit_to_plot(disp_bin26));
                                when 26 => bar_height := clip_height(scale_8bit_to_plot(disp_bin27));
                                when 27 => bar_height := clip_height(scale_8bit_to_plot(disp_bin28));
                                when 28 => bar_height := clip_height(scale_8bit_to_plot(disp_bin29));
                                when 29 => bar_height := clip_height(scale_8bit_to_plot(disp_bin30));
                                when 30 => bar_height := clip_height(scale_8bit_to_plot(disp_bin31));
                                when 31 => bar_height := clip_height(scale_8bit_to_plot(disp_bin32));
                                when others => bar_height := 0;
                            end case;
                            bar_top_y  := PLOT_Y1 - bar_height;

                            if v_count >= bar_top_y and v_count <= PLOT_Y1 then
                                is_bar := true;
                            end if;
                        end if;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Axes and ticks
                ----------------------------------------------------------------
                if h_count = PLOT_X0 and v_count >= PLOT_Y0 and v_count <= PLOT_Y1 then
                    is_axis := true;
                end if;

                if v_count = PLOT_Y1 and h_count >= PLOT_X0 and h_count <= PLOT_X1 then
                    is_axis := true;
                end if;

                -- y-axis ticks
                if h_count >= PLOT_X0 - 5 and h_count <= PLOT_X0 + 5 then
                    if v_count = PLOT_Y1 or
                       v_count = PLOT_Y1 - PLOT_H / 4 or
                       v_count = PLOT_Y1 - PLOT_H / 2 or
                       v_count = PLOT_Y1 - (3 * PLOT_H) / 4 or
                       v_count = PLOT_Y0 then
                        is_tick := true;
                    end if;
                end if;

                -- x-axis ticks
                if v_count >= PLOT_Y1 - 5 and v_count <= PLOT_Y1 + 5 then
                    if h_count = PLOT_X0 or
                       h_count = PLOT_X0 + PLOT_W / 4 or
                       h_count = PLOT_X0 + PLOT_W / 2 or
                       h_count = PLOT_X0 + (3 * PLOT_W) / 4 or
                       h_count = PLOT_X1 then
                        is_tick := true;
                    end if;
                end if;

                ----------------------------------------------------------------
                -- Text labels
                -- label_hit() tests each fixed label at its screen position.
                -- The text uses the 5x7 bitmap font scaled to 2x size.
                ----------------------------------------------------------------
                if label_hit(h_count, v_count, 245, 12, 0) then -- FFT SPECTRUM
                    is_text := true;
                elsif label_hit(h_count, v_count, 8, 12, 1) then -- POWER
                    is_text := true;
                elsif label_hit(h_count, v_count, 278, 455, 2) then -- FREQ KHZ
                    is_text := true;
                elsif label_hit(h_count, v_count, 43, PLOT_Y1 - 7, 3) then -- 0
                    is_text := true;
                elsif label_hit(h_count, v_count, 31, PLOT_Y1 - PLOT_H / 4 - 7, 4) then -- 25
                    is_text := true;
                elsif label_hit(h_count, v_count, 31, PLOT_Y1 - PLOT_H / 2 - 7, 5) then -- 50
                    is_text := true;
                elsif label_hit(h_count, v_count, 31, PLOT_Y1 - (3 * PLOT_H) / 4 - 7, 6) then -- 75
                    is_text := true;
                elsif label_hit(h_count, v_count, 19, PLOT_Y0 - 7, 7) then -- 100
                    is_text := true;
                elsif label_hit(h_count, v_count, PLOT_X0 - 4, PLOT_Y1 + 17, 3) then -- 0 kHz
                    is_text := true;
                elsif label_hit(h_count, v_count, PLOT_X0 + PLOT_W / 4 - 20, PLOT_Y1 + 17, 8) then -- 6.25
                    is_text := true;
                elsif label_hit(h_count, v_count, PLOT_X0 + PLOT_W / 2 - 20, PLOT_Y1 + 17, 9) then -- 12.5
                    is_text := true;
                elsif label_hit(h_count, v_count, PLOT_X0 + (3 * PLOT_W) / 4 - 26, PLOT_Y1 + 17, 10) then -- 18.75
                    is_text := true;
                elsif label_hit(h_count, v_count, PLOT_X1 - 10, PLOT_Y1 + 17, 11) then -- 25
                    is_text := true;
                end if;

                ----------------------------------------------------------------
                -- Priority: background < grid < bars < axes/ticks < text
                ----------------------------------------------------------------
                if is_grid then
                    rr := GRID_R;
                    gg := GRID_G;
                    bb := GRID_B;
                end if;

                if is_bar then
                    rr := BAR_R;
                    gg := BAR_G;
                    bb := BAR_B;
                end if;

                if is_axis or is_tick then
                    rr := WHITE_R;
                    gg := WHITE_G;
                    bb := WHITE_B;
                end if;

                if is_text then
                    rr := TEXT_R;
                    gg := TEXT_G;
                    bb := TEXT_B;
                end if;
            end if;

            r <= rr;
            g <= gg;
            b <= bb;
        end if;
    end process;

    red   <= r;
    green <= g;
    blue  <= b;

end Behavioral;