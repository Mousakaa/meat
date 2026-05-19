----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2026 11:34:13 AM
-- Design Name: 
-- Module Name: AXISAddTLAST - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AXISAddTLAST is
    generic(
        DATA_WIDTH: integer := 8;
        DATA_LENGTH: integer := 1000
    );
    port(
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        -- IN
        axis_in_tready: out std_logic;
        axis_in_tdata: in std_logic_vector(0 to DATA_WIDTH-1);
        axis_in_tvalid: in  std_logic;
        -- OUT
        axis_out_tready: in std_logic;
        axis_out_tdata: out std_logic_vector(0 to DATA_WIDTH-1);
        axis_out_tlast: out  std_logic;
        axis_out_tvalid: out  std_logic
    );
end AXISAddTLAST;

architecture Behavioral of AXISAddTLAST is

    signal counter: integer range 0 to DATA_LENGTH := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                counter <= 0;
                axis_in_tready <= '0';
                axis_out_tdata <= axis_in_tdata;
                axis_out_tlast <= '0';
                axis_out_tvalid <= '0';
            else
                axis_in_tready <= '0';
                axis_out_tdata <= axis_in_tdata;
                axis_out_tlast <= '0';
                axis_out_tvalid <= '0';
                
                -- TLAST ASSERTION
                if counter = DATA_LENGTH - 1 then
                    axis_out_tlast <= '1';
                end if;
                
                -- COUNTER INCREMENTATION
                if axis_out_tready = '1' then
                    axis_in_tready <= '1';
                    if axis_in_tvalid = '1' then
                        axis_out_tvalid <= '1';
                        if counter = DATA_LENGTH - 1 then
                            counter <= 0;
                        else
                            counter <= counter + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
