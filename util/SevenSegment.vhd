-- Baseado no código de FPGA Prototyping by VHDL Examples - Pong P. Chu
-- Adaptacao para a placa DE1 da Altera
library ieee;
use ieee.std_logic_1164.all;

entity SevenSegment is
   port(
      SW: in std_logic_vector(3 downto 0);
      --dp: in std_logic;
      HEX0: out std_logic_vector(6 downto 0)
   );
end SevenSegment;

architecture arch of SevenSegment is
begin
   with SW select
      HEX0(6 downto 0) <=
         "1000000" when "0000",
         "1111001" when "0001",
         "0100100" when "0010",
         "0110000" when "0011",
         "0011001" when "0100",
         "0010010" when "0101",
         "0100000" when "0110",       -- ERRADO !!!CORRIGIR!
         "0001111" when "0111",       -- ERRADO !!! CORRIGIR!
         "0000000" when "1000",       	-- ERRADO !!! CORRIGIR!
         "0000100" when "1001",       	-- ERRADO !!! CORRIGIR!
         "0001000" when "1010", --A   -- ERRADO !!! CORRIGIR!
         "1100000" when "1011", --b   -- ERRADO !!! CORRIGIR!
         "0110001" when "1100", --C   -- ERRADO !!! CORRIGIR!
         "1000010" when "1101", --d   -- ERRADO !!! CORRIGIR!
         "0110000" when "1110", --E   -- ERRADO !!! CORRIGIR!
         "0111000" when others; --F   -- ERRADO !!! CORRIGIR!
   --sseg(7) <= dp;
end arch;