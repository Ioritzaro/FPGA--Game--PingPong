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

library work;
use work.constants_package.all;

entity pads is
  Port (  pxl_clk           : in  STD_LOGIC;
              move_up     : in STD_LOGIC;              
              move_down : in STD_LOGIC;
              pad_mode    : in STD_LOGIC;
              enable_AI      : in STD_LOGIC;
              box_y_pos   : in STD_LOGIC_VECTOR (11 downto 0);
              pad_y_reg     : out  STD_LOGIC_VECTOR (11 downto 0));
end pads;

architecture Behavioral of pads is	

--Pad signals
signal update_pad              : std_logic;
signal pad_cntr_reg            : std_logic_vector(24 downto 0) := (others =>'0');
signal up_button	              : std_logic;
signal up_button_reg	        : std_logic;
signal down_button	          : std_logic;
signal down_button_reg	    : std_logic;
signal pad_y                      : std_logic_vector(11 downto 0) := PAD_Y_INIT;
signal pad_move_up           : std_logic := '1';

begin
  
   --Update pads
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (pad_cntr_reg = (PAD_CLK_DIV - 1)) then
        pad_cntr_reg <= (others=>'0');
      else
        pad_cntr_reg <= pad_cntr_reg + 1;     
      end if;
    end if;
  end process; 
 
  update_pad <= '1' when pad_cntr_reg = (PAD_CLK_DIV - 1) else
                '0';
  
  
  -- Detect Up/Down ----
	process(pxl_clk)
	begin
    if (rising_edge(pxl_clk)) then
      up_button             <=  move_up;
      up_button_reg      <=  up_button;
      down_button        <=  move_down;
      down_button_reg  <= down_button;
      if ((up_button_reg = '0') and (up_button = '1')) then  --- Right button rise edge
        pad_move_up <= '1';
	    elsif ((down_button_reg = '0') and (down_button= '1')) then  --- Left button rise edge
	      pad_move_up <= '0';
		end if;
	end if;
	end process;
	
  -- Calculate PAD Y axis value
  process (pxl_clk)
	begin
    if (rising_edge(pxl_clk)) then
      -- AI player
      if ((update_pad = '1') and (enable_AI = '1')) then
        if(((pad_y + PAD_HALF_HEIGHT) < box_y_pos) and (pad_y < FRAME_HEIGHT - (PAD_HEIGHT + PAD_BOT_MARGIN))) then
           pad_y <= pad_y + PAD_SPEED;
        elsif (((pad_y + PAD_HALF_HEIGHT) >= box_y_pos) and (pad_y > PAD_TOP_MARGIN)) then
          pad_y <= pad_y - PAD_SPEED;
        end if;      
      -- Slide mode
      elsif ((update_pad = '1') and (pad_mode = '1')) then
        if ((pad_move_up = '1') and (pad_y < FRAME_HEIGHT - (PAD_HEIGHT + PAD_BOT_MARGIN))) then
          pad_y <= pad_y + PAD_SPEED;
        elsif ((pad_move_up = '0') and (pad_y > PAD_TOP_MARGIN)) then
          pad_y <= pad_y - PAD_SPEED;
        end if;
      -- Step mode
      elsif ((update_pad = '1') and (pad_mode = '0'))then
        if ((up_button = '1') and (pad_y < FRAME_HEIGHT - (PAD_HEIGHT + PAD_BOT_MARGIN))) then
          pad_y <= pad_y + PAD_SPEED;
        elsif ((down_button = '1') and (pad_y > PAD_TOP_MARGIN)) then
          pad_y <= pad_y - PAD_SPEED;
        end if;
      end if;
    end if;
  end process;
  
  pad_y_reg <= pad_y;
  
  
  end Behavioral;
