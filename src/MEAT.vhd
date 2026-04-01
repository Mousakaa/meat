----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2025 02:43:25 PM
-- Design Name: 
-- Module Name: SWEAT - structure
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

entity MEAT is
    generic (
        N_OUTPUTS: integer := 5;
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
       
        m_axis_tdata : out data_array(0 to N_OUTPUTS-1)((OUTPUT_DATA_WIDTH / 8) * 8 - 1 downto 0);
        m_axis_tlast : out std_logic_vector(0 to N_OUTPUTS-1);
        m_axis_tvalid : out std_logic_vector(0 to N_OUTPUTS-1);
        m_axis_tready : in std_logic_vector(0 to N_OUTPUTS-1);
        
        mem_rot: out std_logic;
        trig_event_o: out std_logic;
        trig_id_o: out std_logic_vector(4 downto 0);
        trig_pol_o: out std_logic
    );
end MEAT;

architecture structure of MEAT is
    
    constant DATA_WIDTH: integer := 256 * IMG_COLS / SENSOR_COLS; -- optimized for EVT 2.1 Metavision protocol
    constant OUT_DATA_WIDTH: integer := (OUTPUT_DATA_WIDTH / 8) * 8;
    constant ACCUMULATION_TIME_US: integer := 1000 * TOTAL_ACCUMULATION_TIME_MS / N_OUTPUTS;
    constant ADDR_WIDTH: integer := clogb2(IMG_ROWS * IMG_COLS * 8 / DATA_WIDTH);
    
    component evt_decoder is
        generic (
            DATA_WIDTH: integer;
            ADDR_WIDTH: integer;
            SENSOR_ROWS: integer;
            SENSOR_COLS: integer;
            IMG_ROWS: integer;
            IMG_COLS: integer;
            ACCUMULATION_TIME_US: integer
        );
        port (
            clk: in std_logic;
            rst_n: in std_logic;
            -- inputs
            ready: in std_logic;
            -- axi stream slave
            s_axis_tready: out std_logic;
            s_axis_tdata: in  std_logic_vector(31 downto 0);
            s_axis_tvalid: in  std_logic;
            s_axis_tlast: in  std_logic;
            -- outputs
            valid: out std_logic;
            trig_event_o: out std_logic;
            trig_id_o: out std_logic_vector(4 downto 0);
            trig_pol_o: out std_logic;
            -- BRAM
            ram_en: out std_logic;
            ram_we: out std_logic;
            ram_addr: out std_logic_vector(ADDR_WIDTH-1 downto 0);
            ram_di : out std_logic_vector(DATA_WIDTH-1 downto 0);
            ram_do : in std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component evt_decoder;

    component ram_array is
        generic (
            N_SCALES: integer;
            ADDR_WIDTH: integer;
            DATA_WIDTH: integer;
            OUT_DATA_WIDTH: integer;
            IMG_ROWS: integer;
            IMG_COLS: integer;
            FIXED_FRAMERATE: boolean
        );
        port (
            clk : in STD_LOGIC;
            rst_n : in STD_LOGIC;
            -- inputs
            acc_valid : in std_logic;
            ram_cnt : in integer range 0 to N_SCALES-1;
            -- outputs
            acc_ready : out STD_LOGIC;
            -- BRAM input
            in_ram_en: in std_logic;
            in_ram_we: in std_logic;
            in_ram_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);
            in_ram_di : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_ram_do : out std_logic_vector(DATA_WIDTH-1 downto 0);
            -- axi stream outputs
            axis_tready: in std_logic_vector(0 to N_SCALES-1);
            axis_tdata: out data_array(0 to N_SCALES-1)(OUT_DATA_WIDTH-1 downto 0);
            axis_tlast: out  std_logic_vector(0 to N_SCALES-1);
            axis_tvalid: out  std_logic_vector(0 to N_SCALES-1)
            );
    end component ram_array;

    component base_counter is
        generic (
            N_SCALES: integer := 5
        );
        port (
            clk : in STD_LOGIC;
            rst_n : in STD_LOGIC;
            incr : in STD_LOGIC;
            addr : out integer range 0 to N_SCALES-1
        );
    end component base_counter;
    
    signal ram_en : std_logic := '0';
    signal ram_we : std_logic := '0';
    signal ram_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal ram_di : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal ram_do : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    
    signal acc_valid : STD_LOGIC := '0';
    signal ram_cnt : integer range 0 to N_OUTPUTS-1 := 0;
    signal out_ready : STD_LOGIC := '0';
    signal out_valid : STD_LOGIC := '0';
    signal acc_ready : STD_LOGIC := '0';

begin
    
    counter : base_counter
        generic map (
            N_OUTPUTS
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            incr => acc_valid,
            addr => ram_cnt
        );
        
    decoder : evt_decoder
        generic map (
            DATA_WIDTH,
            ADDR_WIDTH,
            SENSOR_ROWS,
            SENSOR_COLS,
            IMG_ROWS,
            IMG_COLS,
            ACCUMULATION_TIME_US
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            -- inputs
            ready => acc_ready,
            -- axi stream slave
            s_axis_tready => s_axis_tready,
            s_axis_tdata => s_axis_tdata,
            s_axis_tvalid => s_axis_tvalid,
            s_axis_tlast => s_axis_tlast,
            -- outputs
            valid => acc_valid,
            trig_event_o => trig_event_o,
            trig_id_o => trig_id_o,
            trig_pol_o => trig_pol_o,
            -- BRAM
            ram_en => ram_en,
            ram_we => ram_we,
            ram_addr => ram_addr,
            ram_di => ram_di,
            ram_do => ram_do
        );
        
    BRAM : ram_array
        generic map (
            N_OUTPUTS,
            ADDR_WIDTH,
            DATA_WIDTH,
            OUT_DATA_WIDTH,
            IMG_ROWS,
            IMG_COLS,
            FIXED_FRAMERATE
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            acc_valid => acc_valid,
            ram_cnt => ram_cnt,
            acc_ready => acc_ready,
            in_ram_en => ram_en,
            in_ram_we => ram_we,
            in_ram_addr => ram_addr,
            in_ram_di => ram_di,
            in_ram_do => ram_do,
            -- axi stream slave
            axis_tready => m_axis_tready,
            axis_tdata => m_axis_tdata,
            axis_tlast => m_axis_tlast,
            axis_tvalid => m_axis_tvalid
        );
        
    mem_rot <= acc_valid;
        
end structure;
