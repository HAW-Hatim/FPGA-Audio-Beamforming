-- Dual-Port Block RAM with Two Write Ports, synchronous hence only one clock
-- Writefirst
-- Correct Modelization with a Shared Variable
-- File: rams_tdp_wf_wf.vhd
-- 2 clock cycle read latency because of output register

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity rams_tdp_wf_wf is
generic(
    data_width : integer := 64;
    addr_width : integer := 12;
    ram_depth: integer := 1024);
port(
    clk : in std_logic; -- Clock
    ena : in std_logic; -- Enable Port A
    enb : in std_logic; -- Enable Port B
    wea : in std_logic; -- Write Enable Port A
    web : in std_logic; -- Write Enable Port B
    addra : in std_logic_vector(addr_width-1 downto 0); -- Address Port A
    addrb : in std_logic_vector(addr_width-1 downto 0); -- Address Port B
    dia : in std_logic_vector(data_width-1 downto 0); -- Data in Port A
    dib : in std_logic_vector(data_width-1 downto 0); -- Data in Port B
    doa : out std_logic_vector(data_width-1 downto 0); -- Data out Port A
    dob : out std_logic_vector(data_width-1 downto 0) -- Data out Port B
);
end rams_tdp_wf_wf;

architecture syn of rams_tdp_wf_wf is
    type ram_type is array (ram_depth-1 downto 0) of std_logic_vector(data_width-1 downto 0);
    shared variable RAM : ram_type :=
        (others => (others => '0'));
    
    -- Signals for output registers
    signal r_doa : std_logic_vector(data_width-1 downto 0);
    signal r_dob : std_logic_vector(data_width-1 downto 0);
    
    
begin

-- Port A
process(CLK)
begin
    if rising_edge(CLK) then
        if ENA = '1' then
            if WEA = '1' then
                RAM(to_integer(unsigned(ADDRA))) := DIA;
            end if;
            
            -- Read first before writing
            r_doa <= RAM(to_integer(unsigned(ADDRA)));
            
        end if;
    end if;
end process;

--Port B
process(CLK)
begin
    if rising_edge(CLK) then
        if ENB = '1' then
            if WEB = '1' then
                RAM(to_integer(unsigned(ADDRB))) := DIB;
            end if;
            
            -- Read first before writing
             r_dob <= RAM(to_integer(unsigned(ADDRB)));
        end if;
    end if;
end process;

-- Output register for both Ports

process(clk)
begin
if rising_edge(clk) then
            dob <= r_dob;
            doa <= r_doa;
end if;
end process;
end syn;