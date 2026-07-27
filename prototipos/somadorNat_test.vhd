-- Copyright (C) 2025  Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, the Altera Quartus Prime License Agreement,
-- the Altera IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Altera and sold by Altera or its authorized distributors.  Please
-- refer to the Altera Software License Subscription Agreements 
-- on the Quartus Prime software download page.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "07/25/2026 17:52:58"
                                                            
-- Vhdl Test Bench template for design  :  somadorNat
-- 
-- Simulation tool : Questa Altera FPGA (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY somadorNat_vhd_tst IS
END somadorNat_vhd_tst;
ARCHITECTURE somadorNat_arch OF somadorNat_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL HEX0 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX1 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX2 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX3 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX4 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL HEX5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL KEY : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);
COMPONENT somadorNat
	PORT (
	HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	KEY : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
	LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
	SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0)
	);
END COMPONENT;

-- Função auxiliar para gerar o padrão de 7 segmentos (mesma tabela do DUT)
FUNCTION dec_to_7seg_tb(digito : NATURAL) RETURN STD_LOGIC_VECTOR IS
BEGIN
	CASE digito IS
		WHEN 0 => RETURN "1000000";
		WHEN 1 => RETURN "1111001";
		WHEN 2 => RETURN "0100100";
		WHEN 3 => RETURN "0110000";
		WHEN 4 => RETURN "0011001";
		WHEN 5 => RETURN "0010010";
		WHEN 6 => RETURN "0000010";
		WHEN 7 => RETURN "1111000";
		WHEN 8 => RETURN "0000000";
		WHEN 9 => RETURN "0010000";
		WHEN OTHERS => RETURN "1111111";
	END CASE;
END FUNCTION;

BEGIN
	i1 : somadorNat
	PORT MAP (
	-- list connections between master ports and signals
	HEX0 => HEX0,
	HEX1 => HEX1,
	HEX2 => HEX2,
	HEX3 => HEX3,
	HEX4 => HEX4,
	HEX5 => HEX5,
	KEY => KEY,
	LEDR => LEDR,
	SW => SW
	);

	init : PROCESS
	BEGIN
		-- Inicialização
		KEY <= "11";
		SW  <= (OTHERS => '0');
		wait for 200 ns;

		-- Test 1: 5 + 3 = 8
		SW <= "0000000101"; -- 5
		wait for 100 ns;
		KEY <= "10"; -- press KEY(0) (falling edge)
		wait for 100 ns;
		KEY <= "11"; -- release
		wait for 200 ns;

		SW <= "0000000011"; -- 3
		wait for 100 ns;
		KEY <= "10"; -- press confirm
		wait for 100 ns;
		KEY <= "11"; -- release
		wait for 300 ns; -- aguarda DUT calcular e atualizar displays

		if HEX0 = dec_to_7seg_tb(8) then
			report "Test 1 PASSED: 5 + 3 = 8" severity note;
		else
			report "Test 1 FAILED: expected 8 on HEX0" severity error;
		end if;

		-- Test 2: reset e 10 + 15 = 25
		KEY <= "01"; -- KEY(1) = '0' faz reset
		wait for 100 ns;
		KEY <= "11";
		wait for 200 ns;

		SW <= "0000001010"; -- 10
		wait for 100 ns;
		KEY <= "10"; -- press
		wait for 100 ns;
		KEY <= "11";
		wait for 200 ns;

		SW <= "0000001111"; -- 15
		wait for 100 ns;
		KEY <= "10"; -- press
		wait for 100 ns;
		KEY <= "11";
		wait for 400 ns;

		if (HEX1 = dec_to_7seg_tb(2)) and (HEX0 = dec_to_7seg_tb(5)) then
			report "Test 2 PASSED: 10 + 15 = 25" severity note;
		else
			report "Test 2 FAILED: expected 25 on HEX1/HEX0" severity error;
		end if;

		report "End of testbench" severity note;
		wait;
	END PROCESS init;
END somadorNat_arch;
