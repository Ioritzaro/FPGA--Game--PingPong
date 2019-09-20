----------------------------------------------------------------------------------
-- Company: Irt Embedded
-- Engineer: Ioritz Arocena
-- 
--
-- Create Date:    13:01:51 09/02/2019 
-- Project Name:   Ping -pong game
-- Target Devices: arty
-- Tool versions:  2017.2
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

package constants_package is

--Sync Generation constants

----***640x480@60Hz***--  Requires 25 MHz clock
--constant FRAME_WIDTH : natural := 640;
--constant FRAME_HEIGHT : natural := 480;

--constant H_FP : natural := 16; --H front porch width (pixels)
--constant H_PW : natural := 96; --H sync pulse width (pixels)
--constant H_MAX : natural := 800; --H total period (pixels)

--constant V_FP : natural := 10; --V front porch width (lines)
--constant V_PW : natural := 2; --V sync pulse width (lines)
--constant V_MAX : natural := 525; --V total period (lines)

--constant H_POL : std_logic := '0';
--constant V_POL : std_logic := '0';

----***800x600@60Hz***--  Requires 40 MHz clock
--constant FRAME_WIDTH : natural := 800;
--constant FRAME_HEIGHT : natural := 600;
--
--constant H_FP : natural := 40; --H front porch width (pixels)
--constant H_PW : natural := 128; --H sync pulse width (pixels)
--constant H_MAX : natural := 1056; --H total period (pixels)
--
--constant V_FP : natural := 1; --V front porch width (lines)
--constant V_PW : natural := 4; --V sync pulse width (lines)
--constant V_MAX : natural := 628; --V total period (lines)
--
--constant H_POL : std_logic := '1';
--constant V_POL : std_logic := '1';


----***1280x720@60Hz***-- Requires 74.25 MHz clock
--constant FRAME_WIDTH : natural := 1280;
--constant FRAME_HEIGHT : natural := 720;
--
--constant H_FP : natural := 110; --H front porch width (pixels)
--constant H_PW : natural := 40; --H sync pulse width (pixels)
--constant H_MAX : natural := 1650; --H total period (pixels)
--
--constant V_FP : natural := 5; --V front porch width (lines)
--constant V_PW : natural := 5; --V sync pulse width (lines)
--constant V_MAX : natural := 750; --V total period (lines)
--
--constant H_POL : std_logic := '1';
--constant V_POL : std_logic := '1';

--***1280x1024@60Hz***-- Requires 108 MHz clock
constant FRAME_WIDTH  : natural := 1280;
constant FRAME_HEIGHT : natural := 1024;

constant H_FP   : natural := 48; --H front porch width (pixels)
constant H_PW   : natural := 112; --H sync pulse width (pixels)
constant H_MAX  : natural := 1688; --H total period (pixels)

constant V_FP   : natural := 1; --V front porch width (lines)
constant V_PW   : natural := 3; --V sync pulse width (lines)
constant V_MAX  : natural := 1066; --V total period (lines)

constant H_POL  : std_logic := '1';
constant V_POL  : std_logic := '1';

--***1920x1080@60Hz***-- Requires 148.5 MHz pxl_clk
--constant FRAME_WIDTH : natural := 1920;
--constant FRAME_HEIGHT : natural := 1080;

--constant H_FP : natural := 88; --H front porch width (pixels)
--constant H_PW : natural := 44; --H sync pulse width (pixels)
--constant H_MAX : natural := 2200; --H total period (pixels)

--constant V_FP : natural := 4; --V front porch width (lines)
--constant V_PW : natural := 5; --V sync pulse width (lines)
--constant V_MAX : natural := 1125; --V total period (lines)

--constant H_POL : std_logic := '1';
--constant V_POL : std_logic := '1';

-- Color constants
constant BLACK                    : std_logic_vector(3 downto 0) := "0000";
constant WHITE                    : std_logic_vector(3 downto 0) := "1111";
constant PAD_BOX_COLOR   : std_logic_vector(3 downto 0) := "0000";

--Moving Box constants
constant BOX_TOP_MARGIN    : natural := 100;
constant BOX_BOT_MARGIN    : natural := 50;
constant BOX_WIDTH    : natural := 10;
constant BOX_CLK_DIV  : natural := 1000000; --MAX=(2^25 - 1)
constant BOX_X_MAX    : natural := (FRAME_WIDTH - BOX_WIDTH);
constant BOX_Y_MAX    : natural := (FRAME_HEIGHT - BOX_WIDTH - BOX_BOT_MARGIN);
constant BOX_X_MIN    : natural := 0;
constant BOX_Y_MIN    : natural := BOX_TOP_MARGIN;
constant BOX_X_INIT   : std_logic_vector(11 downto 0) := x"019";
constant BOX_Y_INIT   : std_logic_vector(11 downto 0) := x"200"; --512

-- PADS Constants
constant PAD_GAP                  : natural := 5;
constant PAD_WIDTH              : natural := 15;
constant PAD_HEIGHT             : natural := 170;
constant PAD_HALF_HEIGHT   : natural := 85;
constant PAD_CLK_DIV           : natural := 500000; --MAX=(2^25 - 1)
constant PAD_X_MARGIN        : natural := 10;
constant PAD_TOP_Y_MIN      : natural := 10;
constant PAD_SPEED              : natural := 2;
constant PAD_TOP_MARGIN    : natural := 100;
constant PAD_BOT_MARGIN    : natural := 50;
constant PAD_Y_INIT   : std_logic_vector(11 downto 0) := x"1AB";-- 512-170/2

-- Menu Constants
constant TOP_MENU : natural := PAD_TOP_MARGIN - PAD_GAP;
constant BOT_MENU : natural := PAD_BOT_MARGIN - PAD_GAP;
constant BORDER_MARGIN : natural :=5;
constant FRAME_MIDDLE : natural := 640;
constant MIDDLE_GAP : natural := 2;
constant BLACK_FRAME_TOP   : natural := 88;
constant BLACK_FRAME_BOT   : natural := 38;
constant BLACK_FRAME_WIDTH   : natural := 4;

end package constants_package;