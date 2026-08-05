LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY somadorFloat IS
    PORT (

        KEY : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 2 botões da placa (KEY0 e KEY1)
        SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 switches da placa (SW0 a SW9)
        LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 LEDs da placa (LEDR0 a LEDR9)
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END somadorFloat;

ARCHITECTURE arch OF somadorFloat IS

    -- VARIAVEIS DO SOMADOR ORIGINAL
        -- sufixos:
        -- [b]ig (maior número),
        -- [s]mall (menor número),
        -- [a]ligned (alinhado),
        -- [n]ormalized (normalizado)
    SIGNAL signb, signs : STD_LOGIC;
    SIGNAL expb, exps, expn : unsigned(3 DOWNTO 0);
    SIGNAL fracb, fracs, fraca, fracn : unsigned(7 DOWNTO 0);
    SIGNAL sum_norm : unsigned(7 DOWNTO 0);
    SIGNAL exp_diff : unsigned(3 DOWNTO 0);
    SIGNAL sum : unsigned(8 DOWNTO 0); -- 1 bit extra para o carry (vai-um)
    SIGNAL lead0 : unsigned(2 DOWNTO 0);

    -- Registradores de memória e acumulador
    SIGNAL sign_in, sign_acc : STD_LOGIC := '0';
    SIGNAL exp_in, exp_acc : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL frac_in, frac_acc : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- Normalizacao do operando recem-lido nos switches (frac_in pode nao vir normalizado)
    SIGNAL frac_in_raw : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL frac_in_shifted : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL lead0_in : unsigned(3 DOWNTO 0);

    -- Registradores de Memória: Vão guardar os valores do acumulador e do operando atual
    SIGNAL sign1, sign2 : STD_LOGIC := '0';
    SIGNAL exp1, exp2 : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL frac1, frac2 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- Sinais que guardam o resultado da conta antes de enviar para os Displays
    SIGNAL sign_out : STD_LOGIC;
    SIGNAL exp_out : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL frac_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Sinais para os displays de 7 segmentos
    SIGNAL hex_sign : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit7 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit6 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit4 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_exp : STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Conversões para o display de 7 segmentos
    FUNCTION nibble_to_7seg(d : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE d IS
            WHEN "0000" => RETURN "1000000"; -- 0
            WHEN "0001" => RETURN "1111001"; -- 1
            WHEN "0010" => RETURN "0100100"; -- 2
            WHEN "0011" => RETURN "0110000"; -- 3
            WHEN "0100" => RETURN "0011001"; -- 4
            WHEN "0101" => RETURN "0010010"; -- 5
            WHEN "0110" => RETURN "0000010"; -- 6
            WHEN "0111" => RETURN "1111000"; -- 7
            WHEN "1000" => RETURN "0000000"; -- 8
            WHEN "1001" => RETURN "0010000"; -- 9
            WHEN "1010" => RETURN "0001000"; -- A
            WHEN "1011" => RETURN "0000011"; -- b
            WHEN "1100" => RETURN "1000110"; -- C
            WHEN "1101" => RETURN "0100001"; -- d
            WHEN "1110" => RETURN "0000110"; -- E
            WHEN "1111" => RETURN "0001110"; -- F
            WHEN OTHERS => RETURN "1111111";
        END CASE;
    END FUNCTION nibble_to_7seg;

    FUNCTION bit_to_7seg(b : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        IF b = '1' THEN
            RETURN "1111001"; -- 1
        ELSE
            RETURN "1000000"; -- 0
        END IF;
    END FUNCTION bit_to_7seg;

    FUNCTION sign_to_7seg(s : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        IF s = '1' THEN
            RETURN "0111111"; -- -
        ELSE
            RETURN "1111111"; -- blank
        END IF;
    END FUNCTION sign_to_7seg;

BEGIN

    -- =========================================================
    -- CONTROLE DO ACUMULADOR
    -- =========================================================

    -- KEY(0) adiciona o valor atual (entrada nos switches) à soma acumulada
    -- KEY(1) zera a soma acumulada

    PROCESS (KEY)
    BEGIN
        IF (KEY(1) = '0') THEN
            sign_acc <= '0';
            exp_acc <= (OTHERS => '0');
            frac_acc <= (OTHERS => '0');
        ELSIF falling_edge(KEY(0)) THEN
            sign_acc <= sign_out;
            exp_acc <= exp_out;
            frac_acc <= frac_out;
        END IF;
    END PROCESS;

    -- Valor atual de entrada e saída para LEDs
    sign_in <= SW(9);
    frac_in_raw <= SW(4 DOWNTO 0) & "000";
    LEDR <= SW;

    -- Conta os zeros a esquerda de frac_in_raw (0 a 8)
    lead0_in <=
        "0000" WHEN frac_in_raw(7) = '1' ELSE
        "0001" WHEN frac_in_raw(6) = '1' ELSE
        "0010" WHEN frac_in_raw(5) = '1' ELSE
        "0011" WHEN frac_in_raw(4) = '1' ELSE
        "0100" WHEN frac_in_raw(3) = '1' ELSE
        "0101" WHEN frac_in_raw(2) = '1' ELSE
        "0110" WHEN frac_in_raw(1) = '1' ELSE
        "0111" WHEN frac_in_raw(0) = '1' ELSE
        "1000"; -- fracao toda zero

    WITH lead0_in SELECT
        frac_in_shifted <=
        frac_in_raw WHEN "0000",
        frac_in_raw(6 DOWNTO 0) & '0' WHEN "0001",
        frac_in_raw(5 DOWNTO 0) & "00" WHEN "0010",
        frac_in_raw(4 DOWNTO 0) & "000" WHEN "0011",
        frac_in_raw(3 DOWNTO 0) & "0000" WHEN "0100",
        frac_in_raw(2 DOWNTO 0) & "00000" WHEN "0101",
        frac_in_raw(1 DOWNTO 0) & "000000" WHEN "0110",
        frac_in_raw(0) & "0000000" WHEN "0111",
        "00000000" WHEN OTHERS;

    -- Normaliza o operando de entrada (bit mais significativo da fracao = '1'). Sem isso, a
    -- comparacao/subtracao abaixo pode escolher o operando errado como "maior" e estourar
    -- por baixo numa subtracao unsigned quando SW traz uma fracao nao normalizada.
    PROCESS (frac_in_raw, frac_in_shifted, lead0_in, SW)
        VARIABLE exp_raw : unsigned(3 DOWNTO 0);
    BEGIN
        exp_raw := unsigned(SW(8 DOWNTO 5));
        IF (frac_in_raw = "00000000") OR (lead0_in > exp_raw) THEN
            exp_in <= (OTHERS => '0');
            frac_in <= (OTHERS => '0');
        ELSE
            exp_in <= STD_LOGIC_VECTOR(exp_raw - lead0_in);
            frac_in <= frac_in_shifted;
        END IF;
    END PROCESS;

    -- Operando maior e menor usados pelo somador
    sign1 <= sign_acc;
    exp1 <= exp_acc;
    frac1 <= frac_acc;
    sign2 <= sign_in;
    exp2 <= exp_in;
    frac2 <= frac_in;

    -- =========================================================
    -- O SOMADOR DE PONTO FLUTUANTE
    -- =========================================================

    -- 1º Estágio: ordenar para identificar o maior número
    PROCESS (sign1, sign2, exp1, exp2, frac1, frac2)
    BEGIN
        IF (exp1 & frac1) > (exp2 & frac2) THEN -- Se o num1 for maior
            signb <= sign1;
            signs <= sign2;
            expb <= unsigned(exp1);
            exps <= unsigned(exp2);
            fracb <= unsigned(frac1);
            fracs <= unsigned(frac2);
        ELSE -- Se o num2 for maior
            signb <= sign2;
            signs <= sign1;
            expb <= unsigned(exp2);
            exps <= unsigned(exp1);
            fracb <= unsigned(frac2);
            fracs <= unsigned(frac1);
        END IF;
    END PROCESS;

    -- 2º Estágio: alinhar o menor número
    exp_diff <= expb - exps; -- Calcula a diferença dos expoentes    
    WITH exp_diff SELECT
        fraca <=
        fracs WHEN "0000",
        "0" & fracs(7 DOWNTO 1) WHEN "0001",
        "00" & fracs(7 DOWNTO 2) WHEN "0010",
        "000" & fracs(7 DOWNTO 3) WHEN "0011",
        "0000" & fracs(7 DOWNTO 4) WHEN "0100",
        "00000" & fracs(7 DOWNTO 5) WHEN "0101",
        "000000" & fracs(7 DOWNTO 6) WHEN "0110",
        "0000000" & fracs(7) WHEN "0111",
        "00000000" WHEN OTHERS;

    -- 3º Estágio: Adição ou Subtração
    -- Se os sinais forem iguais, soma. Se forem diferentes, subtrai.
    -- O '0' adicionado na frente é para dar espaço para um eventual "vai um" (carry)
    sum <= ('0' & fracb) + ('0' & fraca) WHEN signb = signs ELSE
           ('0' & fracb) - ('0' & fraca);

    -- 4º Estágio: normalizar
    -- O número precisa ficar no padrão onde o bit mais a esquerda seja '1'.

    -- 4.1: Conta quantos zeros tem à esquerda do resultado
    lead0 <=
        "000" WHEN sum(7) = '1' ELSE
        "001" WHEN sum(6) = '1' ELSE
        "010" WHEN sum(5) = '1' ELSE
        "011" WHEN sum(4) = '1' ELSE
        "100" WHEN sum(3) = '1' ELSE
        "101" WHEN sum(2) = '1' ELSE
        "110" WHEN sum(1) = '1' ELSE
        "111";

    -- 4.2: Empurra os bits para a esquerda para
    WITH lead0 SELECT
        sum_norm <=
        sum(7 DOWNTO 0) WHEN "000",
        sum(6 DOWNTO 0) & '0' WHEN "001",
        sum(5 DOWNTO 0) & "00" WHEN "010",
        sum(4 DOWNTO 0) & "000" WHEN "011",
        sum(3 DOWNTO 0) & "0000" WHEN "100",
        sum(2 DOWNTO 0) & "00000" WHEN "101",
        sum(1 DOWNTO 0) & "000000" WHEN "110",
        sum(0) & "0000000" WHEN OTHERS;

    -- 4.3: Ajusta o expoente final dependendo se houve "vai-um" ou se zerou
    PROCESS (sum, sum_norm, expb, lead0)
    BEGIN
        IF sum = "000000000" THEN -- Cancelamento exato, zero canonico            
            expn <= (OTHERS => '0');
            fracn <= (OTHERS => '0');
        ELSIF sum(8) = '1' THEN
            -- Com carry out: incrementa expoente e desloca frac para a direita
            expn <= expb + 1;
            fracn <= sum(8 DOWNTO 1);
        ELSIF (lead0 > expb) THEN
            -- Resultado muito pequeno para normalizar: zera o valor
            expn <= (OTHERS => '0');
            fracn <= (OTHERS => '0');
        ELSE
            -- Situação normal: subtrai os zeros engolidos do expoente
            expn <= expb - lead0;
            fracn <= sum_norm;
        END IF;
    END PROCESS;


    -- Atribuição das saídas
    sign_out <= '0' WHEN sum = "000000000" ELSE signb;
    exp_out <= STD_LOGIC_VECTOR(expn);
    frac_out <= STD_LOGIC_VECTOR(fracn);

    -- Conversão dos resultados para os displays de 7 segmentos
    hex_sign <= sign_to_7seg(sign_acc);
    hex_bit7 <= bit_to_7seg(frac_acc(7));
    hex_bit6 <= bit_to_7seg(frac_acc(6));
    hex_bit5 <= bit_to_7seg(frac_acc(5));
    hex_bit4 <= bit_to_7seg(frac_acc(4));
    hex_exp <= nibble_to_7seg(exp_acc);

    HEX5 <= hex_sign;
    HEX4 <= hex_bit7;
    HEX3 <= hex_bit6;
    HEX2 <= hex_bit5;
    HEX1 <= hex_bit4;
    HEX0 <= hex_exp;

END arch;