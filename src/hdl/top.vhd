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

-- VGA SYNC Block
component vga_sync 
  port (  pxl_clk                 : in  STD_LOGIC;
             h_sync                 : out  STD_LOGIC;              
             v_sync                 : out  STD_LOGIC;
             h_counter            : out  STD_LOGIC_VECTOR (11 downto 0);              
             v_counter            : out  STD_LOGIC_VECTOR (11 downto 0)
          );
end component;

-- Ball Block
component ball 
  port (  pxl_clk                 : in  STD_LOGIC;
             left_pad_y_reg     : in  STD_LOGIC_VECTOR (11 downto 0);              
             right_pad_y_reg   : in  STD_LOGIC_VECTOR (11 downto 0);
             serve                   : in STD_LOGIC;
             box_y                  : out  STD_LOGIC_VECTOR (11 downto 0);              
             box_x                  : out  STD_LOGIC_VECTOR (11 downto 0)
          );
end component;

-- PAD Block
component pads 
  port (  pxl_clk            : in  STD_LOGIC;
              move_up       : in STD_LOGIC;              
              move_down  : in STD_LOGIC;
              pad_mode     : in STD_LOGIC;
              enable_AI      : in STD_LOGIC;
              box_y_pos    : in STD_LOGIC_VECTOR (11 downto 0);
              pad_y_reg     : out  STD_LOGIC_VECTOR (11 downto 0)
          );
end component;

-- Generic signals
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
signal box_y_reg    : std_logic_vector(11 downto 0) := BOX_Y_INIT;
signal update_box   : std_logic;
signal pixel_in_box : std_logic;

--Left pad
signal pixel_in_left_pad              : std_logic;
signal left_pad_y_reg                : std_logic_vector(11 downto 0) := PAD_Y_INIT;

-- Right pad
signal pixel_in_right_pad            : std_logic;
signal right_pad_y_reg              : std_logic_vector(11 downto 0) := PAD_Y_INIT;

begin

-- Clock divider   
clk_div_inst : clk_wiz_0
port map
  (-- Clock in ports
    CLK_IN1 => CLK_I,
   -- Clock out ports
    CLK_OUT1 => pxl_clk
  );

 ------------------------------------------------------
 -------         MOVING BALL LOGIC                ------
 ------------------------------------------------------ 
                
  Ping_pong_ball : ball
    port map
      (-- Clock in ports
        pxl_clk                 => pxl_clk,
        left_pad_y_reg     => left_pad_y_reg,
        right_pad_y_reg   => right_pad_y_reg,
        serve                   => sw(0),
        box_y                  => box_y_reg,
        box_x                  => box_x_reg 
      );
                
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
        enable_AI       => sw(3),
        box_y_pos     => box_y_reg,
        pad_y_reg     => left_pad_y_reg 
      );
 
	pixel_in_left_pad <= '1' when  (((v_cntr_reg >= left_pad_y_reg) and (v_cntr_reg < (left_pad_y_reg + PAD_HEIGHT))) and
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
        enable_AI       => sw(2),
        box_y_pos     => box_y_reg,
        pad_y_reg      => right_pad_y_reg 
      );
  
  pixel_in_right_pad <= '1' when (((v_cntr_reg >= right_pad_y_reg) and (v_cntr_reg < (right_pad_y_reg + PAD_HEIGHT))) and
                                                    ((h_cntr_reg >= (FRAME_WIDTH - PAD_X_MARGIN - PAD_WIDTH)) and (h_cntr_reg < (FRAME_WIDTH - PAD_X_MARGIN)))) else
                                    '0';			 
 
 ------------------------------------------------------
 -------         SYNC GENERATION                 ------
 ------------------------------------------------------
 
  sync_vga : vga_sync
    port map
      (-- Clock in ports
        pxl_clk          => pxl_clk,
        h_sync          => h_sync_reg,
        v_sync          => v_sync_reg,
        h_counter      => h_cntr_reg,
        v_counter      => v_cntr_reg 
      );
     
  active <= '1' when ((h_cntr_reg < FRAME_WIDTH) and (v_cntr_reg < FRAME_HEIGHT))else
            '0';

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
                       ("0000")   when (active = '1' and  ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1') and not(pixel_in_left_pad = '1') and not(pixel_in_right_pad = '1'))) else
                       PAD_BOX_COLOR;
                
  vga_blue <=   BLACK     when (active = '1' and ((((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg >BLACK_FRAME_TOP) and (v_cntr_reg < (BLACK_FRAME_TOP + BLACK_FRAME_WIDTH)))) or 
                                                                          (((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg > FRAME_HEIGHT - BLACK_FRAME_BOT - BLACK_FRAME_WIDTH) and (v_cntr_reg < (FRAME_HEIGHT - BLACK_FRAME_BOT)))) or
                                                                          (((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg<= BLACK_FRAME_TOP) and (v_cntr_reg > BORDER_MARGIN))))) else  
                       WHITE      when (active = '1' and (((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg <= TOP_MENU )) or 
                                                                            ((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg >= (FRAME_HEIGHT - BOT_MENU))) or
                                                                            ((h_cntr_reg  < BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT))) or 
                                                                            ((h_cntr_reg  > FRAME_WIDTH - BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT ))) or
                                                                            ((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg(5) <= '0')))) else
                       ("0000")   when (active = '1' and  ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1') and not(pixel_in_left_pad = '1') and not(pixel_in_right_pad = '1'))) else
                       PAD_BOX_COLOR;
              
  vga_green <= BLACK     when (active = '1' and ((((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg >BLACK_FRAME_TOP) and (v_cntr_reg < (BLACK_FRAME_TOP + BLACK_FRAME_WIDTH)))) or 
                                                                          (((h_cntr_reg  > BORDER_MARGIN) and (h_cntr_reg < FRAME_WIDTH - BORDER_MARGIN ) and (v_cntr_reg > FRAME_HEIGHT - BLACK_FRAME_BOT - BLACK_FRAME_WIDTH) and (v_cntr_reg < (FRAME_HEIGHT - BLACK_FRAME_BOT)))) or
                                                                          (((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg<= BLACK_FRAME_TOP) and (v_cntr_reg > BORDER_MARGIN))))) else  
                       WHITE      when (active = '1' and (((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg <= TOP_MENU )) or 
                                                                            ((h_cntr_reg  < FRAME_WIDTH) and (v_cntr_reg >= (FRAME_HEIGHT - BOT_MENU))) or
                                                                            ((h_cntr_reg  < BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT))) or 
                                                                            ((h_cntr_reg  > FRAME_WIDTH - BORDER_MARGIN) and (v_cntr_reg <= (FRAME_HEIGHT ))) or
                                                                            ((h_cntr_reg  > (FRAME_MIDDLE - MIDDLE_GAP)) and (h_cntr_reg  < (FRAME_MIDDLE + MIDDLE_GAP)) and (v_cntr_reg(5) <= '0')))) else
                       ("1000")   when (active = '1' and  ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1') and not(pixel_in_left_pad = '1') and not(pixel_in_right_pad = '1'))) else
                        PAD_BOX_COLOR;
           
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
