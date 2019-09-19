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
--use work.pads.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
  Port (  CLK_I     : in  STD_LOGIC;
          VGA_HS_O  : out  STD_LOGIC;
          VGA_VS_O  : out  STD_LOGIC;		   
          btn       : in  STD_LOGIC_VECTOR (3 downto 0);
          sw        : in  STD_LOGIC_VECTOR (3 downto 0);
          VGA_R     : out  STD_LOGIC_VECTOR (3 downto 0);
          VGA_B     : out  STD_LOGIC_VECTOR (3 downto 0);
          VGA_G     : out  STD_LOGIC_VECTOR (3 downto 0));
end top;

architecture Behavioral of top is

-- Vivado Clock divider IP
component clk_wiz_0
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic
 );
end component;

-- PAD Block
component pads 
  port (  pxl_clk            : in  STD_LOGIC;
              move_up       : in STD_LOGIC;              
              move_down  : in STD_LOGIC;
              pad_mode     : in STD_LOGIC;
              pad_y_reg     : out  STD_LOGIC_VECTOR (11 downto 0)
          );
end component;

signal pxl_clk  : std_logic;
signal active   : std_logic;

-- VGA Sync signals
signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal h_sync_reg : std_logic := not(H_POL);
signal v_sync_reg : std_logic := not(V_POL);
signal h_sync_dly_reg : std_logic := not(H_POL);
signal v_sync_dly_reg : std_logic :=  not(V_POL);

-- RGB signal
signal vga_red_reg    : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_green_reg  : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_blue_reg   : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_red    : std_logic_vector(3 downto 0);
signal vga_green  : std_logic_vector(3 downto 0);
signal vga_blue   : std_logic_vector(3 downto 0);

-- Ball movement signals
signal box_x_reg    : std_logic_vector(11 downto 0) := BOX_X_INIT;
signal box_x_dir    : std_logic := '1';
signal box_y_reg    : std_logic_vector(11 downto 0) := BOX_Y_INIT;
signal box_y_dir    : std_logic := '1';
signal box_cntr_reg : std_logic_vector(24 downto 0) := (others =>'0');

signal update_box   : std_logic;
signal pixel_in_box : std_logic;

--Pad signals

--Botton pad
signal left_pixel_in_pad              : std_logic;
signal left_pad_y_reg                : std_logic_vector(11 downto 0) := PAD_Y_INIT;

-- Top pad
signal right_pixel_in_pad            : std_logic;
signal right_pad_y_reg              : std_logic_vector(11 downto 0) := PAD_Y_INIT;

-- Game signals
signal game_over                      : std_logic := '0';

begin

-- Clock divider   
clk_div_inst : clk_wiz_0
port map
  (-- Clock in ports
    CLK_IN1 => CLK_I,
   -- Clock out ports
    CLK_OUT1 => pxl_clk
  );

  ----------------------------------------------------
  -------         Update RGB values            -------
  ----------------------------------------------------
  vga_red <=   BLACK      when (active = '1' and ((((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg >BLACK_FRAME_TOP) and (v_cntr_reg < (BLACK_FRAME_TOP + BLACK_FRAME_WIDTH)))) or 
                                                                          (((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg > FRAME_HEIGHT - BLACK_FRAME_BOT - BLACK_FRAME_WIDTH) and (v_cntr_reg < (FRAME_HEIGHT - BLACK_FRAME_BOT)))) or
                                                                          (((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg<= BLACK_FRAME_TOP) and (v_cntr_reg > BORDER_MARGIN))))) else  
                       WHITE      when (active = '1' and (((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg <= TOP_MENU )) or 
                                                                            ((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg >= (FRAME_HEIGHT - BOT_MENU))) or
                                                                            ((h_cntr_reg  < BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT))) or 
                                                                            ((h_cntr_reg  > FRAME_WIDTH - BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT ))) or
                                                                            ((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg(5) <= '0')))) else
                       ("0000")   when (active = '1' and  ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1') and not(left_pixel_in_pad = '1') and not(right_pixel_in_pad = '1'))) else
                       PAD_BOX_COLOR;
                
  vga_blue <=   BLACK     when (active = '1' and ((((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg >BLACK_FRAME_TOP) and (v_cntr_reg < (BLACK_FRAME_TOP + BLACK_FRAME_WIDTH)))) or 
                                                                          (((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg > FRAME_HEIGHT - BLACK_FRAME_BOT - BLACK_FRAME_WIDTH) and (v_cntr_reg < (FRAME_HEIGHT - BLACK_FRAME_BOT)))) or
                                                                          (((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg<= BLACK_FRAME_TOP) and (v_cntr_reg > BORDER_MARGIN))))) else  
                       WHITE      when (active = '1' and (((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg <= TOP_MENU )) or 
                                                                            ((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg >= (FRAME_HEIGHT - BOT_MENU))) or
                                                                            ((h_cntr_reg  < BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT))) or 
                                                                            ((h_cntr_reg  > FRAME_WIDTH - BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT ))) or
                                                                            ((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg(5) <= '0')))) else
                       ("0000")   when (active = '1' and  ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1') and not(left_pixel_in_pad = '1') and not(right_pixel_in_pad = '1'))) else
                       PAD_BOX_COLOR;
              
  vga_green <= BLACK     when (active = '1' and ((((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg >BLACK_FRAME_TOP) and (v_cntr_reg < (BLACK_FRAME_TOP + BLACK_FRAME_WIDTH)))) or 
                                                                          (((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg > FRAME_HEIGHT - BLACK_FRAME_BOT - BLACK_FRAME_WIDTH) and (v_cntr_reg < (FRAME_HEIGHT - BLACK_FRAME_BOT)))) or
                                                                          (((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg<= BLACK_FRAME_TOP) and (v_cntr_reg > BORDER_MARGIN))))) else  
                       WHITE      when (active = '1' and (((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg <= TOP_MENU )) or 
                                                                            ((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg >= (FRAME_HEIGHT - BOT_MENU))) or
                                                                            ((h_cntr_reg  < BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT))) or 
                                                                            ((h_cntr_reg  > FRAME_WIDTH - BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT ))) or
                                                                            ((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg(5) <= '0')))) else
                       ("1000")   when (active = '1' and  ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1') and not(left_pixel_in_pad = '1') and not(right_pixel_in_pad = '1'))) else
                        PAD_BOX_COLOR;
 
 ------------------------------------------------------
 -------         MOVING BOX LOGIC                ------
 ------------------------------------------------------ 
  --Move ball x and y axes
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (update_box = '1' and game_over = '0') then
        if (box_x_dir = '1') then
          box_x_reg <= box_x_reg + 2;
        else
          box_x_reg <= box_x_reg - 2;
        end if;
        if (box_y_dir = '1') then
          box_y_reg <= box_y_reg + 2;
        else
          box_y_reg <= box_y_reg - 2;
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
         elsif((box_x_dir = '1' and (box_x_reg > FRAME_WIDTH - PAD_X_MARGIN - PAD_WIDTH)) or (box_x_dir = '0' and (box_x_reg < PAD_X_MARGIN +PAD_WIDTH))) then
            game_over <= '1';
        elsif(sw(0) = '1') then			
            game_over <= '0';
        end if;
        if (((box_y_dir = '1') and (box_y_reg > BOX_Y_MAX - 1) ) or
            ((box_y_dir = '0') and (box_y_reg <= BOX_Y_MIN + 5))) then
              box_y_dir <= not(box_y_dir);
        end if;
      end if;
    end if;
  end process;
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
                
  pixel_in_box <= '1' when (((h_cntr_reg >= box_x_reg) and (h_cntr_reg < (box_x_reg + BOX_WIDTH))) and
                            ((v_cntr_reg >= box_y_reg) and (v_cntr_reg < (box_y_reg + BOX_WIDTH)))) else
                  '0';
                
  
 ------------------------------------------------------
 -------         MOVING PADDLE LOGIC                ------
 ------------------------------------------------------
 
  -- Left Player   
  left_pad : pads
    port map
      (-- Clock in ports
        pxl_clk           => pxl_clk,
        move_up       => btn(3),
        move_down  => btn(2),
        pad_mode     => sw(1),
        pad_y_reg     => left_pad_y_reg 
      );
 
	left_pixel_in_pad <= '1' when  (((v_cntr_reg >= left_pad_y_reg) and (v_cntr_reg < (left_pad_y_reg + PAD_HEIGHT))) and
                                                  ((h_cntr_reg >= PAD_X_MARGIN) and (h_cntr_reg < (PAD_X_MARGIN + PAD_WIDTH)))) else
                                  '0';
				  
	-- Right Player   
  right_pad : pads
    port map
      (-- Clock in ports
        pxl_clk           => pxl_clk,
        move_up       => btn(1),
        move_down   => btn(0),
        pad_mode      => sw(1),
        pad_y_reg      => right_pad_y_reg 
      );
  
  right_pixel_in_pad <= '1' when (((v_cntr_reg >= right_pad_y_reg) and (v_cntr_reg < (right_pad_y_reg + PAD_HEIGHT))) and
                                                    ((h_cntr_reg >= (FRAME_WIDTH - PAD_X_MARGIN - PAD_WIDTH)) and (h_cntr_reg < (FRAME_WIDTH - PAD_X_MARGIN)))) else
                                    '0';			 
 
 ------------------------------------------------------
 -------         SYNC GENERATION                 ------
 ------------------------------------------------------
 
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (h_cntr_reg = (H_MAX - 1)) then
        h_cntr_reg <= (others =>'0');
      else
        h_cntr_reg <= h_cntr_reg + 1;
      end if;
    end if;
  end process;
  
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
        v_cntr_reg <= (others =>'0');
      elsif (h_cntr_reg = (H_MAX - 1)) then
        v_cntr_reg <= v_cntr_reg + 1;
      end if;
    end if;
  end process;
  
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
        h_sync_reg <= H_POL;
      else
        h_sync_reg <= not(H_POL);
      end if;
    end if;
  end process;
  
  
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
        v_sync_reg <= V_POL;
      else
        v_sync_reg <= not(V_POL);
      end if;
    end if;
  end process;
  
  
  active <= '1' when ((h_cntr_reg < FRAME_WIDTH) and (v_cntr_reg < FRAME_HEIGHT))else
            '0';

  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      v_sync_dly_reg <= v_sync_reg;
      h_sync_dly_reg <= h_sync_reg;
      vga_red_reg <= vga_red;
      vga_green_reg <= vga_green;
      vga_blue_reg <= vga_blue;
    end if;
  end process;

  VGA_HS_O <= h_sync_dly_reg;
  VGA_VS_O <= v_sync_dly_reg;
  VGA_R <= vga_red_reg;
  VGA_G <= vga_green_reg;
  VGA_B <= vga_blue_reg;

end Behavioral;
