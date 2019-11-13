library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity clocks is
generic (
    PERIOD_PICOS 	: integer := 2500;
    CLK_DIV_0   	: integer := 2;		-- 200MHz, 0 deg
    CLK_DIV_1   	: integer := 2;		-- 200MHz, 180 deg
    CLK_DIV_2   	: integer := 16;	-- 25MHz, 0 deg 
    CLK_DIV_3   	: integer := 8;		-- 50MHz, 0 deg
	CLK_DIV_4   	: integer := 4;		-- 100MHz, 0 deg
	
    BUF_OUT_MULT 	: integer := 4;
    DIVCLK_DIV  	: integer := 1
);
port (
	sys_clk     	  : in std_logic;
    sys_rst 	      : in std_logic;
	
    sync_reset_out       : out std_logic; -- sync_reset_out
    async_reset_out      : out std_logic;

    clk_100_mhz_0       : out std_logic; 
    clk_25_mhz_0        : out std_logic; -- clk0 
    clk_200_mhz_0     	: out std_logic; -- sysclk_2x
    clk_200_mhz_180   	: out std_logic; -- sysclk_2x_180
    clk_50_mhz_0       	: out std_logic; -- _mcb_drp_clk
    pll_ce_0          	: out std_logic;
    pll_ce_90         	: out std_logic;
    pll_lock          	: out std_logic
);
end entity;


architecture rtl of clocks is

  constant RESET_OUT_DELAY_CLKS   : integer := 24;
  constant PERIOD_NANOS  : real := (real(PERIOD_PICOS)) / 1000.0;

  signal   sys_clk_buffered       : std_logic;

  signal   clk_200_mhz_0_pll_out     : std_logic;
  signal   clk_200_mhz_180_pll_out   : std_logic;
  
  signal   clk_25_mhz_0_buf_out      : std_logic;
  signal   clk_25_mhz_0_pll_out      : std_logic;
  
  signal   clk_50_mhz_0_buf_out     : std_logic;
  signal   clk_50_mhz_0_pll_out 	: std_logic;
  
  signal   clk_100_mhz_0_buf_out     : std_logic;
  signal   clk_100_mhz_0_pll_out     : std_logic;

  signal   clkfbinout    	   : std_logic;
  signal   rst_tmp             : std_logic;
  
  
  signal   rst0_sync_r         : std_logic_vector(RESET_OUT_DELAY_CLKS downto 0);

  signal   seen_mcb_lock 	 : std_logic;
  signal   locked            : std_logic;
  signal   mcb_locked   	 : std_logic;
  

  attribute max_fanout : string;
  attribute max_fanout of rst0_sync_r : signal is "10";

  attribute syn_maxfan : integer;
  attribute syn_maxfan of rst0_sync_r : signal is 10;

  attribute KEEP : string; 
  attribute KEEP of sys_clk_buffered     : signal is "TRUE";

begin 

	-- input clock buffer 
	sysclk_buffer: IBUFG port map ( I  => sys_clk, O  => sys_clk_buffered );

	clk_25_mhz_0 <= clk_25_mhz_0_buf_out;
	clk_50_mhz_0 <= clk_50_mhz_0_buf_out;
	clk_100_mhz_0 <= clk_100_mhz_0_buf_out;

	-- output clock buffers 
    b25m: BUFG port map( O => clk_25_mhz_0_buf_out, I => clk_25_mhz_0_pll_out );
	
	b50m: BUFG port map ( O => clk_50_mhz_0_buf_out, I => clk_50_mhz_0_pll_out );

	b100m: BUFG port map ( O => clk_100_mhz_0_buf_out, I => clk_100_mhz_0_pll_out );


	pll_lock <= mcb_locked;

	pll: PLL_ADV generic map (
			 BANDWIDTH          => "OPTIMIZED",
			 CLKIN1_PERIOD      => PERIOD_NANOS,
			 CLKIN2_PERIOD      => PERIOD_NANOS,
			 CLKOUT0_DIVIDE     => CLK_DIV_0,
			 CLKOUT1_DIVIDE     => CLK_DIV_1,
			 CLKOUT2_DIVIDE     => CLK_DIV_2,
			 CLKOUT3_DIVIDE     => CLK_DIV_3,
			 CLKOUT4_DIVIDE     => CLK_DIV_4,
			 CLKOUT5_DIVIDE     => 1,
			 CLKOUT0_PHASE      => 0.000,
			 CLKOUT1_PHASE      => 180.000,
			 CLKOUT2_PHASE      => 0.000,
			 CLKOUT3_PHASE      => 0.000,
			 CLKOUT4_PHASE      => 0.000,
			 CLKOUT5_PHASE      => 0.000,
			 CLKOUT0_DUTY_CYCLE => 0.500,
			 CLKOUT1_DUTY_CYCLE => 0.500,
			 CLKOUT2_DUTY_CYCLE => 0.500,
			 CLKOUT3_DUTY_CYCLE => 0.500,
			 CLKOUT4_DUTY_CYCLE => 0.500,
			 CLKOUT5_DUTY_CYCLE => 0.500,
			 COMPENSATION       => "INTERNAL",
			 DIVCLK_DIVIDE      => DIVCLK_DIV,
			 CLKFBOUT_MULT      => BUF_OUT_MULT,
			 CLKFBOUT_PHASE     => 0.0,
			 REF_JITTER         => 0.005000
		)
        port map (
			CLKFBIN          => clkfbinout,
			CLKINSEL         => '1',
			CLKIN1           => sys_clk_buffered,
			CLKIN2           => '0',
			DADDR            => (others => '0'),
			DCLK             => '0',
			DEN              => '0',
			DI               => (others => '0'),
			DWE              => '0',
			REL              => '0',
			RST              => sys_rst,
			CLKFBDCM         => open,
			CLKFBOUT         => clkfbinout,
			CLKOUTDCM0       => open,
			CLKOUTDCM1       => open,
			CLKOUTDCM2       => open,
			CLKOUTDCM3       => open,
			CLKOUTDCM4       => open,
			CLKOUTDCM5       => open,
			CLKOUT0          => clk_200_mhz_0_pll_out,
			CLKOUT1          => clk_200_mhz_180_pll_out,
			CLKOUT2          => clk_25_mhz_0_pll_out,
			CLKOUT3          => clk_50_mhz_0_pll_out,
			CLKOUT4          => clk_100_mhz_0_pll_out,
			CLKOUT5          => open,
			DO               => open,
			DRDY             => open,
			LOCKED           => locked
	   );

	bufpllmcb: BUFPLL_MCB port map (
		IOCLK0         => clk_200_mhz_0,	
		IOCLK1         => clk_200_mhz_180, 
		LOCKED         => locked,
		GCLK           => clk_50_mhz_0_buf_out,
		SERDESSTROBE0  => pll_ce_0, 
		SERDESSTROBE1  => pll_ce_90, 
		PLLIN0         => clk_200_mhz_0_pll_out,  
		PLLIN1         => clk_200_mhz_180_pll_out,
		LOCK           => mcb_locked 
	);
	

	rst_tmp <= sys_rst or not(seen_mcb_lock);

	async_reset_out <= rst_tmp;
	
	process (clk_25_mhz_0_buf_out)
	begin
		if rising_edge(clk_25_mhz_0_buf_out) 
		then 
			if sys_rst = '1' 
			then 
				seen_mcb_lock <= '0';
			elsif mcb_locked = '1' 
			then 
				seen_mcb_lock <= '1';
			end if;
		end if;
	end process;
	
	rst0_sync_r <= 
		(others => '1') when rst_tmp = '1' else 
		(rst0_sync_r(RESET_OUT_DELAY_CLKS-1 downto 0) & '0') when rising_edge(clk_25_mhz_0_buf_out) else 
		unaffected;

	sync_reset_out  <= rst0_sync_r(RESET_OUT_DELAY_CLKS);

end architecture rtl;

