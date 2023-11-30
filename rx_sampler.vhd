library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_sampler is
    port(
        clk    : in  std_logic;
        reset  : in  std_logic;
        enable : in  std_logic;
        rx     : in  std_logic;
        vote   : in  std_logic;
        sample : out std_logic
    );
end rx_sampler;

architecture behavioral of rx_sampler is
    
    -- Synchronizer signals
    signal rx_meta : std_logic;
    signal rx_sync : std_logic;

    -- Sampler x16 signals
    signal sampling_reg : std_logic_vector(15 downto 0);

    -- Majority voter signals
    signal sampled_vote : std_logic;

begin

    --------------------
    --  Synchronizer  --
    --------------------

    process(clk, reset)
    begin
        if reset = '1' then
            rx_meta <= '0';
            rx_sync <= '0';
        elsif rising_edge(clk) then
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end if;
    end process;

    -------------------
    --  Sampler x16  --
    -------------------

    process(clk, reset)
    begin
        if reset = '1' then
            sampling_reg <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                sampling_reg(15) <= rx_sync;
                sampling_reg(14 downto 0) <= sampling_reg(15 downto 1);
            end if;
        end if;
    end process;

    ----------------------
    --  Majority voter  --
    ----------------------

    process(sampling_reg)
        variable num_ones : integer;
        variable vote_result : std_logic;
    begin
        num_ones := 0;
        for i in 0 to 15 loop
            if sampling_reg(i) = '1' then
                num_ones := num_ones + 1;
            end if;
        end loop;

        vote_result := '0';
        if num_ones >= 8 then
            vote_result := '1';
        end if;

        sampled_vote <= vote_result;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            sample <= '0';
        elsif rising_edge(clk) then
            if vote = '1' then
                sample <= sampled_vote;
            end if;
        end if;
    end process;

end behavioral;

