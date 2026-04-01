----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/19/2025 03:57:15 PM
-- Design Name: 
-- Module Name: base_address_counter - Behavioral
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
use ieee.numeric_std.all;

library work;
use work.custom_types.all;

entity base_counter is
    generic (
        N_SCALES: integer := 5
    );
    port (
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        incr : in STD_LOGIC;
        addr : out integer range 0 to N_SCALES
    );
end base_counter;

architecture Behavioral of base_counter is
    signal addr_cnt : integer range 0 to N_SCALES;
begin

    addr <= addr_cnt;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                addr_cnt <= 0;
            else
                if incr = '1' then
                    if addr_cnt = N_SCALES then
                        addr_cnt <= 0;
                    else
                        addr_cnt <= addr_cnt + 1;
                    end if;
                end if;
            end if;
        end if; 
    end process;

end Behavioral;
