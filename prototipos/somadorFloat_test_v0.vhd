LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY somadorFloat_vhd_tst IS
END somadorFloat_vhd_tst;

ARCHITECTURE somadorFloat_arch OF somadorFloat_vhd_tst IS
    SIGNAL KEY : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);

    COMPONENT somadorFloat
        PORT (
            KEY : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0)
        );
    END COMPONENT;

    FUNCTION bits_to_real(bits_in : STD_LOGIC_VECTOR(9 DOWNTO 0)) RETURN REAL IS
        VARIABLE sign_val : STD_LOGIC;
        VARIABLE exp_val : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE frac_val : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE valor : REAL;
    BEGIN
        sign_val := bits_in(9);
        exp_val := bits_in(8 DOWNTO 5);
        frac_val := bits_in(4 DOWNTO 0) & "000";

        IF sign_val = '1' THEN
            valor := -1.0;
        ELSE
            valor := 1.0;
        END IF;

        RETURN valor * (REAL(TO_INTEGER(UNSIGNED(frac_val))) / 256.0) *
               (2.0 ** REAL(TO_INTEGER(UNSIGNED(exp_val))));
    END FUNCTION;

    FUNCTION encode_real(value : REAL) RETURN STD_LOGIC_VECTOR IS
        VARIABLE sign_val : STD_LOGIC;
        VARIABLE exp_val : STD_LOGIC_VECTOR(3 DOWNTO 0);
        VARIABLE frac_val : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE best_exp : INTEGER := 0;
        VARIABLE best_frac : INTEGER := 0;
        VARIABLE best_error : REAL := 1.0E30;
        VARIABLE abs_val : REAL;
        VARIABLE candidate : REAL;
        VARIABLE candidate_error : REAL;
        VARIABLE e : INTEGER;
        VARIABLE f : INTEGER;
    BEGIN
        sign_val := '0';
        abs_val := ABS(value);

        IF value < 0.0 THEN
            sign_val := '1';
        END IF;

        FOR e IN 0 TO 15 LOOP
            FOR f IN 0 TO 31 LOOP
                candidate := (REAL(f * 8) / 256.0) * (2.0 ** REAL(e));
                candidate_error := ABS(abs_val - candidate);

                IF candidate_error < best_error THEN
                    best_error := candidate_error;
                    best_exp := e;
                    best_frac := f * 8;
                END IF;
            END LOOP;
        END LOOP;

        exp_val := STD_LOGIC_VECTOR(TO_UNSIGNED(best_exp, 4));
        frac_val := STD_LOGIC_VECTOR(TO_UNSIGNED(best_frac, 8));
        RETURN sign_val & exp_val & frac_val(7 DOWNTO 3);
    END FUNCTION;

BEGIN
    i1 : somadorFloat
    PORT MAP (
        KEY => KEY,
        LEDR => LEDR,
        SW => SW
    );

    stimulus : PROCESS
        VARIABLE l : line;

        PROCEDURE press_key0 IS
        BEGIN
            KEY(0) <= '0';
            WAIT FOR 50 ns;
            KEY(0) <= '1';
            WAIT FOR 50 ns;
        END PROCEDURE;

        PROCEDURE reset_fsm IS
        BEGIN
            write(l, string'("> RESET <"));
            writeline(output, l);
            write(l, string'(""));
            writeline(output, l);
            KEY(1) <= '0';
            WAIT FOR 50 ns;
            KEY(1) <= '1';
            WAIT FOR 50 ns;
        END PROCEDURE;

        PROCEDURE log_value(name_txt : STRING; bits_in : STD_LOGIC_VECTOR(9 DOWNTO 0); value_real : REAL) IS
            VARIABLE mantissa : REAL;
            VARIABLE expoente : INTEGER;
            VARIABLE valor_abs : REAL;
        BEGIN
            valor_abs := ABS(value_real);
            expoente := 0;

            IF valor_abs > 0.0 THEN
                WHILE valor_abs >= 10.0 LOOP
                    valor_abs := valor_abs / 10.0;
                    expoente := expoente + 1;
                END LOOP;

                WHILE valor_abs < 1.0 LOOP
                    valor_abs := valor_abs * 10.0;
                    expoente := expoente - 1;
                END LOOP;
            END IF;

            mantissa := valor_abs;

            write(l, name_txt);
            write(l, string'(" | "));
            write(l, bits_in);
            write(l, string'(" | ~"));
            IF value_real < 0.0 THEN
                write(l, string'(" - "));
            ELSE
                write(l, string'("   "));
            END IF;
            write(l, mantissa, right, 0, 2);
            write(l, string'(" e"));
            IF expoente >= 0 THEN
                write(l, string'("+"));
            ELSE
                write(l, string'("-"));
            END IF;
            write(l, ABS(expoente));
            writeline(output, l);
        END PROCEDURE;

        PROCEDURE drive_value(value : REAL) IS
        BEGIN
            SW <= encode_real(value);
            WAIT FOR 20 ns;
        END PROCEDURE;

    BEGIN
        KEY <= "11";
        SW <= (OTHERS => '0');
        WAIT FOR 100 ns;

        write(l, string'("=================================================")); writeline(output, l);
        write(l, string'(" SIMULACAO SOMADOR DE PONTO FLUTUANTE ")); writeline(output, l);
        write(l, string'("=================================================")); writeline(output, l);

        -- Teste 1: sinais iguais e expoentes proximos
        write(l, string'("TESTE 1: sinais iguais e expoentes proximos")); writeline(output, l);
        drive_value(3.14);
        log_value("NUM1", SW, 3.14);
        press_key0;

        drive_value(1.73);
        log_value("NUM2", SW, 1.73);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 2: sinais opostos
        write(l, string'("TESTE 2: sinais opostos")); writeline(output, l);
        drive_value(5.0);
        log_value("NUM1", SW, 5.0);
        press_key0;

        drive_value(-2.5);
        log_value("NUM2", SW, -2.5);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 3: expoentes muito diferentes
        write(l, string'("TESTE 3: expoentes muito diferentes")); writeline(output, l);
        drive_value(0.25);
        log_value("NUM1", SW, 0.25);
        press_key0;

        drive_value(8.0);
        log_value("NUM2", SW, 8.0);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 4: sinais opostos com magnitudes proximas
        write(l, string'("TESTE 4: sinais opostos com magnitudes proximas")); writeline(output, l);
        drive_value(7.5);
        log_value("NUM1", SW, 7.5);
        press_key0;

        drive_value(-7.5);
        log_value("NUM2", SW, -7.5);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 5: ordem de grandeza distinta (pequeno + grande)
        write(l, string'("TESTE 5: ordem de grandeza distinta (pequeno + grande)")); writeline(output, l);
        drive_value(0.125);
        log_value("NUM1", SW, 0.125);
        press_key0;

        drive_value(64.0);
        log_value("NUM2", SW, 64.0);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 6: valores negativos e grandes
        write(l, string'("TESTE 6: valores negativos e grandes")); writeline(output, l);
        drive_value(-12.0);
        log_value("NUM1", SW, -12.0);
        press_key0;

        drive_value(-48.0);
        log_value("NUM2", SW, -48.0);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 7: sinais diferentes com grandeza proxima
        write(l, string'("TESTE 7: sinais diferentes com grandeza proxima")); writeline(output, l);
        drive_value(15.0);
        log_value("NUM1", SW, 15.0);
        press_key0;

        drive_value(-14.75);
        log_value("NUM2", SW, -14.75);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        -- Teste 8: valores mais aleatorios e diferentes ordens de grandeza
        write(l, string'("TESTE 8: valores mais aleatorios e diferentes ordens de grandeza")); writeline(output, l);
        drive_value(2.75);
        log_value("NUM1", SW, 2.75);
        press_key0;

        drive_value(-0.03125);
        log_value("NUM2", SW, -0.03125);
        press_key0;

        WAIT FOR 100 ns;
        log_value("SOMA", LEDR, bits_to_real(LEDR));
        writeline(output, l);
        reset_fsm;

        write(l, string'("=================================================")); writeline(output, l);
        write(l, string'(" FIM DA SIMULACAO ")); writeline(output, l);
        write(l, string'("=================================================")); writeline(output, l);

        WAIT;
    END PROCESS stimulus;

END somadorFloat_arch;