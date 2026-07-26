LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY somadorFloat IS
    PORT (

        KEY : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 2 botões da placa (KEY0 e KEY1)
        SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 switches da placa (SW0 a SW9)
        LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0) -- 10 LEDs da placa (LEDR0 a LEDR9)
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

    -- MAQUINA DE ESTADOS
    TYPE state_type IS (S_LER_N1, S_LER_N2, S_RESULTADO);
    SIGNAL state : state_type := S_LER_N1; -- O programa começa no passo 1

    -- Registradores de Memória: Vão guardar os valores lidos nas chaves físicas
    SIGNAL sign1, sign2 : STD_LOGIC := '0';
    SIGNAL exp1, exp2 : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL frac1, frac2 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- Sinais que guardam o resultado da conta antes de enviar para os LEDs
    SIGNAL sign_out : STD_LOGIC;
    SIGNAL exp_out : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL frac_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    -- =========================================================
    -- MÁQUINA DE ESTADOS
    -- =========================================================

    -- Solução encontrada para para receber os dois números 
    -- e mostrar o resultado da soma, uma coisa de cada vez

    -- S_LER_N1:    Espera o primeiro número
    -- S_LER_N2:    Espera o segundo número
    -- S_RESULTADO: Mostra o resultado da soma

    -- KEY(0) avança para o próximo estado
    -- KEY(1) reseta a máquina de estados

    PROCESS (KEY)
    BEGIN

        -- O botão KEY0 avança para o próximo estado
        IF (KEY(0) = '0') THEN
            CASE state IS
                WHEN S_LER_N1 =>
                    state <= S_LER_N2;
                WHEN S_LER_N2 =>
                    state <= S_RESULTADO;
                WHEN S_RESULTADO =>
                    state <= S_LER_N1;
            END CASE;
        END IF;

        -- O botão KEY1 atua como reset
        IF (KEY(1) = '0') THEN
            state <= S_LER_N1;
        END IF;

        CASE state IS

            WHEN S_LER_N1 =>
                LEDR <= SW;                         -- Os leds imitam as chaves
                sign1 <= SW(9);                     -- Chave 9 vira o sinal do num1
                exp1 <= SW(8 DOWNTO 5);             -- Chaves 8 a 5 viram o expoente do num1
                frac1 <= SW(4 DOWNTO 0) & "000";    -- Chaves 4 a 0 viram a fração (completada com zeros)

            WHEN S_LER_N2 =>
                LEDR <= SW;                         -- Os leds imitam as chaves
                sign2 <= SW(9);                     -- Chave 9 vira o sinal do num2
                exp2 <= SW(8 DOWNTO 5);             -- Chaves 8 a 5 viram o expoente do num2
                frac2 <= SW(4 DOWNTO 0) & "000";    -- Chaves 4 a 0 viram a fração

            WHEN S_RESULTADO =>
                LEDR(9) <= sign_out;                        -- Sinal do resultado
                LEDR(8 DOWNTO 5) <= exp_out;                -- Expoente do resultado
                LEDR(4 DOWNTO 0) <= frac_out(7 DOWNTO 3);   -- Fração do resultado (apenas os 5 bits mais significativos)

        END CASE;

    END PROCESS;

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
        IF sum(8) = '1' THEN
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
    sign_out <= signb;
    exp_out <= STD_LOGIC_VECTOR(expn);
    frac_out <= STD_LOGIC_VECTOR(fracn);

END arch;