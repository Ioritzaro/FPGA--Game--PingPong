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

entity vga_sync is
  Port (  pxl_clk           : in  STD_LOGIC;
              h_sync          : out STD_LOGIC;              
              v_sync          : out STD_LOGIC;
              h_counter     : out  STD_LOGIC_VECTOR (11 downto 0);
              v_counter     : out  STD_LOGIC_VECTOR (11 downto 0));
end vga_sync;

architecture Behavioral of vga_sync is	

-- VGA Sync signals
signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
signal h_sync_reg : std_logic := not(H_POL);
signal v_sync_reg : std_logic := not(V_POL);

begin
  
  -- Calculate horizontal counter
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
  
  -- Calculate vertical counter
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
  
  -- Horizontal sync logic
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
  
  -- Vertical sync logic
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
  
  h_counter <= h_cntr_reg;
  v_counter <= v_cntr_reg;  
  h_sync      <= h_sync_reg;
  v_sync      <= v_sync_reg;  
  
  end Behavioral;