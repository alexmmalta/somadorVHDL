LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY fp_adder IS
    PORT (
        sign1, sign2 : IN STD_LOGIC;
        exp1, exp2 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        frac1, frac2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        sign_out : OUT STD_LOGIC;
        exp_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        frac_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END fp_adder;
ARCHITECTURE arch OF fp_adder IS
    -- Sufixos b, s, a, n para número grande (big), pequeno (small), alinhado (aligned) e normalizado
    SIGNAL signb, signs : STD_LOGIC;
    SIGNAL expb, exps, expn : unsigned(3 DOWNTO 0);
    SIGNAL fracb, fracs, fraca, fracn : unsigned(7 DOWNTO 0);
    SIGNAL sum_norm : unsigned(7 DOWNTO 0);
    SIGNAL exp_diff : unsigned(3 DOWNTO 0);
    SIGNAL sum : unsigned(8 DOWNTO 0); -- 1 bit extra para o carry (vai-um)
    SIGNAL lead0 : unsigned(2 DOWNTO 0);
BEGIN

    -- 1º Estágio: ordenar para identificar o maior número
    PROCESS (sign1, sign2, exp1, exp2, frac1, frac2)
    BEGIN
        IF (exp1 & frac1) > (exp2 & frac2) THEN
            signb <= sign1;
            signs <= sign2;
            expb <= unsigned(exp1);
            exps <= unsigned(exp2);
            fracb <= unsigned(frac1);
            fracs <= unsigned(frac2);
        ELSE
            signb <= sign2;
            signs <= sign1;
            expb <= unsigned(exp2);
            exps <= unsigned(exp1);
            fracb <= unsigned(frac2);
            fracs <= unsigned(frac1);
        END IF;
    END PROCESS;

    -- 2º Estágio: alinhar o menor número
    exp_diff <= expb - exps;
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

    -- 3º Estágio: somar / subtrair
    sum <= ('0' & fracb) + ('0' & fraca) WHEN signb = signs ELSE
        ('0' & fracb) - ('0' & fraca);

    -- 4º Estágio: normalizar
    -- Contar zeros à esquerda
    lead0 <=
        "000" WHEN sum(7) = '1' ELSE
        "001" WHEN sum(6) = '1' ELSE
        "010" WHEN sum(5) = '1' ELSE
        "011" WHEN sum(4) = '1' ELSE
        "100" WHEN sum(3) = '1' ELSE
        "101" WHEN sum(2) = '1' ELSE
        "110" WHEN sum(1) = '1' ELSE
        "111";
    -- Deslocar o significando conforme a contagem de zeros
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
    -- Normalização sob condições especiais
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
            expn <= expb - lead0;
            fracn <= sum_norm;
        END IF;
    END PROCESS;
    
    -- Atribuição das saídas
    sign_out <= signb;
    exp_out <= STD_LOGIC_VECTOR(expn);
    frac_out <= STD_LOGIC_VECTOR(fracn);
END arch;