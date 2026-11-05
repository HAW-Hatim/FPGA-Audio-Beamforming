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

entity Butterfly is
    Port ( 
           z1 : in t_My_Complex_Type;
           z2 : in t_My_Complex_Type;
           Z1_out : out t_My_Complex_Type;
           Z2_out : out t_My_Complex_Type;
           Twiddle : in t_My_Complex_Type);
end Butterfly;

architecture Behavioral of Butterfly is

begin

-- Can be optimized by calculating the multiplication only once and using it
butterfly_calc: process(z1, z2, Twiddle)
variable complex_mult_res : t_My_Complex_Type;
begin
complex_mult_res := complex_multiply(Twiddle,z2);
Z1_out <= complex_add(z1,complex_mult_res);
Z2_out <= complex_subtract(z1,complex_mult_res);

end process;
end Behavioral;