library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- fuer to_unsigned()
entity seven_segment_display is
    Port (
        clk : in STD_LOGIC;  -- 25,6 MHz Takt des Basys 3 Boards
        reset : in STD_LOGIC; -- Reset-Signal
        -- Zifferneingaben (0 bis 9 und -, sowie others)
        Z1 : in INTEGER range 0 to 11; -- linkeste Ziffer (Tausenderstelle)
        Z2 : in INTEGER range 0 to 11; -- Hunderterstelle
        Z3 : in INTEGER range 0 to 11; -- Zehnerstelle
        Z4 : in INTEGER range 0 to 11; -- Einerstelle
        -- Ausgaenge fuer die 7-Segment-Anzeige
        Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0); -- Anodensignale
        LED_out : out STD_LOGIC_VECTOR (6 downto 0) -- Kathodenmuster
    );
end seven_segment_display;
architecture Behavioral of seven_segment_display is
    -- Signal, das die vier Ziffern zusammenfasst (jeweils 4 Bit)
    signal displayed_number : STD_LOGIC_VECTOR(15 downto 0);
    -- Signal fuer die aktuell angezeigte Ziffer
    signal LED_BCD : STD_LOGIC_VECTOR(3 downto 0);
    -- Zaehler fuer das Zeit-Multiplexing der 4 Anzeigen
    signal refresh_counter : STD_LOGIC_VECTOR(17 downto 0);
    -- 2-Bit Zaehler, um die aktive Anode zu bestimmen
    signal LED_activating_counter : STD_LOGIC_VECTOR(1 downto 0);
begin
    ------------------------------------------------------------------------
    -- Ziffern zusammensetzen:
    -- Jede Ziffer (Z1, Z2, Z3, Z4) wird in 4 Bit konvertiert und
    -- zum 16-Bit Vektor kombiniert
    ------------------------------------------------------------------------
    displayed_number <= 
        std_logic_vector(to_unsigned(Z1, 4)) &
        std_logic_vector(to_unsigned(Z2, 4)) &
        std_logic_vector(to_unsigned(Z3, 4)) &
        std_logic_vector(to_unsigned(Z4, 4));
    ------------------------------------------------------------------------
    -- Refresh-Counter: erzeugt den Multiplex-Takt fuer die 4-stellige Anzeige
    -- 18 Bit Counter -> ca. 10.xx ms bei 25,6 MHz
    ------------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '0' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
             refresh_counter <= std_logic_vector(unsigned(refresh_counter) + 1);
        end if;
    end process;
    -- 2 hoechstwertige Bits fuer die LED-Auswahl
    LED_activating_counter <= refresh_counter(17 downto 16);
    ------------------------------------------------------------------------
    -- Ansteuern der Anoden + Auswahl der aktuellen 4 Bit Ziffer
    ------------------------------------------------------------------------
    process(LED_activating_counter, displayed_number)
    begin
        case LED_activating_counter is
            when "00" =>
                Anode_Activate <= "0111"; -- nur erste Stelle aktiv
                LED_BCD <= displayed_number(15 downto 12); -- Z1
            when "01" =>
                Anode_Activate <= "1011"; -- nur zweite Stelle aktiv
                LED_BCD <= displayed_number(11 downto 8);  -- Z2
            when "10" =>
                Anode_Activate <= "1101"; -- nur dritte Stelle aktiv
                LED_BCD <= displayed_number(7 downto 4);   -- Z3
            when "11" =>
                Anode_Activate <= "1110"; -- nur vierte Stelle aktiv
                LED_BCD <= displayed_number(3 downto 0);   -- Z4
            when others =>
                Anode_Activate <= "1111"; -- alle aus, sollte nie passieren
        end case;
    end process;
    ------------------------------------------------------------------------
    -- BCD zu 7-Segment Decoder
    -- 7-Segment LED_out: 0 = LED an, 1 = LED aus
    ------------------------------------------------------------------------
    process(LED_BCD)
    begin
        case LED_BCD is
            when "0000" => LED_out <= "0000001"; -- 0
            when "0001" => LED_out <= "1001111"; -- 1
            when "0010" => LED_out <= "0010010"; -- 2
            when "0011" => LED_out <= "0000110"; -- 3
            when "0100" => LED_out <= "1001100"; -- 4
            when "0101" => LED_out <= "0100100"; -- 5
            when "0110" => LED_out <= "0100000"; -- 6
            when "0111" => LED_out <= "0001111"; -- 7
            when "1000" => LED_out <= "0000000"; -- 8
            when "1001" => LED_out <= "0000100"; -- 9
            when "1010" => LED_out <= "1111110"; -- -
            when others => LED_out <= "1111111"; -- alle Segmente aus (Fehler)
        end case;
    end process;
end Behavioral;
