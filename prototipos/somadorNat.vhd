LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY somadorNat IS
    PORT (
        -- 10 interruptores usados para entrar com os números binários.
        -- SW(0) é o bit menos significativo e SW(9) o mais significativo.
        SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);

        -- Botão A: confirma o número atual e avança o estado.
        -- Botão B: zera a soma e retorna ao primeiro estado.
        KEY : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- LEDs usados para indicar em qual etapa da operação o sistema está.
        -- LEDR(0) indica o primeiro estado, LEDR(1) indica o segundo e LEDR(3 downto 0)
        -- acendem todos no estado de resultado.
        LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);

        -- Displays de 7 segmentos para mostrar o valor decimal da soma.
        -- HEX0 representa a unidade, HEX1 a dezena e assim por diante.
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END somadorNat;

ARCHITECTURE comportamento OF somadorNat IS
    TYPE estado_t IS (ESPERA_PRIMEIRO, ESPERA_SEGUNDO, MOSTRA_RESULTADO);

    -- Estados da máquina de estados.
    SIGNAL estado : estado_t := ESPERA_PRIMEIRO;

    -- Registradores para guardar os dois números digitados e a soma.
    SIGNAL num1_reg : unsigned(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL num2_reg : unsigned(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL soma_reg : unsigned(11 DOWNTO 0) := (OTHERS => '0');

    -- Valor que será exibido na saída dos displays.
    SIGNAL valor_exibido : unsigned(11 DOWNTO 0) := (OTHERS => '0');

    SIGNAL valor_display : unsigned(11 DOWNTO 0);

    -- Função que converte um dígito decimal (0 a 9) para o padrão de 7 segmentos.
    -- Na placa DE10-Lite, os displays são de anodo comum, então o valor '0' acende o segmento.
    FUNCTION dec_to_7seg(digito : NATURAL) RETURN STD_LOGIC_VECTOR IS
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

    -- Processo responsável por controlar os estados e guardar os números.
    PROCESS(KEY)
    BEGIN
        IF (KEY(1) = '0') THEN
            -- Reset da soma e retorno ao primeiro estado.
            estado <= ESPERA_PRIMEIRO;
            num1_reg <= (OTHERS => '0');
            num2_reg <= (OTHERS => '0');
            soma_reg <= (OTHERS => '0');
            valor_exibido <= (OTHERS => '0');

        ELSIF falling_edge(KEY(0)) THEN
            CASE estado IS
                WHEN ESPERA_PRIMEIRO =>
                    -- Armazena o primeiro número vindo dos switches.
                    num1_reg <= unsigned(SW);
                    estado <= ESPERA_SEGUNDO;

                WHEN ESPERA_SEGUNDO =>
                    -- Armazena o segundo número e calcula a soma.
                    num2_reg <= unsigned(SW);

                    soma_reg <= resize(num1_reg, 12) + resize(unsigned(SW), 12);
                    valor_exibido <= resize(num1_reg, 12) + resize(unsigned(SW), 12);
                    estado <= MOSTRA_RESULTADO;

                WHEN MOSTRA_RESULTADO =>
                    -- Mantém o resultado exibido até um novo reset.
                    estado <= MOSTRA_RESULTADO;
            END CASE;
        END IF;
    END PROCESS;

    LEDR <= SW;

WITH estado SELECT
    valor_display <=
        resize(unsigned(SW), 12) WHEN ESPERA_PRIMEIRO,
        resize(unsigned(SW), 12) WHEN ESPERA_SEGUNDO,
        valor_exibido            WHEN MOSTRA_RESULTADO,
        (OTHERS => '0')          WHEN OTHERS;

    -- Processo responsável por converter o valor decimal da soma em
    -- sinais para os displays de 7 segmentos.
    PROCESS(valor_display)
        VARIABLE valor : INTEGER;
        VARIABLE digito : INTEGER;
        VARIABLE resto : INTEGER;
    BEGIN
        valor := to_integer(valor_display);
        resto := valor;

        digito := resto / 100000;
        HEX5 <= dec_to_7seg(digito);
        resto := resto MOD 100000;

        digito := resto / 10000;
        HEX4 <= dec_to_7seg(digito);
        resto := resto MOD 10000;

        digito := resto / 1000;
        HEX3 <= dec_to_7seg(digito);
        resto := resto MOD 1000;

        digito := resto / 100;
        HEX2 <= dec_to_7seg(digito);
        resto := resto MOD 100;

        digito := resto / 10;
        HEX1 <= dec_to_7seg(digito);
        resto := resto MOD 10;

        digito := resto;
        HEX0 <= dec_to_7seg(digito);
    END PROCESS;

END comportamento;