----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/17/2025 02:34:13 PM
-- Design Name: 
-- Module Name:  - 
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

package custom_types is

    function clogb2 (bit_depth_in : integer) return integer;

    type data_array is array(natural range <>) of std_logic_vector;
    
end package;

package body custom_types is

    -- clogb2 function
    function clogb2 (bit_depth_in : integer) return integer is
        variable bit_depth : integer := bit_depth_in;
        variable result : integer := 0;
    begin
        while bit_depth > 0 loop
            bit_depth := bit_depth / 2;
            result := result + 1;
        end loop;
        return result;
    end function;

end custom_types;