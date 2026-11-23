library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity camera_i2c_rom is
port(
    clk                                             :   in      std_logic;

    SW_1                                            :   in      std_logic;  -- '0' : CIS_2M, '1' : OV5640

    i2c_rom_address                                 :   in      std_logic_vector(7 downto 0);
    i2c_rom_data                                    :   out     std_logic_vector(31 downto 0);
    i2c_rom_final                                   :   out     std_logic
);
end entity;

architecture ar_camera_i2c_rom of camera_i2c_rom is

    signal  sig_i2c_rom_final                       :           std_logic := '0';

begin

process(clk)
begin
    if(clk'event and clk = '1')then
        if(SW_1 = '1')then
            case i2c_rom_address is

                -- ov5640_soft_reset
                when    x"00"   =>  i2c_rom_data        <=  x"78310311";
                                    sig_i2c_rom_final   <=  '0';
                when    x"01"   =>  i2c_rom_data        <=  x"78300882";

                -- ov5640_global_init_setting
                when    x"02"   =>  i2c_rom_data        <=  x"78300842";
                when    x"03"   =>  i2c_rom_data        <=  x"78310303";
                when    x"04"   =>  i2c_rom_data        <=  x"783017ff";
                when    x"05"   =>  i2c_rom_data        <=  x"783018ff";
                when    x"06"   =>  i2c_rom_data        <=  x"7830341a";
                when    x"07"   =>  i2c_rom_data        <=  x"78303713";
                when    x"08"   =>  i2c_rom_data        <=  x"78310801";
                when    x"09"   =>  i2c_rom_data        <=  x"78363036";
                when    x"0A"   =>  i2c_rom_data        <=  x"7836310e";
                when    x"0B"   =>  i2c_rom_data        <=  x"783632e2";
                when    x"0C"   =>  i2c_rom_data        <=  x"78363312";
                when    x"0D"   =>  i2c_rom_data        <=  x"783621e0";
                when    x"0E"   =>  i2c_rom_data        <=  x"783704a0";
                when    x"0F"   =>  i2c_rom_data        <=  x"7837035a";
                when    x"10"   =>  i2c_rom_data        <=  x"78371578";
                when    x"11"   =>  i2c_rom_data        <=  x"78371701";
                when    x"12"   =>  i2c_rom_data        <=  x"78370b60";
                when    x"13"   =>  i2c_rom_data        <=  x"7837051a";
                when    x"14"   =>  i2c_rom_data        <=  x"78390502";
                when    x"15"   =>  i2c_rom_data        <=  x"78390610";
                when    x"16"   =>  i2c_rom_data        <=  x"7839010a";
                when    x"17"   =>  i2c_rom_data        <=  x"78373112";
                when    x"18"   =>  i2c_rom_data        <=  x"78360008";
                when    x"19"   =>  i2c_rom_data        <=  x"78360133";
                when    x"1A"   =>  i2c_rom_data        <=  x"78302d60";
                when    x"1B"   =>  i2c_rom_data        <=  x"78362052";
                when    x"1C"   =>  i2c_rom_data        <=  x"78371b20";
                when    x"1D"   =>  i2c_rom_data        <=  x"78471c50";
                when    x"1E"   =>  i2c_rom_data        <=  x"783a1343";
                when    x"1F"   =>  i2c_rom_data        <=  x"783a1800";
                when    x"20"   =>  i2c_rom_data        <=  x"783a197c";
                when    x"21"   =>  i2c_rom_data        <=  x"78363513";
                when    x"22"   =>  i2c_rom_data        <=  x"78363603";
                when    x"23"   =>  i2c_rom_data        <=  x"78363440";
                when    x"24"   =>  i2c_rom_data        <=  x"78362201";
                when    x"25"   =>  i2c_rom_data        <=  x"783c0134";
                when    x"26"   =>  i2c_rom_data        <=  x"783c0428";
                when    x"27"   =>  i2c_rom_data        <=  x"783c0598";
                when    x"28"   =>  i2c_rom_data        <=  x"783c0600";
                when    x"29"   =>  i2c_rom_data        <=  x"783c0707";
                when    x"2A"   =>  i2c_rom_data        <=  x"783c0800";
                when    x"2B"   =>  i2c_rom_data        <=  x"783c091c";
                when    x"2C"   =>  i2c_rom_data        <=  x"783c0a9c";
                when    x"2D"   =>  i2c_rom_data        <=  x"783c0b40";
                when    x"2E"   =>  i2c_rom_data        <=  x"78381000";
                when    x"2F"   =>  i2c_rom_data        <=  x"78381110";
                when    x"30"   =>  i2c_rom_data        <=  x"78381200";
                when    x"31"   =>  i2c_rom_data        <=  x"78370864";
                when    x"32"   =>  i2c_rom_data        <=  x"78400102";
                when    x"33"   =>  i2c_rom_data        <=  x"7840051a";
                when    x"34"   =>  i2c_rom_data        <=  x"78300000";
                when    x"35"   =>  i2c_rom_data        <=  x"783004ff";
                when    x"36"   =>  i2c_rom_data        <=  x"78300e58";
                when    x"37"   =>  i2c_rom_data        <=  x"78302e00";
                when    x"38"   =>  i2c_rom_data        <=  x"78430030";
                when    x"39"   =>  i2c_rom_data        <=  x"78501f00";
                when    x"3A"   =>  i2c_rom_data        <=  x"78440e00";
                when    x"3B"   =>  i2c_rom_data        <=  x"785000a7";
                when    x"3C"   =>  i2c_rom_data        <=  x"78300802";

                -- ov5640_setting_30fps_VGA_640_480
                when    x"3D"   =>  i2c_rom_data        <=  x"783c0708";
                when    x"3E"   =>  i2c_rom_data        <=  x"78382041";
                when    x"3F"   =>  i2c_rom_data        <=  x"78382107";
                when    x"40"   =>  i2c_rom_data        <=  x"78381431";
                when    x"41"   =>  i2c_rom_data        <=  x"78381531";
                when    x"42"   =>  i2c_rom_data        <=  x"78380000";
                when    x"43"   =>  i2c_rom_data        <=  x"78380100";
                when    x"44"   =>  i2c_rom_data        <=  x"78380200";
                when    x"45"   =>  i2c_rom_data        <=  x"78380304";
                when    x"46"   =>  i2c_rom_data        <=  x"7838040a";
                when    x"47"   =>  i2c_rom_data        <=  x"7838053f";
                when    x"48"   =>  i2c_rom_data        <=  x"78380607";
                when    x"49"   =>  i2c_rom_data        <=  x"7838079b";
                when    x"4A"   =>  i2c_rom_data        <=  x"78380802";
                when    x"4B"   =>  i2c_rom_data        <=  x"78380980";
                when    x"4C"   =>  i2c_rom_data        <=  x"78380a01";
                when    x"4D"   =>  i2c_rom_data        <=  x"78380be0";
                when    x"4E"   =>  i2c_rom_data        <=  x"78380c07";
                when    x"4F"   =>  i2c_rom_data        <=  x"78380d68";
                when    x"50"   =>  i2c_rom_data        <=  x"78380e03";
                when    x"51"   =>  i2c_rom_data        <=  x"78380fd8";
                when    x"52"   =>  i2c_rom_data        <=  x"78381306";
                when    x"53"   =>  i2c_rom_data        <=  x"78361800";
                when    x"54"   =>  i2c_rom_data        <=  x"78361229";
                when    x"55"   =>  i2c_rom_data        <=  x"78370952";
                when    x"56"   =>  i2c_rom_data        <=  x"78370c03";
                when    x"57"   =>  i2c_rom_data        <=  x"783a020b";
                when    x"58"   =>  i2c_rom_data        <=  x"783a0388";
                when    x"59"   =>  i2c_rom_data        <=  x"783a140b";
                when    x"5A"   =>  i2c_rom_data        <=  x"783a1588";
                when    x"5B"   =>  i2c_rom_data        <=  x"78400402";
                when    x"5C"   =>  i2c_rom_data        <=  x"7830021c";
                when    x"5D"   =>  i2c_rom_data        <=  x"783006c3";
                when    x"5E"   =>  i2c_rom_data        <=  x"78471303";
                when    x"5F"   =>  i2c_rom_data        <=  x"78440704";
                when    x"60"   =>  i2c_rom_data        <=  x"78460b35";
                when    x"61"   =>  i2c_rom_data        <=  x"78460c22";
                when    x"62"   =>  i2c_rom_data        <=  x"78483722";
                when    x"63"   =>  i2c_rom_data        <=  x"78382402";
                when    x"64"   =>  i2c_rom_data        <=  x"785001a3";
                when    x"65"   =>  i2c_rom_data        <=  x"7830341a";
                when    x"66"   =>  i2c_rom_data        <=  x"78303511";
                when    x"67"   =>  i2c_rom_data        <=  x"78303646";
                when    x"68"   =>  i2c_rom_data        <=  x"78303713";
                when    x"69"   =>  i2c_rom_data        <=  x"78350300";

                -- Doo
                when    x"6A"   =>  i2c_rom_data        <=  x"78501F01";    -- FORMAT MUX CONTROL : ISP RGB
                when    x"6B"   =>  i2c_rom_data        <=  x"7850202A";    -- DITHER CTRL : RGB565/555

                when    x"6C"   =>  i2c_rom_data        <=  x"78430061";    -- FORMAT CONTROL RG : RGB(r[4:0],g[5:3],g[2:0],b[4:0])

                when    x"6D"   =>  i2c_rom_data        <=  x"78382002";    -- TIMING TC REG20 : Sensor vflip
                when    x"6E"   =>  i2c_rom_data        <=  x"78382100";    -- TIMING TC REG21 : Sensor and ISP mirror disabled

                -- test pattern
--                when    x"6F"   =>  i2c_rom_data        <=   x"78503D" & '0' & "000" & x"0";    -- normal
--                when    x"6F"   =>  i2c_rom_data        <=   x"78503D" & '1' & "000" & x"0";    -- test pattern

                                    sig_i2c_rom_final   <=  '1';
                when    others  =>  i2c_rom_data        <=  (others => '0');
            end case;
        else
            case i2c_rom_address is
                when    x"00"   =>  i2c_rom_data        <=  x"00400011";
                                    sig_i2c_rom_final   <=  '0';
                when    x"01"   =>  i2c_rom_data        <=  x"00400118";
                when    x"02"   =>  i2c_rom_data        <=  x"00400000";
                when    x"03"   =>  i2c_rom_data        <=  x"0040062C";
                when    x"04"   =>  i2c_rom_data        <=  x"00408000";
                when    x"05"   =>  i2c_rom_data        <=  x"00408100";
                when    x"06"   =>  i2c_rom_data        <=  x"00408200";
                when    x"07"   =>  i2c_rom_data        <=  x"00408300";
                when    x"08"   =>  i2c_rom_data        <=  x"00408402";
                when    x"09"   =>  i2c_rom_data        <=  x"00408520";
                when    x"0A"   =>  i2c_rom_data        <=  x"00408603";
                when    x"0B"   =>  i2c_rom_data        <=  x"004087C0";
                                    sig_i2c_rom_final   <=  '1';
                when    others  =>  i2c_rom_data        <=  (others => '0');
            end case;
        end if;
    end if;
end process;

i2c_rom_final <= sig_i2c_rom_final;

end architecture;
