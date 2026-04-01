----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2025 03:26:40 PM
-- Design Name: 
-- Module Name: MEAT_5_OUTS - wrapper
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

library work;
use work.custom_types.all;

entity MEAT_5_OUTS is
    generic (
        OUTPUT_DATA_WIDTH: integer range 8 to 64 := 8;
        TOTAL_ACCUMULATION_TIME_MS: integer := 20;
        SENSOR_ROWS: integer := 320;
        SENSOR_COLS: integer := 320;
        IMG_ROWS: integer := 80;
        IMG_COLS: integer := 80;
        FIXED_FRAMERATE: boolean := true
    );
    port (
        clk : in std_logic;
        rst_n : in std_logic;
   
        s_axis_tdata : in std_logic_vector(31 downto 0);
        s_axis_tlast : in std_logic;
        s_axis_tvalid : in std_logic;
        s_axis_tready : out std_logic;
       
        --out_axis_tdata  : out std_logic_vector(3 * (OUTPUT_DATA_WIDTH / 8) * 8 - 1 downto 0);
        --out_axis_tlast  : out std_logic;
        --out_axis_tvalid : out std_logic;
        --out_axis_tready : in std_logic;
        
        m_axis_0_tdata,  m_axis_1_tdata,  m_axis_2_tdata,  m_axis_3_tdata,  m_axis_4_tdata  : out std_logic_vector((OUTPUT_DATA_WIDTH / 8) * 8 - 1 downto 0);
        m_axis_0_tlast,  m_axis_1_tlast,  m_axis_2_tlast,  m_axis_3_tlast,  m_axis_4_tlast  : out std_logic;
        m_axis_0_tvalid, m_axis_1_tvalid, m_axis_2_tvalid, m_axis_3_tvalid, m_axis_4_tvalid : out std_logic;
        m_axis_0_tready, m_axis_1_tready, m_axis_2_tready, m_axis_3_tready, m_axis_4_tready : in std_logic;
        
        mem_rot: out std_logic;
        trig_event_o: out std_logic;
        trig_id_o: out std_logic_vector(4 downto 0);
        trig_pol_o: out std_logic
    );
end MEAT_5_OUTS;

architecture wrapper of MEAT_5_OUTS is

    constant N_OUTPUTS: integer := 5;

    component MEAT is
        generic (
            N_OUTPUTS: integer;
            OUTPUT_DATA_WIDTH: integer range 8 to 64;
            TOTAL_ACCUMULATION_TIME_MS: integer;
            SENSOR_ROWS: integer;
            SENSOR_COLS: integer;
            IMG_ROWS: integer;
            IMG_COLS: integer;
            FIXED_FRAMERATE: boolean
        );
        port (
            clk : in std_logic;
            rst_n : in std_logic;

            s_axis_tdata : in std_logic_vector(31 downto 0);
            s_axis_tlast : in std_logic;
            s_axis_tvalid : in std_logic;
            s_axis_tready : out std_logic;

            m_axis_tdata : out data_array(0 to N_OUTPUTS-1)((OUTPUT_DATA_WIDTH / 8) * 8 - 1 downto 0);
            m_axis_tlast : out std_logic_vector(0 to N_OUTPUTS-1);
            m_axis_tvalid : out std_logic_vector(0 to N_OUTPUTS-1);
            m_axis_tready : in std_logic_vector(0 to N_OUTPUTS-1);

            mem_rot: out std_logic;
            trig_event_o: out std_logic;
            trig_id_o: out std_logic_vector(4 downto 0);
            trig_pol_o: out std_logic
        );
    end component MEAT;
    
    --component mosaic is
    --    generic (
    --        N_INPUTS: integer;
    --        INPUT_DATA_WIDTH: integer range 8 to 64;
    --        INPUT_ROWS: integer;
    --        INPUT_COLS: integer;
    --        IMG_ROWS: integer;
    --        IMG_COLS: integer;
    --        MOSAIC_ROWS: integer;
    --        MOSAIC_COLS: integer
    --    );
    --    port (
    --        clk : in std_logic;
    --        rst_n : in std_logic;
    --        
    --        s_axis_tdata : in data_array(0 to N_INPUTS-1)((INPUT_DATA_WIDTH / 8) * 8 - 1 downto 0);
    --        s_axis_tlast : in std_logic_vector(0 to N_INPUTS-1);
    --        s_axis_tvalid : in std_logic_vector(0 to N_INPUTS-1);
    --        s_axis_tready : out std_logic_vector(0 to N_INPUTS-1);
    --        
    --        m_axis_tvalid : out STD_LOGIC;
    --        m_axis_tready : in STD_LOGIC;
    --        m_axis_tlast : out STD_LOGIC;
    --        m_axis_tdata : out STD_LOGIC_VECTOR (3*INPUT_DATA_WIDTH-1 downto 0)
    --    );
    --end component mosaic;
        
    signal m_axis_tdata: data_array(0 to N_OUTPUTS-1)((OUTPUT_DATA_WIDTH / 8) * 8 - 1 downto 0);
    signal m_axis_tlast: std_logic_vector(0 to N_OUTPUTS-1);
    signal m_axis_tvalid: std_logic_vector(0 to N_OUTPUTS-1);
    signal m_axis_tready: std_logic_vector(0 to N_OUTPUTS-1);
        
begin

    main : MEAT
        generic map (
            N_OUTPUTS => N_OUTPUTS,
            OUTPUT_DATA_WIDTH => OUTPUT_DATA_WIDTH,
            TOTAL_ACCUMULATION_TIME_MS => TOTAL_ACCUMULATION_TIME_MS,
            SENSOR_ROWS => SENSOR_ROWS,
            SENSOR_COLS => SENSOR_COLS,
            IMG_ROWS => IMG_ROWS,
            IMG_COLS => IMG_COLS,
            FIXED_FRAMERATE => FIXED_FRAMERATE
        )
        port map (
            clk => clk,
            rst_n => rst_n,
       
            s_axis_tdata => s_axis_tdata,
            s_axis_tlast  => s_axis_tlast,
            s_axis_tvalid => s_axis_tvalid,
            s_axis_tready => s_axis_tready,
           
            m_axis_tdata => m_axis_tdata,
            m_axis_tlast => m_axis_tlast,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tready => m_axis_tready,
            
            mem_rot => mem_rot,
            trig_event_o => trig_event_o,
            trig_id_o => trig_id_o,
            trig_pol_o => trig_pol_o
        );
    
    --output : mosaic
    --        generic map (
    --            N_INPUTS => N_OUTPUTS,
    --            INPUT_DATA_WIDTH => OUTPUT_DATA_WIDTH,
    --            INPUT_ROWS => IMG_ROWS,
    --            INPUT_COLS => IMG_ROWS,
    --            IMG_ROWS => 720,
    --            IMG_COLS => 1280,
    --            MOSAIC_ROWS => 2,
    --            MOSAIC_COLS => 3
    --        )
    --        port map (
    --            clk => clk,
    --            rst_n => rst_n,
    --            
    --            s_axis_tdata => m_axis_tdata,
    --            s_axis_tlast => m_axis_tlast,
    --            s_axis_tvalid => m_axis_tvalid,
    --            s_axis_tready => m_axis_tready,
    --            
    --            m_axis_tvalid => out_axis_tvalid,
    --            m_axis_tready => out_axis_tready,
    --            m_axis_tlast => out_axis_tlast,
    --            m_axis_tdata => out_axis_tdata
    --        );
    
    m_axis_0_tdata  <= m_axis_tdata  (0);
    m_axis_0_tlast  <= m_axis_tlast  (0);
    m_axis_0_tvalid <= m_axis_tvalid (0);
    
    m_axis_1_tdata  <= m_axis_tdata  (1);
    m_axis_1_tlast  <= m_axis_tlast  (1);
    m_axis_1_tvalid <= m_axis_tvalid (1);
    
    m_axis_2_tdata  <= m_axis_tdata  (2);
    m_axis_2_tlast  <= m_axis_tlast  (2);
    m_axis_2_tvalid <= m_axis_tvalid (2);
    
    m_axis_3_tdata  <= m_axis_tdata  (3);
    m_axis_3_tlast  <= m_axis_tlast  (3);
    m_axis_3_tvalid <= m_axis_tvalid (3);
    
    m_axis_4_tdata  <= m_axis_tdata  (4);
    m_axis_4_tlast  <= m_axis_tlast  (4);
    m_axis_4_tvalid <= m_axis_tvalid (4);
    
    m_axis_tready <= (m_axis_0_tready, m_axis_1_tready, m_axis_2_tready, m_axis_3_tready, m_axis_4_tready);

end wrapper;
