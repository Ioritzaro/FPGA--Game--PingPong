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
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants_package.all;

entity Pixel_On_Text is
	generic(
		displayText: string  := (others => NUL);
		resize: integer );
	port (
		clk: in std_logic;
		-- top left corner of the text
		positionX: in integer;
		positionY: in integer;
		-- current pixel postion
		horzCoord: in integer;
		vertCoord: in integer;
		
		pixel: out std_logic := '0');
end Pixel_On_Text;

architecture Behavioral of Pixel_On_Text is
  
  constant Text_Width : integer := resize*FONT_WIDTH;
  constant Text_Height : integer := resize*FONT_HEIGHT;

	signal fontAddress: integer;
	-- A row of bit in a charactor, we check if our current (x,y) is 1 in char row
	signal charBitInRow: std_logic_vector(FONT_WIDTH-1 downto 0) := (others => '0');
	-- char in ASCII code
	signal charCode:integer := 0;
	-- the position(column) of a charactor in the given text
	signal charPosition:integer := 0;
	-- the bit position(column) in a charactor
	signal bitPosition:integer := 0;
  signal resizeBitRow : std_logic_vector(((resize*FONT_WIDTH) -1) downto 0) := (others => '0');    
  signal vertCoord_z:integer := 0;
  signal vertCoordResize:integer := 0;
  signal vertCoordCntr:integer := 0;
  
  
begin
    
   -- Text x axis bits
  textPosX: process(clk)
	begin
        if rising_edge(clk) then
            if(horzCoord = positionX) then
              bitPosition <= Text_Width - 1;
              charPosition <= 1;
            elsif((horzCoord > positionX) and (horzCoord < positionX + (Text_Width * displayText'length)))then
              if(bitPosition = 0) then
                bitPosition <= Text_Width - 1;
              elsif(bitPosition = 1) then              
                charPosition <= charPosition +1;
                bitPosition <= bitPosition - 1;
              else
                bitPosition <= bitPosition - 1;
              end if;
            else              
              bitPosition <= Text_Width - 1;
              charPosition <= 1;
            end if;
        end if;
	end process;
  
  charCode <= character'pos(displayText(charPosition));
  
  -- Text y axis bits
  vertCoordReg: process(clk)
	begin
        if rising_edge(clk) then
              vertCoord_z <= vertCoord;
        end if;
	end process;
  
  textPosY: process(clk)
	begin
        if rising_edge(clk) then
            if(vertCoord = positionY) then
              vertCoordResize <= vertCoord;
              vertCoordCntr   <= 0;
            elsif(vertCoord > positionY) then
              if(vertCoord > vertCoord_z) then
                if(vertCoordCntr = (resize-1)) then
                  vertCoordResize <= vertCoordResize +1;
                  vertCoordCntr <= 0;
                 else
                  vertCoordCntr <= vertCoordCntr +1;
                end if;
              end if;
            end if;
        end if;
	end process;  
  
   fontAddress <= charCode*FONT_HEIGHT + (vertCoordResize - positionY);
  
	FontRom: entity work.Font_Rom
	port map(
		clk => clk,
		addr => fontAddress,
		fontRow => charBitInRow
	);
	
  
  g_resize: for i in 0 to (FONT_WIDTH-1) generate
      g_X: for j in 0 to (resize-1) generate
        resizeBitRow((resize*i)+j) <= charBitInRow(i);
      end generate g_X;
  end generate g_resize;
  
  
	pixelOn: process(clk)
		variable inXRange: std_logic := '0';
		variable inYRange: std_logic := '0';
	begin
        if rising_edge(clk) then
            -- If current pixel is in the horizontal range of text
            if((horzCoord >= positionX) and (horzCoord < positionX + (Text_Width * displayText'length))) then
                inXRange := '1';
            else
              inXRange := '0';              
            end if;            
            -- If current pixel is in the vertical range of text
            if((vertCoord >= positionY) and (vertCoord < positionY + Text_Height)) then
                inYRange := '1';
            else
              inYRange := '0';
            end if;            
            -- need to check if the pixel is on for text
            if(inXRange= '1' and inYRange = '1') then
                -- FONT_WIDTH-bitPosition: we are reverting the charactor
                if(resizeBitRow(bitPosition) = '1') then
                    pixel <= '1';
                else
                  pixel <= '0';
                end if;
            else
              pixel <= '0';
            end if;
        
        end if;
	end process;

end Behavioral;