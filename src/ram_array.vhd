----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/17/2025 01:42:08 PM
-- Design Name: 
-- Module Name: ram_array - Behavioral
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

entity ram_array is
    generic (
        N_SCALES: integer := 5;
        ADDR_WIDTH: integer := 13;
        DATA_WIDTH: integer := 64;
        OUT_DATA_WIDTH: integer := 8;
        IMG_ROWS: integer := 80;
        IMG_COLS: integer := 80;
        FIXED_FRAMERATE: boolean := true
    );
    
    port (
        clk : in STD_LOGIC;
        rst_n : in STD_LOGIC;
        -- inputs
        acc_valid : in std_logic;
        ram_cnt : in integer range 0 to N_SCALES;
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
end ram_array;

architecture Behavioral of ram_array is

    constant DATA_DEPTH: integer := IMG_ROWS * IMG_COLS * 8 / DATA_WIDTH;
    constant OUT_DATA_DEPTH: integer := IMG_ROWS * IMG_COLS * 8 / OUT_DATA_WIDTH;
    
    component xpm_ram is
        generic (
            ADDR_WIDTH: integer := 20;
            DATA_WIDTH: integer := 8;
            DATA_DEPTH: integer := 2**20;
            RAM_TYPE: string := "block"
        );
        port(
            clk : in std_logic;
            ena : in std_logic;
            enb : in std_logic;
            wea : in std_logic;
            web : in std_logic;
            addra : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            addrb : in std_logic_vector(ADDR_WIDTH-1 downto 0);
            dia : in std_logic_vector(DATA_WIDTH-1 downto 0);
            dib : in std_logic_vector(DATA_WIDTH-1 downto 0);
            doa : out std_logic_vector(DATA_WIDTH-1 downto 0);
            dob : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component xpm_ram;
    
    signal ready : std_logic_vector(0 to N_SCALES);
    
    signal ram_en_w, ram_en_r, ram_we, ram_rst : std_logic_vector(0 to N_SCALES) := (others => '0');
    signal ram_addr_w, ram_addr_r : data_array(0 to N_SCALES)(ADDR_WIDTH-1 downto 0) := (others => (others => '0'));
    signal ram_di, ram_do_w, ram_do_r : data_array(0 to N_SCALES)(DATA_WIDTH-1 downto 0) := (others => (others => '0'));
    
    signal axis_ram_tready, axis_ram_tlast, axis_ram_tvalid : std_logic_vector(0 to N_SCALES);
    signal axis_ram_tdata : data_array(0 to N_SCALES)(OUT_DATA_WIDTH-1 downto 0);
    
    type state_type is (RESET, IDLE, PREREAD, READ);
    type state_array is array(0 to N_SCALES) of state_type;
    type idx_array is array(0 to N_SCALES) of integer range 0 to OUT_DATA_DEPTH-1;
    
    signal state, state_next : state_array;
    signal idx, idx_next : idx_array;

begin

    BRAMS: for i in 0 to N_SCALES generate
    
        out_bram : xpm_ram
            generic map (
                ADDR_WIDTH,
                DATA_WIDTH,
                DATA_DEPTH,
                "ultra"
            )
            port map (
                clk => clk,
                ena => ram_en_w(i),
                enb => ram_en_r(i),
                wea => ram_we(i),
                web => ram_rst(i),
                addra => ram_addr_w(i),
                addrb => ram_addr_r(i),
                dia => ram_di(i),
                dib => (others => '0'),
                doa => ram_do_w(i),
                dob => ram_do_r(i)
            );
    
        process(state(i), idx(i), acc_valid, ram_cnt, in_ram_addr, axis_ram_tready(i), ram_do_r(i))
            variable remain : integer range 0 to DATA_WIDTH / OUT_DATA_WIDTH - 1;
        begin
        
            ready(i) <= '0';
    
            state_next(i) <= state(i);
            idx_next(i) <= 0;
                
            ram_en_r(i) <= '0';
            ram_rst(i) <= '0';
            ram_addr_r(i) <= (others => '0');
            
            axis_ram_tvalid(i) <= '0';
            axis_ram_tlast(i) <= '0';
            axis_ram_tdata(i) <= (others => '0');
        
            case state(i) is
                when RESET =>
                    -- Write zeros in BRAM if it is not handled by the accumulator
                    if i /= ram_cnt then
                        ram_en_r(i) <= '1';
                        ram_rst(i) <= '1';
                        ram_addr_r(i) <= std_logic_vector(to_unsigned(idx(i), ram_addr_r(i)'length));
                    end if;
                    -- Until we reach the end
                    if idx(i) = DATA_DEPTH - 1 then
                        --ready(i) <= '1';
                        state_next(i) <= IDLE;
                    else
                        idx_next(i) <= idx(i) + 1;
                    end if;
                when IDLE =>
                    if i = (ram_cnt + 1) mod (N_SCALES + 1) then
                        ready(i) <= '1';
                    end if;
                    
                    if acc_valid = '1' then
                        state_next(i) <= PREREAD;
                    end if;
                when PREREAD =>
                    if i = ram_cnt then
                        state_next(i) <= IDLE;
                    else
                        state_next(i) <= READ;
                        if axis_ram_tready(i) = '1' then
                            ram_en_r(i) <= '1';
                        end if;
                    end if;
                when READ =>
                    -- Wait for AXI-Stream
                    if axis_ram_tready(i) = '1' then
                        remain := idx(i) mod (DATA_WIDTH / OUT_DATA_WIDTH);
                        -- Send data to AXI-Stream
                        axis_ram_tvalid(i) <= '1';
                        axis_ram_tdata(i) <= ram_do_r(i)(
                            (remain + 1) * OUT_DATA_WIDTH - 1
                            downto
                            remain * OUT_DATA_WIDTH
                        );
                            
                        -- Reset the BRAM that will be written next if it is the last time we read this address
                        if i = (ram_cnt + 1) mod (N_SCALES + 1)
                        and (idx(i) + 1) mod (DATA_WIDTH / OUT_DATA_WIDTH) = DATA_WIDTH / OUT_DATA_WIDTH - 1
                        then
                            ram_rst(i) <= '1';
                        end if;
                        
                        -- Wait for last element
                        if idx(i) = OUT_DATA_DEPTH - 1 then
                            axis_ram_tlast(i) <= '1';
                            --ready(i) <= '1';
                            state_next(i) <= IDLE;
                        else
                            idx_next(i) <= idx(i) + 1;
                            ram_en_r(i) <= '1';
                            ram_addr_r(i) <= std_logic_vector(to_unsigned(
                                (idx(i) + 1) * OUT_DATA_WIDTH / DATA_WIDTH,
                                ram_addr_r(i)'length
                            ));
                        end if;
                    else
                        -- Wait for last element
                        if idx(i) = OUT_DATA_DEPTH - 1 then
                            axis_ram_tlast(i) <= '1';
                            --ready(i) <= '1';
                            state_next(i) <= IDLE;
                        else
                            idx_next(i) <= idx(i);
                            ram_en_r(i) <= '1';
                            ram_addr_r(i) <= std_logic_vector(to_unsigned(idx(i) * OUT_DATA_WIDTH / DATA_WIDTH, ram_addr_r(0)'length));
                        end if;
                    end if;
                when others =>
                    state_next(i) <= RESET;
            end case;
            
        end process;
            
    end generate;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= (others => RESET);
                idx <= (others => 0);
            else
                state <= state_next;
                idx <= idx_next;
            end if;
        end if;
    end process;
    
    process(acc_valid, ram_cnt, in_ram_en, in_ram_we, in_ram_addr, in_ram_di, ram_do_w, axis_tready, axis_ram_tvalid, axis_ram_tdata, axis_ram_tlast)
        variable i : integer range 0 to N_SCALES - 1;
        variable out_idx : integer range 0 to N_SCALES;
    begin
        
        ram_en_w <= (others => '0');
        ram_we <= (others => '0');
        ram_addr_w <= (others => (others => '0'));
        ram_di <= (others => (others => '0'));
        
        axis_ram_tready <= (others => '0');
        axis_tvalid <= (others => '0');
        axis_tlast <= (others => '0');
        axis_tdata <= (others => (others => '0'));
        
        -- Plug the accumulator to the BRAM for writing
        ram_en_w(ram_cnt) <= in_ram_en;
        ram_we(ram_cnt) <= in_ram_we;
        ram_addr_w(ram_cnt) <= in_ram_addr;
        ram_di(ram_cnt) <= in_ram_di;
        in_ram_do <= ram_do_w(ram_cnt);
        
        -- Plug the AXI-Stream outputs of the BRAMs to their corresponding output, with the latest-written one first
        for i in 0 to N_SCALES - 1 loop
            out_idx := (N_SCALES + ram_cnt - i) mod (N_SCALES + 1);
            axis_ram_tready(out_idx) <= axis_tready(i);
            axis_tvalid(i) <= axis_ram_tvalid(out_idx);
            axis_tlast(i) <= axis_ram_tlast(out_idx);
            axis_tdata(i) <= axis_ram_tdata(out_idx);
        end loop;
    
    end process;
    
    -- Accumulation waits for the next BRAM to be read and erased
    acc_ready <= ready((ram_cnt + 1) mod (N_SCALES + 1));

end Behavioral;
