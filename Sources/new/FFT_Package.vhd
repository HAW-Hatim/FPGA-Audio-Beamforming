----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.05.2026 10:38:58
-- Design Name: 
-- Module Name: FFT_Package - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package fft_package is


constant FFT_LENGTH: integer:=32;
constant FFT_STAGES: integer:= 5; -- log2(FFT_Length)
constant Num_Butterflies_STAGES: integer:= 16; -- FFT_Length/2
constant DATA_WIDTH: integer:=8;

type sample is array(0 to FFT_LENGTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
 
-- Lookup table for DIT indexes

type my_lut_type is array (natural range <>) of integer;


-- Function decleration
function make_my_lut return my_lut_type;

function bit_reverse(x : integer; width : integer) return integer;

-- Index LUT for DIT index
constant DIT_INDEX : my_lut_type(0 to FFT_LENGTH-1) := make_my_lut;

-- LUT for Twiddlefactor RAM

-- Complex number operations
-- Complex number types




type t_My_Complex_Type is record
Real: signed(DATA_WIDTH-1 downto 0);
Imag: signed(DATA_WIDTH-1 downto 0);
end record;

type Result_Complex_Type is record
Real: signed(2*DATA_WIDTH-1 downto 0);
Imag: signed(2*DATA_WIDTH-1 downto 0);
end record;


type complex_array is array(0 to FFT_LENGTH-1) of t_My_Complex_Type;


-- Technically possible to overload symbols "*", "+" and "-" but this should work too
function complex_multiply(a, b : t_My_Complex_Type) return t_My_Complex_Type;

function complex_add(a, b : t_My_Complex_Type) return t_My_Complex_Type;

function complex_subtract(a, b : t_My_Complex_Type) return t_My_Complex_Type;


function abs_squared(a : complex_array) return sample;

-- Twiddle factors

    
    -- Calculated Twiddle factors from matlab script
  constant twiddle_factors : complex_array :=(
  (Real=> "01111111", Imag => "00000000"),
(Real=> "01111110", Imag => "11100111"),
(Real=> "01110110", Imag => "11001111"),
(Real=> "01101010", Imag => "10111001"),
(Real=> "01011011", Imag => "10100101"),
(Real=> "01000111", Imag => "10010110"),
(Real=> "00110001", Imag => "10001010"),
(Real=> "00011001", Imag => "10000010"),
(Real=> "00000000", Imag => "10000000"),
(Real=> "11100111", Imag => "10000010"),
(Real=> "11001111", Imag => "10001010"),
(Real=> "10111001", Imag => "10010110"),
(Real=> "10100101", Imag => "10100101"),
(Real=> "10010110", Imag => "10111001"),
(Real=> "10001010", Imag => "11001111"),
(Real=> "10000010", Imag => "11100111"),
(Real=> "10000000", Imag => "00000000"),
(Real=> "10000010", Imag => "00011001"),
(Real=> "10001010", Imag => "00110001"),
(Real=> "10010110", Imag => "01000111"),
(Real=> "10100101", Imag => "01011011"),
(Real=> "10111001", Imag => "01101010"),
(Real=> "11001111", Imag => "01110110"),
(Real=> "11100111", Imag => "01111110"),
(Real=> "00000000", Imag => "01111111"),
(Real=> "00011001", Imag => "01111110"),
(Real=> "00110001", Imag => "01110110"),
(Real=> "01000111", Imag => "01101010"),
(Real=> "01011011", Imag => "01011011"),
(Real=> "01101010", Imag => "01000111"),
(Real=> "01110110", Imag => "00110001"),
(Real=> "01111110", Imag => "00011001")
);
  




end package fft_package;



package body fft_package is

-- Bit reversal of a bit vector
function bit_reverse(x : integer; width : integer) return integer is
  variable int_reversed : integer;
  variable unsigned_index : unsigned(width-1 downto 0);
  variable temp_index : unsigned(width-1 downto 0);

begin
   unsigned_index := TO_UNSIGNED(x, width);
    BIT_REVERSE: for k in 0 to WIDTH-1 loop
        temp_index(k) := unsigned_index(WIDTH-1-k);
    end loop;
    int_reversed := TO_INTEGER(temp_index);
    return int_reversed;

end function;


-- Generate lookuptable for bitreversed index (DIT)
 function make_my_lut return my_lut_type is
  variable return_lut : my_lut_type(0 to (FFT_LENGTH-1));
  constant width : integer := 5;
begin
  
  for idx in return_lut'range loop
    return_lut(idx) := bit_reverse(idx, width);
  end loop;
  return return_lut;
end function;

-- Complex functions

-- Complex multiplication
-- Note: 1Q23 Format results in 2Q46 which then gets shifted and resized back to 1Q23
function complex_multiply(a, b : t_My_Complex_Type) return
t_My_Complex_Type is
variable ResultVal: Result_Complex_Type;
variable RetVal: t_My_Complex_Type;

begin
ResultVal.Real := a.real * b.real - a.imag * b.imag;
ResultVal.Imag := a.real * b.imag + b.real * a.imag;
-- Shift down to our complex type size
RetVal.Real := resize(shift_right(ResultVal.Real, DATA_WIDTH-1), RetVal.Real'length);
RetVal.Imag :=  resize(shift_right(ResultVal.Imag, DATA_WIDTH-1), RetVal.Imag'length);
return(RetVal);
end function complex_multiply;


-- TODO: Improv could save a few resources here since we only need 25bits
function complex_add(a, b : t_My_Complex_Type) return
t_My_Complex_Type is
variable ResultVal: Result_Complex_Type;
variable RetVal: t_My_Complex_Type;

begin
-- Possible overflow of 1 bit hence resizing/shifting
ResultVal.Real :=  resize(a.real, 2*DATA_WIDTH) + resize(b.real, 2*DATA_WIDTH);
ResultVal.Imag := resize(a.imag, 2*DATA_WIDTH) + resize(b.imag, 2*DATA_WIDTH);
-- Shift down to our complex type size
RetVal.Real := resize(shift_right(ResultVal.Real, 1), RetVal.Real'length);
RetVal.Imag :=  resize(shift_right(ResultVal.Imag, 1), RetVal.Imag'length);
return(RetVal);
end function complex_add;

function complex_subtract(a, b : t_My_Complex_Type) return
t_My_Complex_Type is
variable RetVal: t_My_Complex_Type;
variable ResultVal: Result_Complex_Type;

begin
-- Possible overflow of 1 bit hence resizing/shifting
ResultVal.Real :=  resize(a.real, 2*DATA_WIDTH) - resize(b.real, 2*DATA_WIDTH);
ResultVal.Imag := resize(a.imag, 2*DATA_WIDTH) - resize(b.imag, 2*DATA_WIDTH);
-- Shift down to our complex type size
RetVal.Real := resize(shift_right(ResultVal.Real, 1), RetVal.Real'length);
RetVal.Imag :=  resize(shift_right(ResultVal.Imag, 1), RetVal.Imag'length);
return(RetVal);
end function complex_subtract;


-- Conversion of std_logic_vector array to complex array
function array_to_complex_array(samples: sample) return 
complex_array is
  variable return_array : complex_array;
begin
 for idx in return_array'range loop
    return_array(idx) := (Real => signed(samples(idx)), Imag => (others => '0'));
  end loop;
  return(return_array);
end function array_to_complex_array;

-- Betrags quadrat for output of FFT
function abs_squared(a : complex_array) return sample is
    variable return_array : sample;
    variable ResultVal: signed(2*DATA_WIDTH-1 downto 0);

begin

 for idx in return_array'range loop
    ResultVal := a(idx).real * a(idx).real + a(idx).imag * a(idx).imag;
    return_array(idx) := std_logic_vector(resize(shift_right(ResultVal,DATA_WIDTH-1), return_array(idx)'length));
  end loop;
  return(return_array);
end function abs_squared;



end package body fft_package;

