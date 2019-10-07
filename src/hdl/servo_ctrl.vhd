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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity servo_ctrl is
    Port ( 
      Clk         : in  std_logic;       -- 100kHz clock source is required!!!
      box_pos  : in  std_logic_vector(11 downto 0);
      servo      : out std_logic
      );
end servo_ctrl;

architecture Behavioral of servo_ctrl is

-- 50Hz servo refresh 2000 of 10us clock periods
constant PWM_REFRESH : std_logic_vector(10 downto 0) := conv_std_logic_vector(1999, 11);

-- pulse length
signal data : std_logic_vector(7 downto 0) := conv_std_logic_vector(180, 8);

-- Pulse counter
signal cnt  : std_logic_vector(10 downto 0) := "00000000000";

signal servon, ps, pe : std_logic;
signal pos_refactor   : integer;
signal pos_orig         : integer;

begin
   
   servo <= servon;      -- map servo pulse signal to all the four servo pins
                  
   process(Clk)
   begin
      if rising_edge(Clk) then         
         if ps = '1' then
            cnt <= (others => '0');
         else
            cnt <= cnt + '1';
         end if;
      end if;
   end process;

  -- 50Hz impulses which trigger the PWM high	
  -- determines the frequency of the PWM's 
  ps <= '1' when cnt = PWM_REFRESH else '0';

  -- impulses which trigger the PWM low 
  pe <= '1' when cnt = "000"&data else '0';

  -- output decode 
  process (Clk)
    begin
	 	if rising_edge(Clk) then
         if ps = '1' then 
            servon <= '1';
            pos_orig <= CONV_INTEGER(unsigned(box_pos(11 downto 0)));
            pos_refactor <= (pos_orig/10) +100;
            data <= conv_std_logic_vector(pos_refactor,8);
         elsif pe = '1' then
            servon <= '0';
         end if;
      end if;
  end process;

end Behavioral;