set_property PACKAGE_PIN P17 [get_ports sys_clk_in] # 系统时钟输入 SYS_CLK，EGO1 板载 100MHz
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk_in] # 系统时钟 IO 电平标准 3.3V LVCMOS
create_clock -period 10.000 -name sys_clk_in -waveform {0.000 5.000} [get_ports sys_clk_in] # 为 100MHz 系统时钟创建时序约束
set_property PACKAGE_PIN P15 [get_ports sys_rst_n] # 板载 FPGA_RESET 复位输入，RTL 端口名按低有效命名
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n] # 复位输入 IO 电平标准 3.3V LVCMOS
set_property PACKAGE_PIN B16 [get_ports {exp_io[0]}] # J5 扩展口 Row0，矩阵键盘第 0 行
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[0]}] # Row0 使用 3.3V LVCMOS
set_property PACKAGE_PIN A15 [get_ports {exp_io[1]}] # J5 扩展口 Row1，矩阵键盘第 1 行
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[1]}] # Row1 使用 3.3V LVCMOS
set_property PACKAGE_PIN A13 [get_ports {exp_io[2]}] # J5 扩展口 Row2，矩阵键盘第 2 行
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[2]}] # Row2 使用 3.3V LVCMOS
set_property PACKAGE_PIN B18 [get_ports {exp_io[3]}] # J5 扩展口 Row3，矩阵键盘第 3 行
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[3]}] # Row3 使用 3.3V LVCMOS
set_property PACKAGE_PIN F13 [get_ports {exp_io[4]}] # J5 扩展口 Col0，矩阵键盘第 0 列
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[4]}] # Col0 使用 3.3V LVCMOS
set_property PULLUP true [get_ports {exp_io[4]}] # Col0 启用内部上拉，未按键时保持高电平
set_property PACKAGE_PIN B13 [get_ports {exp_io[5]}] # J5 扩展口 Col1，矩阵键盘第 1 列
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[5]}] # Col1 使用 3.3V LVCMOS
set_property PULLUP true [get_ports {exp_io[5]}] # Col1 启用内部上拉，未按键时保持高电平
set_property PACKAGE_PIN D14 [get_ports {exp_io[6]}] # J5 扩展口 Col2，矩阵键盘第 2 列
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[6]}] # Col2 使用 3.3V LVCMOS
set_property PULLUP true [get_ports {exp_io[6]}] # Col2 启用内部上拉，未按键时保持高电平
set_property PACKAGE_PIN B11 [get_ports {exp_io[7]}] # J5 扩展口 Col3，矩阵键盘第 3 列
set_property IOSTANDARD LVCMOS33 [get_ports {exp_io[7]}] # Col3 使用 3.3V LVCMOS
set_property PULLUP true [get_ports {exp_io[7]}] # Col3 启用内部上拉，未按键时保持高电平
set_property PACKAGE_PIN F6 [get_ports {led_pin[0]}] # LED 输出 led_pin[0]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[0]}] # led_pin[0] 使用 3.3V LVCMOS
set_property PACKAGE_PIN G4 [get_ports {led_pin[1]}] # LED 输出 led_pin[1]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[1]}] # led_pin[1] 使用 3.3V LVCMOS
set_property PACKAGE_PIN G3 [get_ports {led_pin[2]}] # LED 输出 led_pin[2]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[2]}] # led_pin[2] 使用 3.3V LVCMOS
set_property PACKAGE_PIN J4 [get_ports {led_pin[3]}] # LED 输出 led_pin[3]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[3]}] # led_pin[3] 使用 3.3V LVCMOS
set_property PACKAGE_PIN H4 [get_ports {led_pin[4]}] # LED 输出 led_pin[4]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[4]}] # led_pin[4] 使用 3.3V LVCMOS
set_property PACKAGE_PIN J3 [get_ports {led_pin[5]}] # LED 输出 led_pin[5]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[5]}] # led_pin[5] 使用 3.3V LVCMOS
set_property PACKAGE_PIN J2 [get_ports {led_pin[6]}] # LED 输出 led_pin[6]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[6]}] # led_pin[6] 使用 3.3V LVCMOS
set_property PACKAGE_PIN K2 [get_ports {led_pin[7]}] # LED 输出 led_pin[7]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[7]}] # led_pin[7] 使用 3.3V LVCMOS
set_property PACKAGE_PIN K1 [get_ports {led_pin[8]}] # LED 输出 led_pin[8]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[8]}] # led_pin[8] 使用 3.3V LVCMOS
set_property PACKAGE_PIN H6 [get_ports {led_pin[9]}] # LED 输出 led_pin[9]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[9]}] # led_pin[9] 使用 3.3V LVCMOS
set_property PACKAGE_PIN H5 [get_ports {led_pin[10]}] # LED 输出 led_pin[10]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[10]}] # led_pin[10] 使用 3.3V LVCMOS
set_property PACKAGE_PIN J5 [get_ports {led_pin[11]}] # LED 输出 led_pin[11]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[11]}] # led_pin[11] 使用 3.3V LVCMOS
set_property PACKAGE_PIN K6 [get_ports {led_pin[12]}] # LED 输出 led_pin[12]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[12]}] # led_pin[12] 使用 3.3V LVCMOS
set_property PACKAGE_PIN L1 [get_ports {led_pin[13]}] # LED 输出 led_pin[13]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[13]}] # led_pin[13] 使用 3.3V LVCMOS
set_property PACKAGE_PIN M1 [get_ports {led_pin[14]}] # LED 输出 led_pin[14]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[14]}] # led_pin[14] 使用 3.3V LVCMOS
set_property PACKAGE_PIN K3 [get_ports {led_pin[15]}] # LED 输出 led_pin[15]，高电平点亮
set_property IOSTANDARD LVCMOS33 [get_ports {led_pin[15]}] # led_pin[15] 使用 3.3V LVCMOS
set_property PACKAGE_PIN G2 [get_ports {seg_cs_pin[0]}] # 七段数码管位选 BIT1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[0]}] # seg_cs_pin[0] 使用 3.3V LVCMOS
set_property PACKAGE_PIN C2 [get_ports {seg_cs_pin[1]}] # 七段数码管位选 BIT2，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[1]}] # seg_cs_pin[1] 使用 3.3V LVCMOS
set_property PACKAGE_PIN C1 [get_ports {seg_cs_pin[2]}] # 七段数码管位选 BIT3，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[2]}] # seg_cs_pin[2] 使用 3.3V LVCMOS
set_property PACKAGE_PIN H1 [get_ports {seg_cs_pin[3]}] # 七段数码管位选 BIT4，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[3]}] # seg_cs_pin[3] 使用 3.3V LVCMOS
set_property PACKAGE_PIN G1 [get_ports {seg_cs_pin[4]}] # 七段数码管位选 BIT5，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[4]}] # seg_cs_pin[4] 使用 3.3V LVCMOS
set_property PACKAGE_PIN F1 [get_ports {seg_cs_pin[5]}] # 七段数码管位选 BIT6，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[5]}] # seg_cs_pin[5] 使用 3.3V LVCMOS
set_property PACKAGE_PIN E1 [get_ports {seg_cs_pin[6]}] # 七段数码管位选 BIT7，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[6]}] # seg_cs_pin[6] 使用 3.3V LVCMOS
set_property PACKAGE_PIN G6 [get_ports {seg_cs_pin[7]}] # 七段数码管位选 BIT8，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cs_pin[7]}] # seg_cs_pin[7] 使用 3.3V LVCMOS
set_property PACKAGE_PIN B4 [get_ports {seg_data_0_pin[0]}] # 第一组七段段选 A0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[0]}] # seg_data_0_pin[0] 使用 3.3V LVCMOS
set_property PACKAGE_PIN A4 [get_ports {seg_data_0_pin[1]}] # 第一组七段段选 B0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[1]}] # seg_data_0_pin[1] 使用 3.3V LVCMOS
set_property PACKAGE_PIN A3 [get_ports {seg_data_0_pin[2]}] # 第一组七段段选 C0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[2]}] # seg_data_0_pin[2] 使用 3.3V LVCMOS
set_property PACKAGE_PIN B1 [get_ports {seg_data_0_pin[3]}] # 第一组七段段选 D0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[3]}] # seg_data_0_pin[3] 使用 3.3V LVCMOS
set_property PACKAGE_PIN A1 [get_ports {seg_data_0_pin[4]}] # 第一组七段段选 E0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[4]}] # seg_data_0_pin[4] 使用 3.3V LVCMOS
set_property PACKAGE_PIN B3 [get_ports {seg_data_0_pin[5]}] # 第一组七段段选 F0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[5]}] # seg_data_0_pin[5] 使用 3.3V LVCMOS
set_property PACKAGE_PIN B2 [get_ports {seg_data_0_pin[6]}] # 第一组七段段选 G0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[6]}] # seg_data_0_pin[6] 使用 3.3V LVCMOS
set_property PACKAGE_PIN D5 [get_ports {seg_data_0_pin[7]}] # 第一组七段小数点 DP0，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_0_pin[7]}] # seg_data_0_pin[7] 使用 3.3V LVCMOS
set_property PACKAGE_PIN D4 [get_ports {seg_data_1_pin[0]}] # 第二组七段段选 A1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[0]}] # seg_data_1_pin[0] 使用 3.3V LVCMOS
set_property PACKAGE_PIN E3 [get_ports {seg_data_1_pin[1]}] # 第二组七段段选 B1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[1]}] # seg_data_1_pin[1] 使用 3.3V LVCMOS
set_property PACKAGE_PIN D3 [get_ports {seg_data_1_pin[2]}] # 第二组七段段选 C1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[2]}] # seg_data_1_pin[2] 使用 3.3V LVCMOS
set_property PACKAGE_PIN F4 [get_ports {seg_data_1_pin[3]}] # 第二组七段段选 D1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[3]}] # seg_data_1_pin[3] 使用 3.3V LVCMOS
set_property PACKAGE_PIN F3 [get_ports {seg_data_1_pin[4]}] # 第二组七段段选 E1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[4]}] # seg_data_1_pin[4] 使用 3.3V LVCMOS
set_property PACKAGE_PIN E2 [get_ports {seg_data_1_pin[5]}] # 第二组七段段选 F1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[5]}] # seg_data_1_pin[5] 使用 3.3V LVCMOS
set_property PACKAGE_PIN D2 [get_ports {seg_data_1_pin[6]}] # 第二组七段段选 G1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[6]}] # seg_data_1_pin[6] 使用 3.3V LVCMOS
set_property PACKAGE_PIN H2 [get_ports {seg_data_1_pin[7]}] # 第二组七段小数点 DP1，高有效
set_property IOSTANDARD LVCMOS33 [get_ports {seg_data_1_pin[7]}] # seg_data_1_pin[7] 使用 3.3V LVCMOS
set_property PACKAGE_PIN D7 [get_ports vga_hs_pin] # VGA 行同步 HSYNC
set_property IOSTANDARD LVCMOS33 [get_ports vga_hs_pin] # VGA 行同步使用 3.3V LVCMOS
set_property PACKAGE_PIN C4 [get_ports vga_vs_pin] # VGA 场同步 VSYNC
set_property IOSTANDARD LVCMOS33 [get_ports vga_vs_pin] # VGA 场同步使用 3.3V LVCMOS
set_property PACKAGE_PIN F5 [get_ports {vga_data_pin[0]}] # VGA Red0，vga_data_pin[3:0] 为红色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[0]}] # VGA Red0 使用 3.3V LVCMOS
set_property PACKAGE_PIN C6 [get_ports {vga_data_pin[1]}] # VGA Red1，vga_data_pin[3:0] 为红色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[1]}] # VGA Red1 使用 3.3V LVCMOS
set_property PACKAGE_PIN C5 [get_ports {vga_data_pin[2]}] # VGA Red2，vga_data_pin[3:0] 为红色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[2]}] # VGA Red2 使用 3.3V LVCMOS
set_property PACKAGE_PIN B7 [get_ports {vga_data_pin[3]}] # VGA Red3，vga_data_pin[3:0] 为红色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[3]}] # VGA Red3 使用 3.3V LVCMOS
set_property PACKAGE_PIN B6 [get_ports {vga_data_pin[4]}] # VGA Green0，vga_data_pin[7:4] 为绿色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[4]}] # VGA Green0 使用 3.3V LVCMOS
set_property PACKAGE_PIN A6 [get_ports {vga_data_pin[5]}] # VGA Green1，vga_data_pin[7:4] 为绿色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[5]}] # VGA Green1 使用 3.3V LVCMOS
set_property PACKAGE_PIN A5 [get_ports {vga_data_pin[6]}] # VGA Green2，vga_data_pin[7:4] 为绿色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[6]}] # VGA Green2 使用 3.3V LVCMOS
set_property PACKAGE_PIN D8 [get_ports {vga_data_pin[7]}] # VGA Green3，vga_data_pin[7:4] 为绿色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[7]}] # VGA Green3 使用 3.3V LVCMOS
set_property PACKAGE_PIN C7 [get_ports {vga_data_pin[8]}] # VGA Blue0，vga_data_pin[11:8] 为蓝色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[8]}] # VGA Blue0 使用 3.3V LVCMOS
set_property PACKAGE_PIN E6 [get_ports {vga_data_pin[9]}] # VGA Blue1，vga_data_pin[11:8] 为蓝色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[9]}] # VGA Blue1 使用 3.3V LVCMOS
set_property PACKAGE_PIN E5 [get_ports {vga_data_pin[10]}] # VGA Blue2，vga_data_pin[11:8] 为蓝色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[10]}] # VGA Blue2 使用 3.3V LVCMOS
set_property PACKAGE_PIN E7 [get_ports {vga_data_pin[11]}] # VGA Blue3，vga_data_pin[11:8] 为蓝色通道
set_property IOSTANDARD LVCMOS33 [get_ports {vga_data_pin[11]}] # VGA Blue3 使用 3.3V LVCMOS
set_property PACKAGE_PIN T1 [get_ports audio_pwm_o] # 板载音频 PWM 输出
set_property IOSTANDARD LVCMOS33 [get_ports audio_pwm_o] # 音频 PWM 使用 3.3V LVCMOS
set_property PACKAGE_PIN M6 [get_ports audio_sd_o] # 板载音频 SD 使能输出，对应 AUDIO_SD#
set_property IOSTANDARD LVCMOS33 [get_ports audio_sd_o] # 音频 SD 使能使用 3.3V LVCMOS
