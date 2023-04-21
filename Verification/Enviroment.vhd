library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.Verification_package.all;

entity Enviroment is
end entity;


architecture rtl of Enviroment is

    -- clock
    constant clk_period : time := 31.25 ns; 
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- routing signals between components
    signal MEM_TO_TU : t_MEM_TO_TU;
    signal TU_TO_BFM : t_TU_TO_BFM;
    signal DEC_TO_BFM : t_DEC_TO_BFM;

    -- routing signals (Enviroment & BFM)
    signal com : t_bfm_com;
    signal response : std_logic := '0';

    -- COMMAND WORD SETTINGS
    signal address : unsigned(4 downto 0) := "11011";
    signal TR_bit : std_logic := '0';
    signal subaddress : unsigned(4 downto 0) := "10100";
    signal data_word_count : unsigned(4 downto 0) := "00110";

    -- DATA WORD SETTINGS
    signal bits : unsigned(15 downto 0) := "0000000111100001";

begin

    BFM_I: entity work.BFM(rtl)
        port map (
            pos_data_out => TU_TO_BFM.in_pos,
            neg_data_out => TU_TO_BFM.in_neg,
            command => com,
            response => response,
            data_from_TU =>  DEC_TO_BFM.data_from_TU,
            RX_done => DEC_TO_BFM.RX_done
        );

    TU_I: entity work.Terminal_unit(rtl)
        port map (
            clk =>    clk,
            reset =>  rst,
            in_pos => TU_TO_BFM.in_pos,
            in_neg =>  TU_TO_BFM.in_neg,
            out_pos => TU_TO_BFM.out_pos,
            out_neg =>  TU_TO_BFM.out_neg,
            mem_wr_en => MEM_TO_TU.write_en ,
            mem_rd_en =>  MEM_TO_TU.read_en,
            mem_wr_done => MEM_TO_TU.wr_done,
            mem_rd_done => MEM_TO_TU.rd_done,
            data_in =>  MEM_TO_TU.data_in,
            data_out =>  MEM_TO_TU.data_out,
            mem_subaddr => MEM_TO_TU.subaddr
        );

    MEMORY_I : entity work.Memory(rtl)
        port map (
            clk => clk,
            reset => rst,
            write_en => MEM_TO_TU.write_en,
            read_en => MEM_TO_TU.read_en,
            write_done => MEM_TO_TU.wr_done,
            read_done => MEM_TO_TU.rd_done,
            data_in => MEM_TO_TU.data_out,
            data_out => MEM_TO_TU.data_in,
            subaddress => MEM_TO_TU.subaddr
        );

    BFM_DECODER_I: entity work.ManchesterDecoder(rtl)
    port map (
        clk   => clk,
        reset => rst,
        in_positive => TU_TO_BFM.out_pos,
        in_negative =>  TU_TO_BFM.out_neg,
        DATA_OUT =>  DEC_TO_BFM.data_from_TU,
        RX_DONE =>  DEC_TO_BFM.RX_done
    );
    



















    MAIN: process

    begin
        rst <= '1';
        wait for 2 us;
        rst <= '0';
        wait for 2 us;
        
        -- send data
        Send_command_word(address, TR_bit, subaddress, data_word_count, com, response);
        for i in 0 to to_integer(data_word_count)-1 loop
            bits <= bits + 1;
            Send_data_word(bits, com, response);
        end loop;
        Receive_word(com, response);
        
        wait for 35 us;

        -- obtain (same) data
        TR_bit <= '1';
        data_word_count <= data_word_count;
        wait for 1 ns;
        Send_command_word(address, TR_bit, subaddress, data_word_count, com, response);
        for i in 0 to to_integer(data_word_count) loop
            Receive_word(com, response);
        end loop;

        wait for 35 us;

        -- send mode code (send status word)
        report "COM";
        TR_bit <= '0';
        subaddress <= "00000";
        data_word_count <= "00010";
        wait for 1 ns;
        Send_command_word(address, TR_bit, subaddress, data_word_count, com, response);
        Receive_word(com, response);

        wait;



    end process;









































    CLK_P: process
    begin
        for i in 0 to 30000 loop
            clk <= '1';
            wait for clk_period/2;
            clk <= '0';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

end architecture;