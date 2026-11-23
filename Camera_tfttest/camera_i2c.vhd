library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity camera_i2c is
port(
    clk                                             :   in      std_logic;

    SW_1                                            :   in      std_logic;  -- '0' : CIS_2M, '1' : OV5640

    camera_RESETn                                   :   out     std_logic;
    camera_PWDN                                     :   out     std_logic;
    camera_scl                                      :   inout   std_logic;
    camera_sda                                      :   inout   std_logic
);
end entity;

architecture ar_camera_i2c of camera_i2c is

    type type_state is (initialize, command, check, idle);
    signal  sig_state : type_state := initialize;

    signal  sig_initialize_count                    :           std_logic_vector(7 downto 0) := (others => '0');

    signal  sig_SW_1_delay_1                        :           std_logic := '0';  -- '0' : CIS_2M, '1' : OV5640
    signal  sig_SW_1_delay_2                        :           std_logic := '0';  -- '0' : CIS_2M, '1' : OV5640

    signal  sig_camera_RESETn                       :           std_logic := '0';
    signal  sig_camera_PWDN                         :           std_logic := '0';

component camera_i2c_rom is
port(
    clk                                             :   in      std_logic;

    SW_1                                            :   in      std_logic;  -- '0' : CIS_2M, '1' : OV5640

    i2c_rom_address                                 :   in      std_logic_vector(7 downto 0);
    i2c_rom_data                                    :   out     std_logic_vector(31 downto 0);
    i2c_rom_final                                   :   out     std_logic
);
end component;

    signal  sig_i2c_rom_address                     :           std_logic_vector(7 downto 0) := (others => '0');
    signal  sig_i2c_rom_data                        :           std_logic_vector(31 downto 0);
    signal  sig_i2c_rom_final                       :           std_logic;

component camera_i2c_command is
port(
    clk                                             :   in      std_logic;

    SW_1                                            :   in      std_logic;  -- '0' : CIS_2M, '1' : OV5640

    i2c_command_enable                              :   in      std_logic;
    i2c_command_data                                :   in      std_logic_vector(31 downto 0);
    i2c_command_end                                 :   out     std_logic;

    i2c_scl                                         :   inout   std_logic;
    i2c_sda                                         :   inout   std_logic
);
end component;

    signal  sig_i2c_command_enable                  :           std_logic := '0';
    signal  sig_i2c_command_end                     :           std_logic;

begin

component_camera_i2c_rom : camera_i2c_rom
port map(
    clk                                             =>  clk,

    SW_1                                            =>  SW_1,

    i2c_rom_address                                 =>  sig_i2c_rom_address,
    i2c_rom_data                                    =>  sig_i2c_rom_data,
    i2c_rom_final                                   =>  sig_i2c_rom_final
);

component_camera_i2c_command : camera_i2c_command
port map(
    clk                                             =>  clk,

    SW_1                                            =>  SW_1,

    i2c_command_enable                              =>  sig_i2c_command_enable,
    i2c_command_data                                =>  sig_i2c_rom_data,
    i2c_command_end                                 =>  sig_i2c_command_end,

    i2c_scl                                         =>  camera_scl,
    i2c_sda                                         =>  camera_sda
);

process(clk)
begin
    if(clk'event and clk = '1')then
        sig_SW_1_delay_1    <=  SW_1;
        sig_SW_1_delay_2    <=  sig_SW_1_delay_1;
    end if;
end process;

process(clk)
begin
    if(clk'event and clk = '1')then
        case sig_state is
            when    initialize      =>
                if(sig_initialize_count = 1)then
                    sig_camera_RESETn <= '0';

                    if(SW_1 = '1')then
                        sig_camera_PWDN <= '1';
                    else
                        sig_camera_PWDN <= '0';
                    end if;

                    sig_initialize_count    <=  sig_initialize_count + 1;
                elsif(sig_initialize_count = 50)then
                    sig_camera_RESETn       <=  '1';

                    if(SW_1 = '1')then
                        sig_camera_PWDN <= '0';
                    else
                        sig_camera_PWDN <= '1';
                    end if;

                    sig_initialize_count    <=  sig_initialize_count + 1;
                elsif(sig_initialize_count = 100)then
                    sig_initialize_count <= (others => '0');
                    sig_state <= command;
                else
                    sig_initialize_count <= sig_initialize_count + 1;
                end if;

            when    command         =>
                if(sig_i2c_command_end = '1')then
                    sig_i2c_command_enable <= '0';
                    sig_state <= check;
                else
                    sig_i2c_command_enable <= '1';
                end if;

            when    check           =>
                if(sig_i2c_rom_final = '1')then
                    sig_i2c_rom_address <= (others => '0');
                    sig_state <= idle;
                else
                    sig_i2c_rom_address <= sig_i2c_rom_address + 1;
                    sig_state <= command;
                end if;

            when    idle            =>
                if(sig_SW_1_delay_1 = '1' and sig_SW_1_delay_2 = '0')then
                    sig_state <= initialize;
                elsif(sig_SW_1_delay_1 = '0' and sig_SW_1_delay_2 = '1')then
                    sig_state <= initialize;
                end if;

        end case;
    end if;
end process;

camera_RESETn <=    sig_camera_RESETn;
camera_PWDN   <=    sig_camera_PWDN;

end architecture;
