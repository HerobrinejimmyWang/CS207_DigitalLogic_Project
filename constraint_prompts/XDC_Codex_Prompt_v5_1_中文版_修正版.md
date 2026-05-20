# XDC Codex Prompt v5.1（中文修正版）

下面整段 prompt 可直接发给 Codex，用于生成 XDC。

```text
你现在要为 EGO1 FPGA 饮料售货机项目生成 Vivado XDC 约束文件。请严格按照以下最新版 v5 端口与 pin 规则生成，不要加入未使用端口。

【最终 TopModule 端口】
input  wire        sys_clk_in
input  wire        sys_rst_n
inout  wire [7:0]  exp_io
output wire [15:0] led_pin
output wire [7:0]  seg_cs_pin
output wire [7:0]  seg_data_0_pin
output wire [7:0]  seg_data_1_pin
output wire        vga_hs_pin
output wire        vga_vs_pin
output wire [11:0] vga_data_pin
output wire        audio_pwm_o
output wire        audio_sd_o

【禁止约束】
不要加入 btn_pin、sw_pin、dip_pin、UART、PS2、SRAM、DAC、XADC、蓝牙、未使用 exp_io[8:31] 等未使用端口约束。

【基础 pin】
sys_clk_in = P17
sys_rst_n  = P15
audio_pwm_o = T1
audio_sd_o  = M6

【矩阵键盘】
exp_io[0] = B16, Row0
exp_io[1] = A15, Row1
exp_io[2] = A13, Row2
exp_io[3] = B18, Row3
exp_io[4] = F13, Col0, PULLUP true
exp_io[5] = B13, Col1, PULLUP true
exp_io[6] = D14, Col2, PULLUP true
exp_io[7] = B11, Col3, PULLUP true
全部 IOSTANDARD LVCMOS33。

【LED】
led_pin[0]=F6, [1]=G4, [2]=G3, [3]=J4, [4]=H4, [5]=J3, [6]=J2, [7]=K2,
[8]=K1, [9]=H6, [10]=H5, [11]=J5, [12]=K6, [13]=L1, [14]=M1, [15]=K3。
全部 IOSTANDARD LVCMOS33。

【数码管位选】
seg_cs_pin[0]=G2, [1]=C2, [2]=C1, [3]=H1, [4]=G1, [5]=F1, [6]=E1, [7]=G6。
全部 IOSTANDARD LVCMOS33。

【数码管段选 0】
seg_data_0_pin[0]=B4, [1]=A4, [2]=A3, [3]=B1, [4]=A1, [5]=B3, [6]=B2, [7]=D5。
全部 IOSTANDARD LVCMOS33。

【数码管段选 1】
seg_data_1_pin[0]=D4, [1]=E3, [2]=D3, [3]=F4, [4]=F3, [5]=E2, [6]=D2, [7]=H2。
全部 IOSTANDARD LVCMOS33。

【VGA】
vga_hs_pin = D7
vga_vs_pin = C4
vga_data_pin[0]=F5, [1]=C6, [2]=C5, [3]=B7, [4]=B6, [5]=A6,
[6]=A5, [7]=D8, [8]=C7, [9]=E6, [10]=E5, [11]=E7。
其中 [3:0]=Red，[7:4]=Green，[11:8]=Blue。
全部 IOSTANDARD LVCMOS33。

【输出要求】
请生成一个完整 .xdc 文件。注释使用中文。不要解释，不要生成 Verilog，只输出 XDC 内容。
```
