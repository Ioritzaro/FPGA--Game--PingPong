----------------------------------------------------------------------------------
-- Company: Digilent
-- Engineer: Arthur Brown
-- 
--
-- Create Date:    13:01:51 02/15/2013 
-- Project Name:   pmodvga
-- Target Devices: arty
-- Tool versions:  2016.4
-- Additional Comments: 
--
-- Copyright Digilent 2017
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( CLK_I : in  STD_LOGIC;
           VGA_HS_O : out  STD_LOGIC;
           VGA_VS_O : out  STD_LOGIC;		   
           btn : in  STD_LOGIC_VECTOR (3 downto 0);
           sw : in  STD_LOGIC_VECTOR (3 downto 0);
           VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
           VGA_G : out  STD_LOGIC_VECTOR (3 downto 0));
end top;

architecture Behavioral of top is

component clk_wiz_0
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic
 );
end component;

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
constant FRAME_WIDTH : natural := 1280;
constant FRAME_HEIGHT : natural := 1024;

constant H_FP : natural := 48; --H front porch width (pixels)
constant H_PW : natural := 112; --H sync pulse width (pixels)
constant H_MAX : natural := 1688; --H total period (pixels)

constant V_FP : natural := 1; --V front porch width (lines)
constant V_PW : natural := 3; --V sync pulse width (lines)
constant V_MAX : natural := 1066; --V total period (lines)

constant H_POL : std_logic := '1';
constant V_POL : std_logic := '1';

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

--Moving Box constants
constant BOX_WIDTH : natural := 15;
constant BOX_CLK_DIV : natural := 1000000; --MAX=(2^25 - 1)

constant BOX_X_MAX : natural := (FRAME_WIDTH - BOX_WIDTH);
constant BOX_Y_MAX : natural := (FRAME_HEIGHT - BOX_WIDTH);

constant BOX_X_MIN : natural := 0;
constant BOX_Y_MIN : natural := 0;

constant BOX_X_INIT : std_logic_vector(11 downto 0) := x"000";
constant BOX_Y_INIT : std_logic_vector(11 downto 0) := x"190"; --400

signal pxl_clk : std_logic;
signal active : std_logic;

signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

signal h_sync_reg : std_logic := not(H_POL);
signal v_sync_reg : std_logic := not(V_POL);

signal h_sync_dly_reg : std_logic := not(H_POL);
signal v_sync_dly_reg : std_logic :=  not(V_POL);

signal vga_red_reg : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_green_reg : std_logic_vector(3 downto 0) := (others =>'0');
signal vga_blue_reg : std_logic_vector(3 downto 0) := (others =>'0');

signal vga_red : std_logic_vector(3 downto 0);
signal vga_green : std_logic_vector(3 downto 0);
signal vga_blue : std_logic_vector(3 downto 0);

signal box_x_reg : std_logic_vector(11 downto 0) := BOX_X_INIT;
signal box_x_dir : std_logic := '1';
signal box_y_reg : std_logic_vector(11 downto 0) := BOX_Y_INIT;
signal box_y_dir : std_logic := '1';
signal box_cntr_reg : std_logic_vector(24 downto 0) := (others =>'0');

signal down_pad_cntr_reg : std_logic_vector(24 downto 0) := (others =>'0');

signal update_box : std_logic;
signal pixel_in_box : std_logic;

constant PAD_WIDTH : natural := 150;
constant PAD_HEIGHT : natural := 15;

constant PAD_CLK_DIV : natural := 500000; --MAX=(2^25 - 1)

signal update_pad : std_logic;
signal bot_pixel_in_pad : std_logic;
signal top_pixel_in_pad : std_logic;

signal bot_push_button_sig	: std_logic;
signal bot_push_button_sig1	: std_logic;
signal bot_push_button_sig2	: std_logic;
signal bot_push_button_sig3	: std_logic;

signal bot_pad_x_reg : std_logic_vector(11 downto 0) := BOX_X_INIT;
signal bot_Move_Right : std_logic := '1';

signal top_push_button_sig	: std_logic;
signal top_push_button_sig1	: std_logic;
signal top_push_button_sig2	: std_logic;
signal top_push_button_sig3	: std_logic;

signal top_pad_x_reg : std_logic_vector(11 downto 0) := BOX_X_INIT;
signal top_Move_Right : std_logic := '1';


constant PAD_BOT_Y_MAX : natural := 1000;
constant PAD_TOP_Y_MIN : natural := 10;


signal game_over : std_logic := '0';


begin
  
   
clk_div_inst : clk_wiz_0
  port map
   (-- Clock in ports
    CLK_IN1 => CLK_I,
    -- Clock out ports
    CLK_OUT1 => pxl_clk);

  
  ----------------------------------------------------
  -------         TEST PATTERN LOGIC           -------
  ----------------------------------------------------
  -- vga_red <= h_cntr_reg(6 downto 3) when (active = '1' and ((h_cntr_reg < 512 and v_cntr_reg < 256) and h_cntr_reg(8) = '1')) else
              -- (others=>'1')         when (active = '1' and ((h_cntr_reg < 512 and not(v_cntr_reg < 256)) and not(pixel_in_box = '1'))) else
              -- (others=>'1')         when (active = '1' and ((not(h_cntr_reg < 512) and (v_cntr_reg(8) = '1' and h_cntr_reg(3) = '1')) or
                                          -- (not(h_cntr_reg < 512) and (v_cntr_reg(8) = '0' and v_cntr_reg(3) = '1')))) else
              -- (others=>'0');
                
  -- vga_blue <= h_cntr_reg(5 downto 2) when (active = '1' and ((h_cntr_reg < 512 and v_cntr_reg < 256) and  h_cntr_reg(6) = '1')) else
              -- (others=>'1')          when (active = '1' and ((h_cntr_reg < 512 and not(v_cntr_reg < 256)) and not(pixel_in_box = '1'))) else 
              -- (others=>'1')          when (active = '1' and ((not(h_cntr_reg < 512) and (v_cntr_reg(8) = '1' and h_cntr_reg(3) = '1')) or
                                           -- (not(h_cntr_reg < 512) and (v_cntr_reg(8) = '0' and v_cntr_reg(3) = '1')))) else
              -- (others=>'0');  
              
  -- vga_green <= h_cntr_reg(4 downto 1) when (active = '1' and ((h_cntr_reg < 512 and v_cntr_reg < 256) and h_cntr_reg(7) = '1')) else
              -- (others=>'1')           when (active = '1' and ((h_cntr_reg < 512 and not(v_cntr_reg < 256)) and not(pixel_in_box = '1'))) else 
              -- (others=>'1')           when (active = '1' and ((not(h_cntr_reg < 512) and (v_cntr_reg(8) = '1' and h_cntr_reg(3) = '1')) or
                                            -- (not(h_cntr_reg < 512) and (v_cntr_reg(8) = '0' and v_cntr_reg(3) = '1')))) else
              -- (others=>'0');
  vga_red <=  ---(others=>'1')         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (game_over = '1'))) else
			  ("0000")         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (bot_pixel_in_pad = '1'))) else
			  ("0000")         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (top_pixel_in_pad = '1'))) else
			  ("0011")              when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1'))) else
              (others=>'1');  
                
  vga_blue <= ---(others=>'1')         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (game_over = '1'))) else
			  ("0000")         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (bot_pixel_in_pad = '1'))) else
			  ("0000")         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (top_pixel_in_pad = '1'))) else
			  ("0011")              when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1'))) else
              (others=>'1');  
              
  vga_green <=---(others=>'1')         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (game_over = '1'))) else
			  ("1111")         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (bot_pixel_in_pad = '1'))) else 
			  ("1111")         when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and (top_pixel_in_pad = '1'))) else
			  ("0011")              when (active = '1' and ((h_cntr_reg < FRAME_WIDTH and not(v_cntr_reg < 1)) and not(pixel_in_box = '1'))) else 
              (others=>'1');
              
 
 ------------------------------------------------------
 -------         MOVING BOX LOGIC                ------
 ------------------------------------------------------ 
 
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
		box_x_reg <=  BOX_X_INIT;
		box_y_reg <=  BOX_Y_INIT;
      end if;
    end if;
  end process;
      
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (update_box = '1') then
        if ((box_x_dir = '1' and (box_x_reg > BOX_X_MAX - 1)) or (box_x_dir = '0' and (box_x_reg < BOX_X_MIN + 5))) then
          box_x_dir <= not(box_x_dir);
        end if;
		if (((box_y_dir = '1') and (box_y_reg > PAD_BOT_Y_MAX - 1) and (box_x_reg >= bot_pad_x_reg) and (box_x_reg <= bot_pad_x_reg + PAD_WIDTH)) or
		   ((box_y_dir = '0') and (box_y_reg <= PAD_TOP_Y_MIN + 5) and (box_x_reg >= top_pad_x_reg) and (box_x_reg <= top_pad_x_reg + PAD_WIDTH))) then
          box_y_dir <= not(box_y_dir);
		elsif(sw(0) = '1') then			
		  game_over <= '0';
		elsif ((box_y_dir = '1' and (box_y_reg > BOX_Y_MAX - 1)) or (box_y_dir = '0' and (box_y_reg < BOX_Y_MIN + 5))) then
		  game_over <= '1';
        end if;
      end if;
    end if;
  end process;
  
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
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (down_pad_cntr_reg = (PAD_CLK_DIV - 1)) then
        down_pad_cntr_reg <= (others=>'0');
      else
        down_pad_cntr_reg <= down_pad_cntr_reg + 1;     
      end if;
    end if;
  end process; 
 
  update_pad <= '1' when down_pad_cntr_reg = (PAD_CLK_DIV - 1) else
                '0';

	-- BOTTON PLAYER ----
	process(pxl_clk)
	begin
    if (rising_edge(pxl_clk)) then
		bot_push_button_sig <=  btn(0);
		bot_push_button_sig1 <=  bot_push_button_sig;
		bot_push_button_sig2 <=  btn(1);
		bot_push_button_sig3 <=  bot_push_button_sig2;
		if  bot_push_button_sig1 = '0' and bot_push_button_sig= '1' then  --- Rise edge
			bot_Move_Right <= '1';
	    elsif bot_push_button_sig3 = '0' and bot_push_button_sig2= '1' then  --- Rise edge
	        bot_Move_Right <= '0';
		end if;
	end if;
	end process;
	
	process (pxl_clk)
	begin
    if (rising_edge(pxl_clk)) then
      if (update_pad = '1' and sw(1) = '1') then
        if ((bot_Move_Right = '1') and (bot_pad_x_reg < BOX_X_MAX - 150)) then
          bot_pad_x_reg <= bot_pad_x_reg + 1;
        elsif ((bot_Move_Right = '0') and (bot_pad_x_reg > BOX_X_MIN + 5)) then
          bot_pad_x_reg <= bot_pad_x_reg - 1;
        end if;
	  elsif (update_pad = '1' and sw(1) = '0') then
	    if ((bot_push_button_sig = '1') and (bot_pad_x_reg < BOX_X_MAX - 150)) then
          bot_pad_x_reg <= bot_pad_x_reg + 1;
        elsif ((bot_push_button_sig2 = '1') and (bot_pad_x_reg > BOX_X_MIN + 5)) then
          bot_pad_x_reg <= bot_pad_x_reg - 1;
        end if;
      end if;
    end if;
  end process;
  
				
  bot_pixel_in_pad <= '1' when (((h_cntr_reg >= bot_pad_x_reg) and (h_cntr_reg < (bot_pad_x_reg + PAD_WIDTH))) and
                            ((v_cntr_reg >= PAD_BOT_Y_MAX) and (v_cntr_reg < (PAD_BOT_Y_MAX + PAD_HEIGHT)))) else
                  '0';
				  
		-- TOP PLAYER ----
	process(pxl_clk)
	begin
    if (rising_edge(pxl_clk)) then
		top_push_button_sig <=  btn(2);
		top_push_button_sig1 <=  top_push_button_sig;
		top_push_button_sig2 <=  btn(3);
		top_push_button_sig3 <=  top_push_button_sig2;
		if  top_push_button_sig1 = '0' and top_push_button_sig= '1' then  --- Rise edge
			top_Move_Right <= '1';
	    elsif top_push_button_sig3 = '0' and top_push_button_sig2= '1' then  --- Rise edge
	        top_Move_Right <= '0';
		end if;
	end if;
	end process;
	
	process (pxl_clk)
	begin
    if (rising_edge(pxl_clk)) then
      if (update_pad = '1' and sw(1) = '1') then
        if ((top_Move_Right = '1') and (top_pad_x_reg < BOX_X_MAX - 150)) then
          top_pad_x_reg <= top_pad_x_reg + 1;
        elsif ((top_Move_Right = '0') and (top_pad_x_reg > BOX_X_MIN + 5)) then
          top_pad_x_reg <= top_pad_x_reg - 1;
        end if;
	  elsif (update_pad = '1' and sw(1) = '0') then
	    if ((top_push_button_sig = '1') and (top_pad_x_reg < BOX_X_MAX - 150)) then
          top_pad_x_reg <= top_pad_x_reg + 1;
        elsif ((top_push_button_sig2 = '1') and (top_pad_x_reg > BOX_X_MIN + 5)) then
          top_pad_x_reg <= top_pad_x_reg - 1;
        end if;
      end if;
    end if;
  end process;
  
 
  top_pixel_in_pad <= '1' when (((h_cntr_reg >= top_pad_x_reg) and (h_cntr_reg < (top_pad_x_reg + PAD_WIDTH))) and
                            ((v_cntr_reg >= PAD_TOP_Y_MIN) and (v_cntr_reg < (PAD_TOP_Y_MIN + PAD_HEIGHT)))) else
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
