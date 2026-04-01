library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
Library xpm;
use xpm.vcomponents.all;

entity xpm_ram is
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
end xpm_ram;

architecture syn of xpm_ram is
    constant MEMORY_SIZE : integer := DATA_DEPTH * DATA_WIDTH;
    signal wea_vector, web_vector : std_logic_vector(0 downto 0);
begin

    wea_vector(0) <= wea;
    web_vector(0) <= web;
    
    xpm_memory_tdpram_inst : xpm_memory_tdpram
    generic map (
       ADDR_WIDTH_A => ADDR_WIDTH,               -- DECIMAL
       ADDR_WIDTH_B => ADDR_WIDTH,               -- DECIMAL
       AUTO_SLEEP_TIME => 0,            -- DECIMAL
       BYTE_WRITE_WIDTH_A => DATA_WIDTH,        -- DECIMAL
       BYTE_WRITE_WIDTH_B => DATA_WIDTH,        -- DECIMAL
       CASCADE_HEIGHT => 0,             -- DECIMAL
       CLOCKING_MODE => "common_clock", -- String
       ECC_BIT_RANGE => "7:0",          -- String
       ECC_MODE => "no_ecc",            -- String
       ECC_TYPE => "none",              -- String
       MEMORY_INIT_FILE => "none",      -- String
       MEMORY_INIT_PARAM => "0",        -- String
       MEMORY_OPTIMIZATION => "true",   -- String
       MEMORY_PRIMITIVE => RAM_TYPE,      -- String
       MEMORY_SIZE => MEMORY_SIZE,             -- DECIMAL
       MESSAGE_CONTROL => 0,            -- DECIMAL
       READ_DATA_WIDTH_A => DATA_WIDTH,         -- DECIMAL
       READ_DATA_WIDTH_B => DATA_WIDTH,         -- DECIMAL
       READ_LATENCY_A => 1,             -- DECIMAL
       READ_LATENCY_B => 1,             -- DECIMAL
       READ_RESET_VALUE_A => "0",       -- String
       READ_RESET_VALUE_B => "0",       -- String
       RST_MODE_A => "SYNC",            -- String
       RST_MODE_B => "SYNC",            -- String
       SIM_ASSERT_CHK => 0,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
       USE_MEM_INIT => 1,               -- DECIMAL
       USE_MEM_INIT_MMI => 0,           -- DECIMAL
       WAKEUP_TIME => "disable_sleep",  -- String
       WRITE_DATA_WIDTH_A => DATA_WIDTH,        -- DECIMAL
       WRITE_DATA_WIDTH_B => DATA_WIDTH,        -- DECIMAL
       WRITE_MODE_A => "no_change",     -- String
       WRITE_MODE_B => "no_change",     -- String
       WRITE_PROTECT => 1               -- DECIMAL
    )
    port map (
       dbiterra => open,             -- 1-bit output: Status signal to indicate double bit error occurrence on the data output of port A.
       dbiterrb => open,             -- 1-bit output: Status signal to indicate double bit error occurrence on the data output of port A.
       douta => doa,                   -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
       doutb => dob,                   -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
       sbiterra => open,             -- 1-bit output: Status signal to indicate single bit error occurrence on the data output of port A.
       sbiterrb => open,             -- 1-bit output: Status signal to indicate single bit error occurrence on the data output of port B.
       addra => addra,                   -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
       addrb => addrb,                   -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
       clka => clk,                     -- 1-bit input: Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE is "common_clock".
       clkb => clk,                     -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is "independent_clock". Unused when
                                         -- parameter CLOCKING_MODE is "common_clock".
    
       dina => dia,                     -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
       dinb => dib,                     -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
       ena => ena,                       -- 1-bit input: Memory enable signal for port A. Must be high on clock cycles when read or write operations
                                         -- are initiated. Pipelined internally.
    
       enb => enb,                       -- 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read or write operations
                                         -- are initiated. Pipelined internally.
    
       injectdbiterra => '0', -- 1-bit input: Controls double bit error injection on input data when ECC enabled (Error injection
                                         -- capability is not available in "decode_only" mode).
    
       injectdbiterrb => '0', -- 1-bit input: Controls double bit error injection on input data when ECC enabled (Error injection
                                         -- capability is not available in "decode_only" mode).
    
       injectsbiterra => '0', -- 1-bit input: Controls single bit error injection on input data when ECC enabled (Error injection
                                         -- capability is not available in "decode_only" mode).
    
       injectsbiterrb => '0', -- 1-bit input: Controls single bit error injection on input data when ECC enabled (Error injection
                                         -- capability is not available in "decode_only" mode).
    
       regcea => '0',                 -- 1-bit input: Clock Enable for the last register stage on the output data path.
       regceb => '0',                 -- 1-bit input: Clock Enable for the last register stage on the output data path.
       rsta => '0',                     -- 1-bit input: Reset signal for the final port A output register stage. Synchronously resets output port
                                         -- douta to the value specified by parameter READ_RESET_VALUE_A.
    
       rstb => '0',                     -- 1-bit input: Reset signal for the final port B output register stage. Synchronously resets output port
                                         -- doutb to the value specified by parameter READ_RESET_VALUE_B.
    
       sleep => '0',                   -- 1-bit input: sleep signal to enable the dynamic power saving feature.
       wea => wea_vector,                       -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector for port A input data port dina. 1
                                         -- bit wide when word-wide writes are used. In byte-wide write configurations, each bit controls the writing
                                         -- one byte of dina to address addra. For example, to synchronously write only bits [15-8] of dina when
                                         -- WRITE_DATA_WIDTH_A is 32, wea would be 4'b0010.
    
       web => web_vector                        -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector for port B input data port dinb. 1
                                         -- bit wide when word-wide writes are used. In byte-wide write configurations, each bit controls the writing
                                         -- one byte of dinb to address addrb. For example, to synchronously write only bits [15-8] of dinb when
                                         -- WRITE_DATA_WIDTH_B is 32, web would be 4'b0010.
    
    );

end architecture;
