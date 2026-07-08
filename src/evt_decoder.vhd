----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/19/2025 01:54:54 PM
-- Design Name: 
-- Module Name: evt_accumulation - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity evt_decoder is
    generic (
        DATA_WIDTH: integer := 8;
        ADDR_WIDTH: integer := 32;
        SENSOR_ROWS: integer := 320;
        SENSOR_COLS: integer := 320;
        IMG_ROWS: integer := 80;
        IMG_COLS: integer := 80;
        ACCUMULATION_TIME_US: integer := 1000
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
end evt_decoder;

architecture prophesee of evt_decoder is

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

    constant DATA_DEPTH: integer := IMG_ROWS * IMG_COLS * 8 / DATA_WIDTH;
    constant SCALE_X : integer := SENSOR_COLS / IMG_COLS;
    constant SCALE_Y : integer := SENSOR_ROWS / IMG_ROWS;
    constant SCALE_X_BW : integer := clogb2(SCALE_X-1);
    constant SCALE_Y_BW : integer := clogb2(SCALE_Y-1);
    
    -- Event types
    constant EVT_NEG       : std_logic_vector(3 downto 0) := "0000";
    constant EVT_POS       : std_logic_vector(3 downto 0) := "0001";
    constant EVT_TIME_HIGH : std_logic_vector(3 downto 0) := "1000";
    constant EXT_TRIGGER   : std_logic_vector(3 downto 0) := "1010";
    constant OTHER         : std_logic_vector(3 downto 0) := "1110";
    constant CONTINUED     : std_logic_vector(3 downto 0) := "1111";
    
    type state_type is (RESET, IDLE, EVT, READ, WRITE, WAIT_IDLE);
    
    signal state, state_next : state_type := RESET;
    signal data_lsb, data_lsb_next : std_logic_vector(31 downto 0) := (others => '0');
    signal x, x_next : std_logic_vector(10 downto 0) := (others => '0');
    signal y, y_next : std_logic_vector(10 downto 0) := (others => '0');
    signal pol, pol_next : std_logic := '0';
    signal vect, vect_next : std_logic_vector(31 downto 0) := (others => '0');
    signal time_lsb_next : std_logic_vector(5 downto 0) := (others => '0');
    signal time_msb_next : std_logic_vector(27 downto 0) := (others => '0');
    signal timestamp, timestamp_last, timestamp_last_next : std_logic_vector(33 downto 0) := (others => '0');
    
    signal resume, resume_next : std_logic;
    
    signal j, j_next : integer range 0 to (32/SCALE_X * 8/DATA_WIDTH) - 1 := 0;
    signal i, i_next : integer range 0 to DATA_DEPTH - 1 := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= RESET;
            else
                state <= state_next;
            end if;
        end if;
    end process;

    -- Process for register updates
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                data_lsb <= (others => '0');
                vect <= (others => '0');
                pol <= '0';
                x <= (others => '0');
                y <= (others => '0');
                timestamp <= (others => '0');
                timestamp_last <= (others => '0');
                j <= 0;
                i <= 0;
                resume <= '0';
            else
                data_lsb <= data_lsb_next;
                vect <= vect_next;
                pol <= pol_next;
                x <= x_next;
                y <= y_next;
                timestamp(5 downto 0) <= time_lsb_next;
                timestamp(33 downto 6) <= time_msb_next;
                timestamp_last <= timestamp_last_next;
                j <= j_next;
                i <= i_next;
                resume <= resume_next;
            end if;
        end if;
    end process;

    -- Main FSM
    process(state, ready, s_axis_tdata, s_axis_tvalid, s_axis_tlast, ram_do, data_lsb, vect, x, y, pol, timestamp, timestamp_last, i, j, resume)
        variable cnt : integer range 0 to 32;
        variable k : integer range 0 to SCALE_X-1;
        variable j_par : integer range 0 to DATA_WIDTH/8 - 1;
    begin
        -- Defaults
        state_next <= state;
        data_lsb_next <= data_lsb;
        vect_next <= (others => '0');
        x_next <= (others => '0');
        y_next <= (others => '0');
        pol_next <= '0';
        time_lsb_next <= timestamp(5 downto 0);
        time_msb_next <= timestamp(33 downto 6);
        timestamp_last_next <= timestamp_last;
        j_next <= 0;
        i_next <= 0;
        resume_next <= resume;
        
        s_axis_tready <= '1';
        valid <= '0';
        ram_en <= '0';
        ram_we <= '0';
        ram_addr <= (others => '0');
        ram_di <= (others => '0');
        
        trig_event_o <= '0';
        trig_id_o <= (others => '0');
        trig_pol_o <= '0';
        
        case state is
             when RESET =>
                ram_en <= '1';
                ram_we <= '1';
                ram_addr <= std_logic_vector(to_unsigned(i, ram_addr'length));
                ram_di <= (others => '0');
                if i = DATA_DEPTH - 1 then
                    i_next <= 0;
                    state_next <= IDLE;
                else
                    i_next <= i + 1;
                    s_axis_tready <= '0';
                end if;
            when IDLE =>
                if s_axis_tvalid = '1' then
                    state_next <= EVT;
                    data_lsb_next <= s_axis_tdata;
                    if s_axis_tlast = '1' then
                        state_next <= IDLE;
                    end if;
                end if;
            when EVT =>
                if s_axis_tvalid = '1' then
                    case s_axis_tdata(31 downto 28) is
                        when EVT_NEG =>
                            state_next <= READ;
                            s_axis_tready <= '0';
                            time_lsb_next <= s_axis_tdata(27 downto 22);
                            x_next <= std_logic_vector(unsigned(s_axis_tdata(21 downto 11)) srl SCALE_X_BW);
                            y_next <= std_logic_vector(unsigned(s_axis_tdata(10 downto 0)) srl SCALE_Y_BW);
                            pol_next <= '0';
                            vect_next <= data_lsb;
                        when EVT_POS =>
                            state_next <= READ;
                            s_axis_tready <= '0';
                            time_lsb_next <= s_axis_tdata(27 downto 22);
                            x_next <= std_logic_vector(unsigned(s_axis_tdata(21 downto 11)) srl SCALE_X_BW);
                            y_next <= std_logic_vector(unsigned(s_axis_tdata(10 downto 0)) srl SCALE_Y_BW);
                            pol_next <= '1';
                            vect_next <= data_lsb;
                        when EVT_TIME_HIGH =>
                            if s_axis_tdata(27 downto 0) /= timestamp(33 downto 6) then
                                time_msb_next <= s_axis_tdata(27 downto 0);
                                time_lsb_next <= (others => '0');
                                if (unsigned(s_axis_tdata(27 downto 0)) sll 6) - unsigned(timestamp_last) >= ACCUMULATION_TIME_US then
                                    timestamp_last_next(33 downto 6) <= s_axis_tdata(27 downto 0);
                                    timestamp_last_next(5 downto 0) <= (others => '0');
                                    if ready = '1' then
                                        valid <= '1';
                                        s_axis_tready <= '1';
                                        state_next <= IDLE;
                                    else
                                        state_next <= WAIT_IDLE;
                                    end if;
                                end if;
                            end if;
                            state_next <= IDLE;
                        when EXT_TRIGGER =>
                            state_next <= IDLE;
                            trig_event_o <= '1';
                            time_lsb_next <= s_axis_tdata(27 downto 22);
                            trig_id_o <= s_axis_tdata(12 downto 8);
                            trig_pol_o <= s_axis_tdata(0);
                        when others =>
                            state_next <= IDLE;
                    end case;
                end if;
            when READ =>
                -- if back from WAIT_IDLE, update the timestamp comparator
                if resume = '1' then
                    resume_next <= '0';
                    timestamp_last_next <= timestamp;
                end if;
            
                state_next <= WRITE;
                ram_en <= '1';
                ram_addr <= std_logic_vector(to_unsigned(
                    (to_integer(unsigned(y)) * IMG_COLS + to_integer(unsigned(x))) * 8/DATA_WIDTH +
                    j,
                ram_addr'length));
                j_next <= j;
                x_next <= x;
                y_next <= y;
                pol_next <= pol;
                vect_next <= vect;
                s_axis_tready <= '0';
            when WRITE =>
                s_axis_tready <= '0';
                ram_en <= '1';
                ram_we <= '1';
                
                ram_addr <= std_logic_vector(to_unsigned(
                    (to_integer(unsigned(y)) * IMG_COLS + to_integer(unsigned(x))) * 8/DATA_WIDTH +
                    j,
                ram_addr'length));
                
                for j_par in 0 to DATA_WIDTH/8 - 1 loop
                    cnt := 0;
                    for k in 0 to SCALE_X-1 loop
                        if vect((j+j_par)*SCALE_X + k) = '1' then
                            cnt := cnt + 1;
                        end if;
                    end loop;
                    
                    if pol = '1' then
                        ram_di(j_par*8 + 7 downto j_par*8) <= std_logic_vector(unsigned(ram_do(j_par*8 + 7 downto j_par*8)) + cnt);
                    else
                        ram_di(j_par*8 + 7 downto j_par*8) <= std_logic_vector(unsigned(ram_do(j_par*8 + 7 downto j_par*8)) - cnt);
                    end if;
                end loop;
                
                if j = (32/SCALE_X * 8/DATA_WIDTH)-1 then
                    j_next <= 0;
                    if unsigned(timestamp) - unsigned(timestamp_last) >= ACCUMULATION_TIME_US then
                        timestamp_last_next <= timestamp;
                        if ready = '1' then
                            valid <= '1';
                            s_axis_tready <= '1';
                            state_next <= IDLE;
                        else
                            state_next <= WAIT_IDLE;
                        end if;
                    else
                        s_axis_tready <= '1';
                        state_next <= IDLE;
                    end if;
                else
                    j_next <= j + 1;
                    state_next <= READ;
                    x_next <= x;
                    y_next <= y;
                    pol_next <= pol;
                    vect_next <= vect;
                end if;
            when WAIT_IDLE =>
                s_axis_tready <= '0';
                resume_next <= '1';
                if ready = '1' then
                    s_axis_tready <= '1';
                    valid <= '1';
                    state_next <= IDLE;
                end if;
            when others =>
                state_next <= IDLE;
        end case;
    end process;


end prophesee;
