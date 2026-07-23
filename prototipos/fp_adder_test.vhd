LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fp_adder_test IS
    PORT (
        clk : IN STD_LOGIC;
        sw : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        btn : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        sseg : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END fp_adder_test;

ARCHITECTURE arch OF fp_adder_test IS
    SIGNAL sign1, sign2 : STD_LOGIC;
    SIGNAL exp1, exp2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL frac1, frac2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sign_out : STD_LOGIC;
    SIGNAL exp_out : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL frac_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL led3, led2, led1, led0 : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN

    -- Configuração dos sinais de entrada do somador FP
    sign1 <= '0';
    exp1 <= "1000";
    frac1 <= '1' & sw(1) & sw(0) & "10101";
    sign2 <= sw(7);
    exp2 <= btn;
    frac2 <= '1' & sw(6 DOWNTO 0);
    -- Instanciação do somador FP
    fp_add_unit : ENTITY work.fp_adder
        PORT MAP(
            sign1 => sign1, sign2 => sign2, exp1 => exp1, exp2 => exp2,
            frac1 => frac1, frac2 => frac2,
            sign_out => sign_out, exp_out => exp_out,
            frac_out => frac_out
        );

    -- Instanciação dos decodificadores hexadecimais para display de 7 segmentos
    -- Expoente
    sseg_unit_0 : ENTITY work.hex_to_sseg
        PORT MAP(hex => exp_out, dp => '0', sseg => led0);

    -- 4 LSBs do significando (fração)
    sseg_unit_1 : ENTITY work.hex_to_sseg
        PORT MAP(hex => frac_out(3 DOWNTO 0), dp => '1', sseg => led1);

    -- 4 MSBs do significando (fração)
    sseg_unit_2 : ENTITY work.hex_to_sseg
        PORT MAP(hex => frac_out(7 DOWNTO 4), dp => '0', sseg => led2);

    -- Exibição do sinal (+ / -)
    led3 <= "11111110" WHEN sign_out = '1' ELSE -- Traço central (sinal negativo)
        "11111111"; -- Apagado (sinal positivo)
        
    -- Instanciação do módulo de multiplexação temporal do display de 7 segmentos
    disp_unit : ENTITY work.disp_mux
        PORT MAP(
            clk => clk, reset => '0',
            in0 => led0, in1 => led1, in2 => led2, in3 => led3,
            an => an, sseg => sseg
        );
END arch;