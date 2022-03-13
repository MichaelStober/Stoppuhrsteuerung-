LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ca2_sm_package.all;

--  Entity Declaration
ENTITY StoppuhrSteuerung IS
    GENERIC(MOD_SM : INTEGER; n:integer:= 3);
    PORT
    (
        clk : IN STD_LOGIC;
        HW_Reset : IN STD_LOGIC;
        START : IN STD_LOGIC;
        STOPP : IN STD_LOGIC;
        RESET : IN STD_LOGIC;
        RUN : OUT STD_LOGIC;
        ZERO : OUT STD_LOGIC;
        --CNT : IN STD_LOGIC;
        seven_segs : OUT STD_LOGIC_VECTOR(6 downto 0)
	);
END StoppuhrSteuerung;

--  Architecture Body
ARCHITECTURE StoppuhrSteuerung_architecture OF StoppuhrSteuerung IS
  SIGNAL HWRn: STD_LOGIC;        -- Invertierter Reset
  SIGNAL FF_Enable: STD_LOGIC;   -- Clock-Gating Automat
  TYPE State is(Z0, Z1, Z2);     -- Z0 Uhr steht auf Null / Z1 Uhr laeuft / Z2 Uhr stopp
  SIGNAL Zact: State;
  SIGNAL Znext: State;
  CONSTANT zmax : integer := 5;
  SIGNAL counter_act, counter_next: integer RANGE 0 TO zmax;
BEGIN

  Comb: PROCESS (START, STOPP, RESET, Zact, Counter_act) IS
    BEGIN
 --übergangsfunktion
        Znext <= Zact;
        CASE Zact IS
            WHEN Z0 => IF Start = '1' Then
                           Znext <= Z1;
                       END IF;
            WHEN Z1 => IF Stopp = '1' Then
                           Znext <= Z2;
                       END IF;
            WHEN Z2 => IF Start = '1' Then
                           Znext <= Z1;
                       ELSIF Reset = '1' Then
                           Znext <= Z0;
                       END IF;
        END CASE;
--Ausgangsfunktion
        CASE Zact IS
            WHEN Z0 => Run <= '0'; Zero <= '1';
                       seven_segs <= "0000001";
            WHEN Z1 => Run <= '1'; Zero <= '-';
                       CASE Counter_act is
                               WHEN 0 => seven_segs <= "0111111";
                               WHEN 1 => seven_segs <= "1011111";
                               WHEN 2 => seven_segs <= "1101111";
                               WHEN 3 => seven_segs <= "1110111";
                               WHEN 4 => seven_segs <= "1111011";
                               WHEN 5 => seven_segs <= "1111101";
                       end case;
            WHEN Z2 => Run <= '0'; Zero <= '0';
                       seven_segs <= "1111110";
        END CASE;
END PROCESS Comb;

Trigger: PROCESS(clk, HW_Reset) IS
BEGIN
    IF (HW_Reset = '1') THEN
        Zact <= Z0;
    elsIF rising_edge(clk) THEN
        zact <= znext;
    END IF;
END PROCESS Trigger;

Comb1: ProCESS (counter_act) --zaehler Automat 
BEGIN
   IF (counter_act < zmax) THEN
       counter_next <= counter_act + 1;
   ELSE
       counter_next <= 0;
   END IF;
END PROCESS Comb1;

MTrigger: PROCESS(clk, HW_Reset) IS
BEGIN
    IF (HW_Reset = '1') THEN
        counter_act <= 0;
    ELSIF rising_edge(clk) THEN
        IF (FF_Enable = '1') THEN
           counter_act <= counter_next;
        END IF;
    END IF;
END PROCESS MTrigger;
  
  

  HWRn <= NOT HW_Reset ;
  Clki_inst: entity work.Mod_Counter
             generic map(n => 25000000)
             port map (clk => clk, PUReset_n => HWRn, OVF => FF_Enable);

END StoppuhrSteuerung_architecture;
