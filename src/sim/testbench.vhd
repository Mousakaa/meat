----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/21/2025 04:23:24 PM
-- Design Name: 
-- Module Name: tb_decoder - Behavioral
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

entity tb is
end tb;

architecture test of tb is
    
    constant EVT_DELAY : time := 0 us;
    constant INTRA_EVT_DELAY_CYCLES : integer := 2;
    constant CLK_PERIOD : time := 10 ns;
    constant N_OUTPUTS : integer := 5;
    constant OUT_DATA_WIDTH : integer := 64;

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
    
    function encode_event (
        x: integer range 0 to 319;
        y: integer range 0 to 319;
        pol: std_logic;
        time: integer
    ) return std_logic_vector is
        variable result : std_logic_vector(63 downto 0) := (others => '0');
    begin
        result(60) := pol;
        result(59 downto 54) := std_logic_vector(to_unsigned(time, 6));
        result(53 downto 43) := std_logic_vector(to_unsigned(x, 11));
        result(47 downto 43) := (others => '0'); -- Align x to 32 grid
        result(42 downto 32) := std_logic_vector(to_unsigned(y, 11));
        result(x mod 32) := '1';
        return result;
    end function;
    
    function encode_time (
        time: integer
    ) return std_logic_vector is
        variable result : std_logic_vector(63 downto 0) := (others => '0');
    begin
        result(63) := '1';
        result(59 downto 32) := std_logic_vector(to_unsigned(time / 64, 28));
        return result;
    end function;
    
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    signal s_axis_tdata : std_logic_vector(31 downto 0) := (others => '0');
    signal s_axis_tlast : std_logic := '0';
    signal s_axis_tvalid : std_logic := '0';
    signal s_axis_tready : std_logic := '0';
    signal mem_rot : std_logic := '0';
    
    signal m_axis_tdata: data_array(0 to N_OUTPUTS-1)(OUT_DATA_WIDTH-1 downto 0);
    signal m_axis_tlast: std_logic_vector(0 to N_OUTPUTS-1);
    signal m_axis_tvalid: std_logic_vector(0 to N_OUTPUTS-1);
    signal m_axis_tready: std_logic_vector(0 to N_OUTPUTS-1);
    
    --signal out_axis_tdata : std_logic_vector(3*OUT_DATA_WIDTH-1 downto 0) := (others => '0');
    --signal out_axis_tlast : std_logic := '0';
    --signal out_axis_tvalid : std_logic := '0';
    --signal out_axis_tready : std_logic := '0';
    
    type state_type is (IDLE, LSB, MSB, WAIT_INTRA);
    signal state : state_type := IDLE;
    signal start : std_logic := '0';
    signal send_time : std_logic := '1';
    signal data : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt : integer := 0;
    signal idx : integer := 0;
    signal elapsed_cycles : integer := 0;
    
begin

    UUT : MEAT
        generic map (
            N_OUTPUTS => N_OUTPUTS,
            OUTPUT_DATA_WIDTH => OUT_DATA_WIDTH,
            TOTAL_ACCUMULATION_TIME_MS => 20,
            SENSOR_ROWS => 320,
            SENSOR_COLS => 320,
            IMG_ROWS => 320,
            IMG_COLS => 320,
            FIXED_FRAMERATE => true
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
            trig_event_o => open,
            trig_id_o => open,
            trig_pol_o => open
        );
        
    --output : mosaic
    --    generic map (
    --        N_INPUTS => N_OUTPUTS,
    --        INPUT_DATA_WIDTH => OUT_DATA_WIDTH,
    --        INPUT_ROWS => 320,
    --        INPUT_COLS => 320,
    --        IMG_ROWS => 720,
    --        IMG_COLS => 1280,
    --        MOSAIC_ROWS => 2,
    --        MOSAIC_COLS => 3
    --    )
    --    port map (
    --        clk => clk,
    --        rst_n => rst_n,
    --        
    --        s_axis_tdata => m_axis_tdata,
    --        s_axis_tlast => m_axis_tlast,
    --        s_axis_tvalid => m_axis_tvalid,
    --        s_axis_tready => m_axis_tready,
    --        
    --        m_axis_tvalid => out_axis_tvalid,
    --        m_axis_tready => out_axis_tready,
    --        m_axis_tlast => out_axis_tlast,
    --        m_axis_tdata => out_axis_tdata
    --    );

    clk <= not clk after CLK_PERIOD/2;
    
    process begin
        rst_n <= '0';
        start <= '0';
        wait for 15 ns;
        rst_n <= '1';
        wait for 200 us;
        start <= '1';
        wait until false;
    end process;
    
    process begin
        m_axis_tready <= (others => '0');
        
        m_axis_tready <= (others => '1') after CLK_PERIOD;
        
        wait until false;
        --wait until m_axis_tlast = std_logic_vector(to_unsigned(2**N_OUTPUTS-1, N_OUTPUTS));
        --wait for CLK_PERIOD;
    end process;
    
    process(clk)
        variable time_us : integer := 0;
        variable pol : std_logic_vector(0 downto 0) := "0";
        variable intra_cnt : integer := 0;
    begin
        if rising_edge(clk) then
            elapsed_cycles <= elapsed_cycles + 1;
            case state is
                when IDLE =>
                    s_axis_tlast <= '0';
                    s_axis_tvalid <= '0';
                    if s_axis_tready = '1' and start = '1' then
                        state <= LSB;
                        if send_time = '1' then -- if more than 64us have elapsed
                            if cnt = EVT_DELAY / CLK_PERIOD then
                                cnt <= 0;
                                time_us := elapsed_cycles * (CLK_PERIOD / 1 ns) / 1000;
                                send_time <= '0';
                                data <= encode_time(time_us);
                            else
                                cnt <= cnt + 1;
                                state <= IDLE;
                            end if;
                        else
                            --pol := std_logic_vector(to_unsigned(idx mod 2, 1));
                            pol := std_logic_vector(to_unsigned(idx mod 2, 1));
                            send_time <= '1';
                            data <= encode_event(
                                idx mod 320,
                                (idx / 320),
                                pol(0),
                                time_us
                            );
                            if idx = 320*320-1 then
                                idx <= 0;
                            else
                                idx <= idx + 1;
                            end if;
                            --data <= encode_event(
                            --    (idx mod 2) * 319,
                            --    (idx / 2) * 319,
                            --    pol(0),
                            --    time_us
                            --);
                            --if idx = 3 then
                            --    idx <= 0;
                            --else
                            --    idx <= idx + 1;
                            --end if;
                        end if;
                    end if;
                when LSB =>
                    s_axis_tlast <= '0';
                    s_axis_tdata <= data(31 downto 0);
                    s_axis_tvalid <= '1';
                    if s_axis_tready = '1' then
                        state <= WAIT_INTRA;
                        intra_cnt := 0;
                    end if;
                when WAIT_INTRA =>
                    s_axis_tlast <= '0';
                    s_axis_tvalid <= '0';
                    s_axis_tdata <= (others => '0');
                    if intra_cnt = INTRA_EVT_DELAY_CYCLES - 1 then
                        state <= MSB;
                    else
                        intra_cnt := intra_cnt + 1;
                    end if;
                when MSB =>
                    s_axis_tlast <= '0';
                    s_axis_tdata <= data(63 downto 32);
                    s_axis_tvalid <= '1';
                    if s_axis_tready = '1' then
                        state <= IDLE;
                    end if;
                when others =>
                    s_axis_tvalid <= '0';
                    state <= IDLE;
            end case;
        end if;
    end process;
    
end test;