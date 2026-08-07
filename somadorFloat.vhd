LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY somadorFloat IS
    PORT (

        KEY  : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 2 botões da placa (KEY0 e KEY1)
        SW   : IN STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 switches da placa (SW0 a SW9)

        LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 LEDs da placa (LEDR0 a LEDR9)
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- 7 segmentos do display HEX0
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END somadorFloat;

ARCHITECTURE arch OF somadorFloat IS

    -- =========================================================
    -- No projeto base os 2 operandos chegam prontos nas portas sign1/exp1/frac1
    -- e sign2/exp2/frac2. Aqui só há 1 operando físico (os switches), então um dos
    -- lados do somador é o acumulador (sign_acc/exp_acc/frac_acc), e o outro é a
    -- entrada atual (sign_in/exp_in/frac_in) que vem dos switches.
    -- =========================================================
    SIGNAL sign_acc : STD_LOGIC := '0';
    SIGNAL exp_acc  : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL frac_acc : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL sign_in : STD_LOGIC;
    SIGNAL exp_in  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL frac_in : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Resultado do somador para realimentar o acumulador e os displays
    SIGNAL sign_out : STD_LOGIC;
    SIGNAL exp_out  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL frac_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- =========================================================
    -- SINAIS: NORMALIZAÇÃO DO OPERANDO DE ENTRADA
    -- No projeto base a mantissa de entrada já chega normalizada (bit mais
    -- significativo = '1'). Aqui  ela é normalizada antes de entrar no somador.
    -- Do contrário o comparador/subtrator  pode escolher o operando
    -- errado como "maior" e estourar por baixo numa subtração.
    -- =========================================================
    SIGNAL frac_in_raw     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL frac_in_shifted : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL lead0_in        : unsigned(3 DOWNTO 0);

    -- =========================================================
    -- SINAIS: NÚCLEO DO SOMADOR DE PONTO FLUTUANTE
    -- mantidos como no projeto base
    -- sufixos: [b]ig (maior número), [s]mall (menor), [a]ligned, [n]ormalized
    -- =========================================================
    SIGNAL signb, signs : STD_LOGIC;
    SIGNAL expb, exps, expn : unsigned(3 DOWNTO 0);
    SIGNAL fracb, fracs, fraca, fracn : unsigned(7 DOWNTO 0);
    SIGNAL sum_norm : unsigned(7 DOWNTO 0);
    SIGNAL exp_diff : unsigned(3 DOWNTO 0);
    SIGNAL sum : unsigned(8 DOWNTO 0); -- 1 bit extra para o carry (vai-um)
    SIGNAL lead0 : unsigned(2 DOWNTO 0);

    -- =========================================================
    -- SINAIS E FUNÇÕES: DISPLAYS DE 7 SEGMENTOS
    -- Usados para converter os bits do acumulador em sinais para os 6 displays.
    -- formato: sinal[1] | mantissa[4] | expoente em hexadecimal[1]
    -- =========================================================
    SIGNAL hex_sign : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit7 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit6 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_bit4 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL hex_exp  : STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Conversões para o display de 7 segmentos
    FUNCTION exp_to_7seg(d : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE d IS
            --  expoente     seg:  7654321
            WHEN "0000" => RETURN "1000000"; -- 0   ┌─ 1 ─┐
            WHEN "0001" => RETURN "1111001"; -- 1   6     2
            WHEN "0010" => RETURN "0100100"; -- 2   ├─ 7 ─┤
            WHEN "0011" => RETURN "0110000"; -- 3   5     3
            WHEN "0100" => RETURN "0011001"; -- 4   └─ 4 ─┘
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
    END FUNCTION exp_to_7seg;

    FUNCTION bit_to_7seg(b : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        IF b = '1'  THEN RETURN "1111001"; -- 1
                    ELSE RETURN "1000000"; -- 0
        END IF;
    END FUNCTION bit_to_7seg;

    FUNCTION sign_to_7seg(s : STD_LOGIC) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        IF s = '1' THEN RETURN "0111111"; -- - (menos)
                   ELSE RETURN "1111111"; --   (vazio)
        END IF;
    END FUNCTION sign_to_7seg;

BEGIN

    -- =========================================================
    -- 1. ENTRADA DE DADOS E LEDs
    -- Formato do switch: SW(9)=sinal, SW(8-5)=expoente, SW(4-0)=mantissa
    -- =========================================================
    sign_in     <= SW(9);
    frac_in_raw <= SW(4 DOWNTO 0) & "000"; -- alinha a mantissa de 5 bits ao formato interno de 8 bits
    LEDR        <= SW;                     -- mostra os switches nos LEDs

    -- =========================================================
    -- 2. NORMALIZAÇÃO DO OPERANDO DE ENTRADA
    -- =========================================================
    -- Conta os zeros à esquerda de frac_in_raw (0 a 8)
    lead0_in <=
        "0000" WHEN frac_in_raw(7) = '1' ELSE
        "0001" WHEN frac_in_raw(6) = '1' ELSE
        "0010" WHEN frac_in_raw(5) = '1' ELSE
        "0011" WHEN frac_in_raw(4) = '1' ELSE
        "0100" WHEN frac_in_raw(3) = '1' ELSE
        "0101" WHEN frac_in_raw(2) = '1' ELSE
        "0110" WHEN frac_in_raw(1) = '1' ELSE
        "0111" WHEN frac_in_raw(0) = '1' ELSE
        "1000"; -- fração toda zero

    -- Desloca frac_in_raw para a esquerda por lead0_in posições
    WITH lead0_in SELECT
        frac_in_shifted <=
        frac_in_raw                             WHEN "0000",
        frac_in_raw(6 DOWNTO 0) &        '0'    WHEN "0001",
        frac_in_raw(5 DOWNTO 0) &       "00"    WHEN "0010",
        frac_in_raw(4 DOWNTO 0) &      "000"    WHEN "0011",
        frac_in_raw(3 DOWNTO 0) &     "0000"    WHEN "0100",
        frac_in_raw(2 DOWNTO 0) &    "00000"    WHEN "0101",
        frac_in_raw(1 DOWNTO 0) &   "000000"    WHEN "0110",
        frac_in_raw(0)          &  "0000000"    WHEN "0111",
                                  "00000000"    WHEN OTHERS;

    -- Ajusta o expoente de entrada subtraindo os zeros engolidos
    PROCESS (frac_in_raw, frac_in_shifted, lead0_in, SW)
        VARIABLE exp_raw : unsigned(3 DOWNTO 0);

    BEGIN
        exp_raw := unsigned(SW(8 DOWNTO 5));

        IF (frac_in_raw = "00000000") OR (lead0_in > exp_raw) THEN
            -- mantissa nula ou expoente insuficiente para normalizar: entra como zero canônico
            -- para não gerar overflow negativo no somador, o expoente é ajustado para zero
            exp_in  <= (OTHERS => '0');
            frac_in <= (OTHERS => '0');

        ELSE
            -- Situação normal: subtrai os zeros engolidos do expoente
            exp_in  <= STD_LOGIC_VECTOR(exp_raw - lead0_in);

            -- desloca a mantissa para a esquerda
            frac_in <= frac_in_shifted;

        END IF;
    END PROCESS;

    -- =========================================================
    -- 3. NÚCLEO DO SOMADOR
    -- Toda a lógica do somador de combinacional do projeto base é mantida.
    -- Apenas os nomes dos sinais foram alterados para refletir a presença do acumulador
    -- e a entrada atual que vem dos switches.
    -- =========================================================

    -- 1º Estágio: ordenar para identificar o maior número
    PROCESS (sign_acc, sign_in, exp_acc, exp_in, frac_acc, frac_in)
    BEGIN
        IF (exp_acc & frac_acc) > (exp_in & frac_in) THEN
        -- Se o acumulador for maior
            signb <= sign_acc;
            signs <= sign_in;
            expb  <= unsigned(exp_acc);
            exps  <= unsigned(exp_in);
            fracb <= unsigned(frac_acc);
            fracs <= unsigned(frac_in);
        ELSE
        -- Se a entrada atual for maior (ou igual)
            signb <= sign_in;
            signs <= sign_acc;
            expb  <= unsigned(exp_in);
            exps  <= unsigned(exp_acc);
            fracb <= unsigned(frac_in);
            fracs <= unsigned(frac_acc);
        END IF;
    END PROCESS;

    -- 2º Estágio: alinhar o menor número
    exp_diff <= expb - exps; -- Calcula a diferença dos expoentes    
    WITH exp_diff SELECT     -- Desloca a mantissa do menor número para a direita
        fraca <=
        fracs WHEN "0000",
        "0"         & fracs(7 DOWNTO 1) WHEN "0001",
        "00"        & fracs(7 DOWNTO 2) WHEN "0010",
        "000"       & fracs(7 DOWNTO 3) WHEN "0011",
        "0000"      & fracs(7 DOWNTO 4) WHEN "0100",
        "00000"     & fracs(7 DOWNTO 5) WHEN "0101",
        "000000"    & fracs(7 DOWNTO 6) WHEN "0110",
        "0000000"   & fracs(7)          WHEN "0111",
        "00000000"                      WHEN OTHERS;

    -- 3º Estágio: Adição ou Subtração
    -- Se os sinais forem iguais, soma. Se forem diferentes, subtrai.
    -- O '0' adicionado na frente é para dar espaço para um eventual "vai um" (carry)
    sum <= ('0' & fracb) + ('0' & fraca)
    WHEN   signb = signs 
    ELSE   ('0' & fracb) - ('0' & fraca);

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

    -- 4.2: Empurra os bits para a esquerda
    WITH lead0 SELECT
        sum_norm <=
        sum(7 DOWNTO 0)             WHEN "000",
        sum(6 DOWNTO 0) &       '0' WHEN "001",
        sum(5 DOWNTO 0) &      "00" WHEN "010",
        sum(4 DOWNTO 0) &     "000" WHEN "011",
        sum(3 DOWNTO 0) &    "0000" WHEN "100",
        sum(2 DOWNTO 0) &   "00000" WHEN "101",
        sum(1 DOWNTO 0) &  "000000" WHEN "110",
        sum(0)          & "0000000" WHEN OTHERS;

    -- 4.3: Ajusta o expoente final dependendo se houve "vai-um" ou se zerou
    -- Foram adicionadas verificações para o caso do resultado ser zero.
    PROCESS (sum, sum_norm, expb, lead0)
    BEGIN

        IF sum(8) = '1' THEN
        -- Com carry out: incrementa expoente e desloca frac para a direita
            expn  <= expb + 1;
            fracn <= sum(8 DOWNTO 1);

        ELSIF (lead0 > expb) OR (sum = "000000000") THEN
        -- Resultado muito pequeno para normalizar ou resultado é zero
            expn  <= (OTHERS => '0');
            fracn <= (OTHERS => '0');

        ELSE
        -- Situação normal: subtrai os zeros engolidos do expoente
            expn  <= expb - lead0;
            fracn <= sum_norm;

        END IF;
    END PROCESS;

    -- Atribuição das saídas
    sign_out <= '0'
    WHEN        sum = "000000000"
    ELSE        signb;
    exp_out  <= STD_LOGIC_VECTOR(expn);
    frac_out <= STD_LOGIC_VECTOR(fracn);

    -- =========================================================
    -- 4. CONTROLE DO ACUMULADOR
    -- KEY(0) grava o resultado do somador no acumulador;
    -- KEY(1) zera o acumulador.
    -- Substitui a 2ª entrada física que o projeto base exigiria.
    -- =========================================================
    PROCESS (KEY)
    BEGIN

        IF (KEY(1) = '0') THEN
        -- botão KEY(1) pressionado
        -- zera o acumulador
            sign_acc <= '0';
            exp_acc  <= (OTHERS => '0');
            frac_acc <= (OTHERS => '0');

        ELSIF falling_edge(KEY(0)) THEN
        -- borda de descida de KEY(0)
        -- grava o resultado do somador no acumulador
            sign_acc <= sign_out;
            exp_acc  <= exp_out;
            frac_acc <= frac_out;

        END IF;
    END PROCESS;

    -- =========================================================
    -- 5. SAÍDAS PARA OS DISPLAYS DE 7 SEGMENTOS
    -- =========================================================
    hex_sign <= sign_to_7seg(sign_acc);
    hex_bit7 <= bit_to_7seg(frac_acc(7));
    hex_bit6 <= bit_to_7seg(frac_acc(6));
    hex_bit5 <= bit_to_7seg(frac_acc(5));
    hex_bit4 <= bit_to_7seg(frac_acc(4));
    hex_exp  <= exp_to_7seg(exp_acc);

    HEX5 <= hex_sign;
    HEX4 <= hex_bit7;
    HEX3 <= hex_bit6;
    HEX2 <= hex_bit5;
    HEX1 <= hex_bit4;
    HEX0 <= hex_exp;

END arch;