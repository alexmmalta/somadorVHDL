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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE std.textio.ALL;

ENTITY somadorFloat_vhd_tst IS
END somadorFloat_vhd_tst;

ARCHITECTURE somadorFloat_arch OF somadorFloat_vhd_tst IS
    SIGNAL HEX0 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX1 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX2 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX3 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX4 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL HEX5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL KEY : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);

    -- permite testar o acumulador com qualquer quantidade de operandos
    TYPE operand_array IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(9 DOWNTO 0);

    COMPONENT somadorFloat
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

    FUNCTION bit_to_char(b : STD_LOGIC) RETURN CHARACTER IS
    BEGIN
        IF b = '1' THEN
            RETURN CHARACTER'('1');
        ELSE
            RETURN CHARACTER'('0');
        END IF;
    END FUNCTION;

    FUNCTION char_to_bit(c : CHARACTER) RETURN STD_LOGIC IS
    BEGIN
        IF c = '1' THEN
            RETURN '1';
        ELSE
            RETURN '0';
        END IF;
    END FUNCTION;

    FUNCTION raw_bits_string(bits : STD_LOGIC_VECTOR(9 DOWNTO 0)) RETURN STRING IS
        VARIABLE s : STRING(1 TO 12);
    BEGIN
        s(1) := bit_to_char(bits(9));
        s(2) := ' ';
        s(3) := bit_to_char(bits(8));
        s(4) := bit_to_char(bits(7));
        s(5) := bit_to_char(bits(6));
        s(6) := bit_to_char(bits(5));
        s(7) := ' ';
        s(8) := bit_to_char(bits(4));
        s(9) := bit_to_char(bits(3));
        s(10) := bit_to_char(bits(2));
        s(11) := bit_to_char(bits(1));
        s(12) := bit_to_char(bits(0));
        RETURN s;
    END FUNCTION;

    -- converte um inteiro nao negativo para binario, sem zeros a esquerda (minimo "0")
    FUNCTION int_to_bin_string(n : INTEGER) RETURN STRING IS
        VARIABLE buf : STRING(1 TO 16);
        VARIABLE value : INTEGER := n;
        VARIABLE idx : INTEGER := 17;
    BEGIN
        IF value = 0 THEN
            RETURN "0";
        END IF;
        WHILE value > 0 LOOP
            idx := idx - 1;
            buf(idx) := CHARACTER'VAL(CHARACTER'POS('0') + (value MOD 2));
            value := value / 2;
        END LOOP;
        RETURN buf(idx TO 16);
    END FUNCTION;

    -- converte um inteiro nao negativo para decimal, sem zeros a esquerda (minimo "0")
    FUNCTION int_to_dec_string(n : INTEGER) RETURN STRING IS
        VARIABLE buf : STRING(1 TO 10);
        VARIABLE value : INTEGER := n;
        VARIABLE idx : INTEGER := 11;
    BEGIN
        IF value = 0 THEN
            RETURN "0";
        END IF;
        WHILE value > 0 LOOP
            idx := idx - 1;
            buf(idx) := CHARACTER'VAL(CHARACTER'POS('0') + (value MOD 10));
            value := value / 10;
        END LOOP;
        RETURN buf(idx TO 10);
    END FUNCTION;

    -- formata um inteiro em decimal com "digits" caracteres, completando com zeros a esquerda
    FUNCTION zero_pad(n : INTEGER; digits : INTEGER) RETURN STRING IS
        VARIABLE result : STRING(1 TO digits);
        VARIABLE value : INTEGER := n;
    BEGIN
        FOR i IN digits DOWNTO 1 LOOP
            result(i) := CHARACTER'VAL(CHARACTER'POS('0') + (value MOD 10));
            value := value / 10;
        END LOOP;
        RETURN result;
    END FUNCTION;

    -- alinha "s" a direita dentro de um campo de "width" caracteres, completando com espacos
    FUNCTION pad_left(s : STRING; width : INTEGER) RETURN STRING IS
        VARIABLE result : STRING(1 TO width) := (OTHERS => ' ');
    BEGIN
        IF s'LENGTH >= width THEN
            RETURN s;
        END IF;
        result(width - s'LENGTH + 1 TO width) := s;
        RETURN result;
    END FUNCTION;

    FUNCTION hexchar_to_nibble(c : CHARACTER) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE c IS
            WHEN '0' => RETURN "0000";
            WHEN '1' => RETURN "0001";
            WHEN '2' => RETURN "0010";
            WHEN '3' => RETURN "0011";
            WHEN '4' => RETURN "0100";
            WHEN '5' => RETURN "0101";
            WHEN '6' => RETURN "0110";
            WHEN '7' => RETURN "0111";
            WHEN '8' => RETURN "1000";
            WHEN '9' => RETURN "1001";
            WHEN 'A' => RETURN "1010";
            WHEN 'b' => RETURN "1011";
            WHEN 'C' => RETURN "1100";
            WHEN 'd' => RETURN "1101";
            WHEN 'E' => RETURN "1110";
            WHEN 'F' => RETURN "1111";
            WHEN OTHERS => RETURN "0000";
        END CASE;
    END FUNCTION;

    FUNCTION hex7seg_to_char(code : STD_LOGIC_VECTOR(6 DOWNTO 0)) RETURN CHARACTER IS
    BEGIN
        CASE code IS
            WHEN "1000000" => RETURN CHARACTER'('0');
            WHEN "1111001" => RETURN CHARACTER'('1');
            WHEN "0100100" => RETURN '2';
            WHEN "0110000" => RETURN '3';
            WHEN "0011001" => RETURN '4';
            WHEN "0010010" => RETURN '5';
            WHEN "0000010" => RETURN '6';
            WHEN "1111000" => RETURN '7';
            WHEN "0000000" => RETURN '8';
            WHEN "0010000" => RETURN '9';
            WHEN "0001000" => RETURN 'A';
            WHEN "0000011" => RETURN 'b';
            WHEN "1000110" => RETURN 'C';
            WHEN "0100001" => RETURN 'd';
            WHEN "0000110" => RETURN 'E';
            WHEN "0001110" => RETURN 'F';
            WHEN "0111111" => RETURN CHARACTER'('-');
            WHEN "1111111" => RETURN ' ';
            WHEN OTHERS => RETURN '?';
        END CASE;
    END FUNCTION;

    FUNCTION display_string(h5, h4, h3, h2, h1, h0 : STD_LOGIC_VECTOR(6 DOWNTO 0)) RETURN STRING IS
        VARIABLE s : STRING(1 TO 6);
    BEGIN
        s(1) := hex7seg_to_char(h5);
        s(2) := hex7seg_to_char(h4);
        s(3) := hex7seg_to_char(h3);
        s(4) := hex7seg_to_char(h2);
        s(5) := hex7seg_to_char(h1);
        s(6) := hex7seg_to_char(h0);
        RETURN s;
    END FUNCTION;

    FUNCTION bits_to_real(bits : STD_LOGIC_VECTOR(9 DOWNTO 0)) RETURN REAL IS
        VARIABLE sign_val : INTEGER := 1;
        VARIABLE exponent : INTEGER := 0;
        VARIABLE frac8 : INTEGER := 0;
        VARIABLE value : REAL := 0.0;
    BEGIN
        IF bits(9) = '1' THEN
            sign_val := -1;
        END IF;
        exponent := TO_INTEGER(UNSIGNED(bits(8 DOWNTO 5)));
        -- a concatenacao inteira precisa ser qualificada: o elemento de operand_array
        -- e STD_LOGIC_VECTOR, entao "&" fica ambiguo entre os dois tipos (vcom-1583)
        frac8 := TO_INTEGER(UNSIGNED(STD_LOGIC_VECTOR'(bits(4 DOWNTO 0) & "000")));
        -- "**" com base 2.0 e expoente inteiro e exato; exp(n*log(2.0)) dava erro tipo 7.999... em vez de 8.0
        value := REAL(frac8) / 256.0 * (2.0 ** exponent) * REAL(sign_val);
        RETURN value;
    END FUNCTION;

    -- converte um inteiro nao negativo para binario com exatamente "digits" caracteres (zeros a esquerda)
    FUNCTION int_to_bin_padded(n : INTEGER; digits : INTEGER) RETURN STRING IS
        VARIABLE result : STRING(1 TO digits);
        VARIABLE value : INTEGER := n;
    BEGIN
        FOR i IN digits DOWNTO 1 LOOP
            result(i) := CHARACTER'VAL(CHARACTER'POS('0') + (value MOD 2));
            value := value / 2;
        END LOOP;
        RETURN result;
    END FUNCTION;

    -- valor absoluto de "bits" em binario exato: parte inteira alinhada em "width" colunas,
    -- fracao com o numero exato de bits necessario (zeros a direita alem do ultimo '1' sao removidos)
    FUNCTION bin_value_string(bits : STD_LOGIC_VECTOR(9 DOWNTO 0); width : INTEGER) RETURN STRING IS
        VARIABLE exponent : INTEGER;
        VARIABLE frac5 : INTEGER;
        VARIABLE shift : INTEGER;
        VARIABLE int_part : INTEGER;
        VARIABLE frac_bits : INTEGER;
        VARIABLE frac_len : INTEGER;
        VARIABLE frac_str : STRING(1 TO 5);
    BEGIN
        exponent := TO_INTEGER(UNSIGNED(bits(8 DOWNTO 5)));
        frac5 := TO_INTEGER(UNSIGNED(bits(4 DOWNTO 0)));
        shift := 5 - exponent;

        -- expoente >= 5: valor inteiro exato, sem bits de fracao
        IF shift <= 0 THEN
            int_part := frac5 * (2 ** (exponent - 5));
            RETURN pad_left(int_to_bin_string(int_part), width) & ",0";
        END IF;

        int_part := frac5 / (2 ** shift);
        frac_bits := frac5 MOD (2 ** shift);
        -- aqui os zeros a esquerda sao significativos: marcam a posicao de cada bit de fracao
        frac_str(1 TO shift) := int_to_bin_padded(frac_bits, shift);

        frac_len := shift;
        WHILE frac_len > 1 AND frac_str(frac_len) = '0' LOOP
            frac_len := frac_len - 1;
        END LOOP;

        RETURN pad_left(int_to_bin_string(int_part), width) & "," & frac_str(1 TO frac_len);
    END FUNCTION;

    -- reconstroi os bits (formato SW) da soma acumulada a partir dos displays de 7 segmentos;
    -- o bit menos significativo da fracao nao aparece no display e e assumido como '0'
    FUNCTION decode_sum_bits(h5, h4, h3, h2, h1, h0 : STD_LOGIC_VECTOR(6 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        VARIABLE bits : STD_LOGIC_VECTOR(9 DOWNTO 0);
    BEGIN
        IF hex7seg_to_char(h5) = '-' THEN
            bits(9) := '1';
        ELSE
            bits(9) := '0';
        END IF;
        bits(8 DOWNTO 5) := hexchar_to_nibble(hex7seg_to_char(h0));
        bits(4) := char_to_bit(hex7seg_to_char(h4));
        bits(3) := char_to_bit(hex7seg_to_char(h3));
        bits(2) := char_to_bit(hex7seg_to_char(h2));
        bits(1) := char_to_bit(hex7seg_to_char(h1));
        bits(0) := '0';
        RETURN bits;
    END FUNCTION;

    -- sinais so podem ser dirigidos por uma procedure se recebidos como parametro SIGNAL
    PROCEDURE press_key0(SIGNAL key_sig : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) IS
    BEGIN
        key_sig <= "10";
        WAIT FOR 20 ns;
        key_sig <= "11";
        WAIT FOR 20 ns;
    END PROCEDURE;

    PROCEDURE press_key1(SIGNAL key_sig : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)) IS
    BEGIN
        key_sig <= "01";
        WAIT FOR 20 ns;
        key_sig <= "11";
        WAIT FOR 20 ns;
    END PROCEDURE;

    PROCEDURE write_value_prefix(prefix : STRING; bits : STD_LOGIC_VECTOR(9 DOWNTO 0); ln : INOUT LINE) IS
        VARIABLE approx : REAL;
        VARIABLE sign_char : CHARACTER;
        VARIABLE magnitude : REAL;
        VARIABLE integer_part : INTEGER;
        VARIABLE frac_part : INTEGER;
    BEGIN
        approx := bits_to_real(bits);
        IF approx < 0.0 THEN
            sign_char := '-';
            magnitude := -approx;
        ELSE
            sign_char := '+';
            magnitude := approx;
        END IF;

        integer_part := INTEGER(FLOOR(magnitude));
        frac_part := INTEGER((magnitude - REAL(integer_part)) * 100.0);
        IF frac_part = 100 THEN
            integer_part := integer_part + 1;
            frac_part := 0;
        END IF;

        write(ln, prefix & raw_bits_string(bits) & string'(" | ") & bin_value_string(bits, 6) &
                  string'(" | ~ ") & sign_char & pad_left(int_to_dec_string(integer_part), 3) & string'(",") &
                  zero_pad(frac_part, 2));
    END PROCEDURE;

    -- imprime a linha "Display: SBBBBE" com o estado atual dos displays
    PROCEDURE log_display(ln : INOUT LINE) IS
    BEGIN
        write(ln, string'("Display: ") & display_string(HEX5, HEX4, HEX3, HEX2, HEX1, HEX0));
        writeline(output, ln);
    END PROCEDURE;

    -- aplica um operando nos switches, aciona <SOMAR> e registra Entrada/Soma/Display
    PROCEDURE log_entrada(bits : STD_LOGIC_VECTOR(9 DOWNTO 0); SIGNAL sw_sig : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
                          SIGNAL key_sig : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); ln : INOUT LINE) IS
        VARIABLE sum_bits : STD_LOGIC_VECTOR(9 DOWNTO 0);
    BEGIN
        sw_sig <= bits;
        WAIT FOR 20 ns;
        write_value_prefix(string'("Entrada: "), bits, ln);
        writeline(output, ln);

        write(ln, string'("<SOMAR>"));
        writeline(output, ln);
        press_key0(key_sig);

        sum_bits := decode_sum_bits(HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
        write_value_prefix(string'("Soma:    "), sum_bits, ln);
        writeline(output, ln);
        log_display(ln);

        write(ln, string'(""));
        writeline(output, ln);
    END PROCEDURE;

    -- aciona <RESET> e registra Soma/Display do acumulador zerado
    PROCEDURE log_reset(SIGNAL key_sig : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); ln : INOUT LINE) IS
        VARIABLE sum_bits : STD_LOGIC_VECTOR(9 DOWNTO 0);
    BEGIN
        write(ln, string'("<RESET>"));
        writeline(output, ln);
        press_key1(key_sig);

        sum_bits := decode_sum_bits(HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
        write_value_prefix(string'("Soma:    "), sum_bits, ln);
        writeline(output, ln);
        log_display(ln);

        write(ln, string'(""));
        writeline(output, ln);
    END PROCEDURE;

BEGIN
    i1 : somadorFloat
        PORT MAP (
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

    stimulus : PROCESS
        VARIABLE l : LINE;

        -- soma cada operando da lista (quantidade livre) e depois reseta o acumulador
        PROCEDURE run_test(titulo : STRING; operandos : operand_array) IS
        BEGIN
            write(l, string'("teste ") & titulo);
            writeline(output, l);
            write(l, string'(""));
            writeline(output, l);

            FOR i IN operandos'RANGE LOOP
                log_entrada(operandos(i), SW, KEY, l);
            END LOOP;
            log_reset(KEY, l);
        END PROCEDURE;
    BEGIN
        KEY <= "11";
        SW <= (OTHERS => '0');
        WAIT FOR 50 ns;

        write(l, string'("=== INICIO ==="));
        writeline(output, l);
        log_display(l);
        write(l, string'(""));
        writeline(output, l);

        run_test("1: 8 + 12", operand_array'(
            "0100000001",   -- 8  = 0 1000 00001
            "0011100011")); -- 12 = 0 0111 00011

        run_test("2: 0.5 + 4.0", operand_array'(
            "0000010000",   -- 0.5 = 0 0000 10000
            "0011000010")); -- 4.0 = 0 0110 00010

        run_test("3: -6 + 1.5", operand_array'(
            "1011000011",   -- -6  = 1 0110 00011
            "0010000011")); -- 1.5 = 0 0100 00011

        run_test("4: 20 + -3", operand_array'(
            "0011100101",   -- 20 = 0 0111 00101
            "1010100011")); -- -3 = 1 0101 00011

        run_test("5: 13 + 2.5 + -6 = 9.5", operand_array'(
            "0010101101",   -- 13   = 0 0101 01101
            "0001010100",   -- 2.5  = 0 0010 10100
            "1011000011")); -- -6   = 1 0110 00011

        run_test("6: 0.75 + -2 + 5 - 7 + 3.25 = 0", operand_array'(
            "0000011000",   -- 0.75 = 0 0000 11000
            "1010100010",   -- -2   = 1 0101 00010
            "0010100101",   -- 5    = 0 0101 00101
            "1001111100",   -- -7   = 1 0011 11100
            "0001011010")); -- 3.25 = 0 0010 11010

        run_test("7: 100 + 100 + 100 + 100 + 100 + 100 + 100 + 100 + 100 + 100 = 1000", operand_array'(
            "0011111001",   -- 100 = 0 0111 11001
            "0011111001",   -- x10
            "0011111001",
            "0011111001",
            "0011111001",
            "0011111001",
            "0011111001",
            "0011111001",
            "0011111001",
            "0011111001"));

        write(l, string'("=== FIM ==="));
        writeline(output, l);

        WAIT;
    END PROCESS;
END ARCHITECTURE somadorFloat_arch;
