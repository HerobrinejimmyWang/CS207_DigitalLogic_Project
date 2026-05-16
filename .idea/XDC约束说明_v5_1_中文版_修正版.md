# EGO1 饮料售货机 XDC 约束说明 v5.1（中文修正版）

只包含最终设计使用端口；矩阵键盘、LED、数码管、VGA、audio PWM。

## 1. XDC 总原则

本 XDC 只约束最终 TopModule 会使用的端口：系统时钟、系统复位、矩阵键盘 exp_io[7:0]、LED、七段数码管、VGA、板载 audio PWM。不约束板载普通按键、拨码、DIP、UART、PS2、SRAM、DAC、XADC、蓝牙等未使用端口。

如果 RTL 顶层端口名与本文件不同，必须二选一：要么改 RTL 端口名，要么同步改 XDC。Vivado 的 get_ports 必须能匹配到顶层端口，否则约束不会生效。

## 2. 基础端口
| 功能 | 顶层端口 | 位 | FPGA Pin | 说明 |
| --- | --- | --- | --- | --- |
| 系统时钟 | sys_clk_in | - | P17 | 100 MHz 系统时钟 |
| 系统复位 | sys_rst_n | - | P15 | 板载 reset；设计默认按端口名低有效，内部 reset_sync 统一处理 |
| 音频 PWM | audio_pwm_o | - | T1 | 板载 audio PWM 输出 |
| 音频使能 | audio_sd_o | - | M6 | 板载音频使能 |

## 3. 矩阵键盘连接
| 矩阵键盘信号 | 顶层端口 | FPGA Pin | 方向/约束 | 说明 |
| --- | --- | --- | --- | --- |
| Row0 | exp_io[0] | B16 | inout；当前行拉低，其余高阻 | 连接矩阵键盘 Row0 |
| Row1 | exp_io[1] | A15 | inout；当前行拉低，其余高阻 | 连接矩阵键盘 Row1 |
| Row2 | exp_io[2] | A13 | inout；当前行拉低，其余高阻 | 连接矩阵键盘 Row2 |
| Row3 | exp_io[3] | B18 | inout；当前行拉低，其余高阻 | 连接矩阵键盘 Row3 |
| Col0 | exp_io[4] | F13 | 输入；PULLUP true | 连接矩阵键盘 Col0 |
| Col1 | exp_io[5] | B13 | 输入；PULLUP true | 连接矩阵键盘 Col1 |
| Col2 | exp_io[6] | D14 | 输入；PULLUP true | 连接矩阵键盘 Col2 |
| Col3 | exp_io[7] | B11 | 输入；PULLUP true | 连接矩阵键盘 Col3 |

矩阵键盘扫描建议：exp_io[0:3] 为行线，当前扫描行由顶层三态逻辑拉低，其他行高阻；exp_io[4:7] 为列线，XDC 加 PULLUP true。未按键时列为 1，按下当前行对应按键时列被拉低为 0。

## 4. LED 约束
| 端口 | FPGA Pin |
| --- | --- |
| led_pin[0] | F6 |
| led_pin[1] | G4 |
| led_pin[2] | G3 |
| led_pin[3] | J4 |
| led_pin[4] | H4 |
| led_pin[5] | J3 |
| led_pin[6] | J2 |
| led_pin[7] | K2 |
| led_pin[8] | K1 |
| led_pin[9] | H6 |
| led_pin[10] | H5 |
| led_pin[11] | J5 |
| led_pin[12] | K6 |
| led_pin[13] | L1 |
| led_pin[14] | M1 |
| led_pin[15] | K3 |

## 5. 七段数码管约束
EGO1 数码管片选和段选按高有效设计。

### 位选
| 端口 | FPGA Pin |
| --- | --- |
| seg_cs_pin[0] | G2 |
| seg_cs_pin[1] | C2 |
| seg_cs_pin[2] | C1 |
| seg_cs_pin[3] | H1 |
| seg_cs_pin[4] | G1 |
| seg_cs_pin[5] | F1 |
| seg_cs_pin[6] | E1 |
| seg_cs_pin[7] | G6 |

### 第一组段选
| 端口 | FPGA Pin | 段 |
| --- | --- | --- |
| seg_data_0_pin[0] | B4 | A0 |
| seg_data_0_pin[1] | A4 | B0 |
| seg_data_0_pin[2] | A3 | C0 |
| seg_data_0_pin[3] | B1 | D0 |
| seg_data_0_pin[4] | A1 | E0 |
| seg_data_0_pin[5] | B3 | F0 |
| seg_data_0_pin[6] | B2 | G0 |
| seg_data_0_pin[7] | D5 | DP0 |

### 第二组段选
| 端口 | FPGA Pin | 段 |
| --- | --- | --- |
| seg_data_1_pin[0] | D4 | A1 |
| seg_data_1_pin[1] | E3 | B1 |
| seg_data_1_pin[2] | D3 | C1 |
| seg_data_1_pin[3] | F4 | D1 |
| seg_data_1_pin[4] | F3 | E1 |
| seg_data_1_pin[5] | E2 | F1 |
| seg_data_1_pin[6] | D2 | G1 |
| seg_data_1_pin[7] | H2 | DP1 |

## 6. VGA 约束
vga_data_pin[3:0] = Red，vga_data_pin[7:4] = Green，vga_data_pin[11:8] = Blue。
| VGA 信号 | 顶层端口 | FPGA Pin |
| --- | --- | --- |
| Red0 | vga_data_pin[0] | F5 |
| Red1 | vga_data_pin[1] | C6 |
| Red2 | vga_data_pin[2] | C5 |
| Red3 | vga_data_pin[3] | B7 |
| Green0 | vga_data_pin[4] | B6 |
| Green1 | vga_data_pin[5] | A6 |
| Green2 | vga_data_pin[6] | A5 |
| Green3 | vga_data_pin[7] | D8 |
| Blue0 | vga_data_pin[8] | C7 |
| Blue1 | vga_data_pin[9] | E6 |
| Blue2 | vga_data_pin[10] | E5 |
| Blue3 | vga_data_pin[11] | E7 |
| HSYNC | vga_hs_pin | D7 |
| VSYNC | vga_vs_pin | C4 |

## 7. 顶层端口建议
```verilog
module TopModule(
    input  wire        sys_clk_in,
    input  wire        sys_rst_n,
    inout  wire [7:0]  exp_io,
    output wire [15:0] led_pin,
    output wire [7:0]  seg_cs_pin,
    output wire [7:0]  seg_data_0_pin,
    output wire [7:0]  seg_data_1_pin,
    output wire        vga_hs_pin,
    output wire        vga_vs_pin,
    output wire [11:0] vga_data_pin,
    output wire        audio_pwm_o,
    output wire        audio_sd_o
);
```
