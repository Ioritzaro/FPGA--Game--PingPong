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

entity ball is
  Port (  pxl_clk                 : in  STD_LOGIC;
             left_pad_y_reg     : in  STD_LOGIC_VECTOR (11 downto 0);              
             right_pad_y_reg   : in  STD_LOGIC_VECTOR (11 downto 0);
             serve                  : in STD_LOGIC;
             box_y                  : out  STD_LOGIC_VECTOR (11 downto 0);              
             box_x                  : out  STD_LOGIC_VECTOR (11 downto 0));
end ball;

architecture Behavioral of ball is	

-- Ball movement signals
signal box_x_reg     : std_logic_vector(11 downto 0) := BOX_X_INIT;
signal box_x_dir      : std_logic := '1';
signal box_y_reg     : std_logic_vector(11 downto 0) := BOX_Y_INIT;
signal box_y_dir      : std_logic := '1';
signal box_cntr_reg : std_logic_vector(24 downto 0) := (others =>'0');
signal update_box   : std_logic;
signal turn_counter  : std_logic_vector(7 downto 0) := x"00";
signal speed            : std_logic_vector(7 downto 0) := x"02";
signal update_speed: std_logic_vector(7 downto 0) := x"04";
-- Game signals
signal game_over                      : std_logic := '0';


begin
  
   --Update ball
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (box_cntr_reg = (BOX_CLK_DIV - 1)) then
        box_cntr_reg <= (others=>'0');
      else
        box_cntr_reg <= box_cntr_reg + 1;     
      end if;
    end if;
  end process;
  
  update_box <= '1' when (box_cntr_reg = (BOX_CLK_DIV - 1)) else
                '0';
  
  --Move ball x and y axes
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (update_box = '1' and game_over = '0') then
        if (box_x_dir = '1') then
          box_x_reg <= box_x_reg + speed;
        else
          box_x_reg <= box_x_reg - speed;
        end if;
        if (box_y_dir = '1') then
          box_y_reg <= box_y_reg + speed;
        else
          box_y_reg <= box_y_reg - speed;
        end if;
      elsif (update_box = '1' and game_over = '1') then
        box_x_reg   <=  BOX_X_INIT;
        box_y_reg   <=  BOX_Y_INIT;
      end if;
    end if;
  end process;
  
  --Bounce ball if pad collision or stop if screen edge
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (update_box = '1') then
        if (((box_x_dir = '1') and (box_x_reg > FRAME_WIDTH - PAD_X_MARGIN - PAD_WIDTH) and (box_y_reg >= right_pad_y_reg) and (box_y_reg <= right_pad_y_reg + PAD_HEIGHT)) or 
            (box_x_dir = '0' and (box_x_reg < PAD_X_MARGIN +PAD_WIDTH) and (box_y_reg >= left_pad_y_reg) and (box_y_reg <= left_pad_y_reg + PAD_HEIGHT))) then
              box_x_dir <= not(box_x_dir);
              turn_counter <= turn_counter + 1;
         elsif((box_x_dir = '1' and (box_x_reg > FRAME_WIDTH - PAD_X_MARGIN - PAD_WIDTH)) or (box_x_dir = '0' and (box_x_reg < PAD_X_MARGIN +PAD_WIDTH))) then
            game_over <= '1';
            turn_counter <= (others => '0');
        elsif(serve = '1') then			
            game_over <= '0';
        end if;
        if (((box_y_dir = '1') and (box_y_reg > BOX_Y_MAX - 1) ) or
            ((box_y_dir = '0') and (box_y_reg <= BOX_Y_MIN + 5))) then
              box_y_dir <= not(box_y_dir);
        end if;
      end if;
    end if;
  end process;
  
  --Update Speed
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (turn_counter = update_speed) then
        speed <= speed + 2;
        update_speed <= update_speed + 4;
       elsif ( game_over = '1') then
         speed <= x"02";         
         update_speed <= x"04";
      end if;
    end if;
  end process;
  
  box_y <= box_y_reg;
  box_x <= box_x_reg;  
  
  end Behavioral;