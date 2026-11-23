library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity camera_i2c_command is
port(
    clk                                             :   in      std_logic;

    SW_1                                            :   in      std_logic;  -- '0' : CIS_2M, '1' : OV5640

    i2c_command_enable                              :   in      std_logic;
    i2c_command_data                                :   in      std_logic_vector(31 downto 0);
    i2c_command_end                                 :   out     std_logic;

    i2c_scl                                         :   inout   std_logic;
    i2c_sda                                         :   inout   std_logic
);
end entity;

architecture ar_camera_i2c_command of camera_i2c_command is

    type type_state is (idle, OV5640, CIS_2M);
    signal  sig_state : type_state := idle;

    signal  sig_i2c_command_data                    :           std_logic_vector(31 downto 0) := (others => '0');

    signal  sig_i2c_scl                             :           std_logic := '1';
    signal  sig_i2c_sda                             :           std_logic := '1';

    signal  sig_count                               :           std_logic_vector(7 downto 0) := (others => '0');

    signal  sig_i2c_command_end                     :           std_logic := '0';

begin

process(clk)
begin
    if(clk'event and clk = '1')then
        case sig_state is
            when    idle            =>
                sig_i2c_scl <= '1';
                sig_i2c_sda <= '1';

                if(i2c_command_enable = '1')then
                    sig_i2c_command_data <= i2c_command_data;

                    if(SW_1 = '1')then
                        sig_state <= OV5640;
                    else
                        sig_state <= CIS_2M;
                    end if;
                end if;
            when    OV5640  =>

                if(sig_count = 113)then
                    sig_count <= (others => '0');
                    sig_state <= idle;
                else
                    sig_count <= sig_count + 1;
                end if;

                case sig_count is
                    when    x"00"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '1';

                    when    x"01"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '0';

                    when    x"02"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= '0';

                    when    x"03"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(31);

                    when    x"04"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(31);

                    when    x"05"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(31);

                    when    x"06"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(30);

                    when    x"07"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(30);

                    when    x"08"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(30);

                    when    x"09"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(29);

                    when    x"0A"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(29);

                    when    x"0B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(29);

                    when    x"0C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(28);

                    when    x"0D"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(28);

                    when    x"0E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(28);

                    when    x"0F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(27);

                    when    x"10"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(27);

                    when    x"11"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(27);

                    when    x"12"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(26);

                    when    x"13"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(26);

                    when    x"14"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(26);

                    when    x"15"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(25);

                    when    x"16"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(25);

                    when    x"17"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(25);

                    when    x"18"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(24);

                    when    x"19"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(24);

                    when    x"1A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(24);

                    when    x"1B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"1C"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"1D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"1E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(23);

                    when    x"1F"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(23);

                    when    x"20"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(23);

                    when    x"21"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(22);

                    when    x"22"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(22);

                    when    x"23"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(22);

                    when    x"24"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(21);

                    when    x"25"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(21);

                    when    x"26"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(21);

                    when    x"27"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(20);

                    when    x"28"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(20);

                    when    x"29"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(20);

                    when    x"2A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(19);

                    when    x"2B"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(19);

                    when    x"2C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(19);

                    when    x"2D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(18);

                    when    x"2E"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(18);

                    when    x"2F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(18);

                    when    x"30"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(17);

                    when    x"31"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(17);

                    when    x"32"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(17);

                    when    x"33"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(16);

                    when    x"34"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(16);

                    when    x"35"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(16);

                    when    x"36"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"37"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"38"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"39"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(15);

                    when    x"3A"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(15);

                    when    x"3B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(15);

                    when    x"3C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(14);

                    when    x"3D"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(14);

                    when    x"3E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(14);

                    when    x"3F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(13);

                    when    x"40"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(13);

                    when    x"41"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(13);

                    when    x"42"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(12);

                    when    x"43"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(12);

                    when    x"44"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(12);

                    when    x"45"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(11);

                    when    x"46"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(11);

                    when    x"47"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(11);

                    when    x"48"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(10);

                    when    x"49"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(10);

                    when    x"4A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(10);

                    when    x"4B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(9);

                    when    x"4C"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(9);

                    when    x"4D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(9);

                    when    x"4E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(8);

                    when    x"4F"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(8);

                    when    x"50"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(8);

                    when    x"51"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"52"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"53"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"54"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(7);

                    when    x"55"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(7);

                    when    x"56"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(7);

                    when    x"57"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(6);

                    when    x"58"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(6);

                    when    x"59"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(6);

                    when    x"5A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(5);

                    when    x"5B"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(5);

                    when    x"5C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(5);

                    when    x"5D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(4);

                    when    x"5E"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(4);

                    when    x"5F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(4);

                    when    x"60"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(3);

                    when    x"61"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(3);

                    when    x"62"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(3);

                    when    x"63"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(2);

                    when    x"64"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(2);

                    when    x"65"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(2);

                    when    x"66"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(1);

                    when    x"67"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(1);

                    when    x"68"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(1);

                    when    x"69"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(0);

                    when    x"6A"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(0);

                    when    x"6B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(0);

                    when    x"6C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"6D"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"6E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"6F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= '0';

                    when    x"70"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '0';
                                        sig_i2c_command_end <= '1';

                    when    x"71"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '1';
                                        sig_i2c_command_end <= '0';

                    when    others  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '1';
                end case;

            when    CIS_2M  =>
                if(sig_count = 86)then
                    sig_count <= (others => '0');
                    sig_state <= idle;
                else
                    sig_count <= sig_count + 1;
                end if;

                case sig_count is
                    when    x"00"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '1';

                    when    x"01"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '0';

                    when    x"02"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= '0';

                    when    x"03"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(23);

                    when    x"04"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(23);

                    when    x"05"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(23);

                    when    x"06"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(22);

                    when    x"07"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(22);

                    when    x"08"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(22);

                    when    x"09"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(21);

                    when    x"0A"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(21);

                    when    x"0B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(21);

                    when    x"0C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(20);

                    when    x"0D"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(20);

                    when    x"0E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(20);

                    when    x"0F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(19);

                    when    x"10"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(19);

                    when    x"11"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(19);

                    when    x"12"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(18);

                    when    x"13"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(18);

                    when    x"14"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(18);

                    when    x"15"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(17);

                    when    x"16"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(17);

                    when    x"17"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(17);

                    when    x"18"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(16);

                    when    x"19"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(16);

                    when    x"1A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(16);

                    when    x"1B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"1C"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"1D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"1E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(15);

                    when    x"1F"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(15);

                    when    x"20"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(15);

                    when    x"21"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(14);

                    when    x"22"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(14);

                    when    x"23"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(14);

                    when    x"24"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(13);

                    when    x"25"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(13);

                    when    x"26"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(13);

                    when    x"27"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(12);

                    when    x"28"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(12);

                    when    x"29"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(12);

                    when    x"2A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(11);

                    when    x"2B"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(11);

                    when    x"2C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(11);

                    when    x"2D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(10);

                    when    x"2E"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(10);

                    when    x"2F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(10);

                    when    x"30"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(9);

                    when    x"31"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(9);

                    when    x"32"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(9);

                    when    x"33"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(8);

                    when    x"34"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(8);

                    when    x"35"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(8);

                    when    x"36"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"37"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"38"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"39"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(7);

                    when    x"3A"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(7);

                    when    x"3B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(7);

                    when    x"3C"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(6);

                    when    x"3D"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(6);

                    when    x"3E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(6);

                    when    x"3F"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(5);

                    when    x"40"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(5);

                    when    x"41"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(5);

                    when    x"42"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(4);

                    when    x"43"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(4);

                    when    x"44"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(4);

                    when    x"45"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(3);

                    when    x"46"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(3);

                    when    x"47"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(3);

                    when    x"48"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(2);

                    when    x"49"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(2);

                    when    x"4A"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(2);

                    when    x"4B"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(1);

                    when    x"4C"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(1);

                    when    x"4D"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(1);

                    when    x"4E"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(0);

                    when    x"4F"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= sig_i2c_command_data(0);

                    when    x"50"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= sig_i2c_command_data(0);

                    when    x"51"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"52"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= 'Z';

                    when    x"53"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= 'Z';

                    when    x"54"  =>
                                        sig_i2c_scl <= '0';
                                        sig_i2c_sda <= '0';

                    when    x"55"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '0';
                                        sig_i2c_command_end <= '1';

                    when    x"56"  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '1';
                                        sig_i2c_command_end <= '0';

                    when    others  =>
                                        sig_i2c_scl <= '1';
                                        sig_i2c_sda <= '1';
                end case;

            end case;
    end if;
end process;

i2c_command_end <= sig_i2c_command_end;

i2c_scl <= sig_i2c_scl;
i2c_sda <= sig_i2c_sda;

end architecture;
