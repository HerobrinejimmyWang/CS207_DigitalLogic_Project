# EGO1 引脚速查

本文用于后续项目 Agent 快速查阅 EGO1 开发板上最常用的引脚与有效电平信息，优先整理课程项目里高频使用的时钟、复位、按键、拨码开关、LED、数码管、串口、VGA、PS/2、蓝牙和扩展 IO。

来源：EGO1 用户手册 [Ego1_UserManual_v2.2.pdf](Ego1_UserManual_v2.2.pdf)。

## 使用说明

- 本文优先保留手册中明确写出的信息。
- 对于手册文本抽取得比较碎的表格，按功能重新分组整理。
- 未在手册中明确说明有效电平的信号，不在这里擅自推断。

## 1. 基础时钟与复位

| 功能 | 手册标号 | FPGA 管脚 | 说明 |
| --- | --- | --- | --- |
| 板载系统时钟 | SYS_CLK | P17 | 100MHz 时钟，直接送入 FPGA 全局时钟网络 |
| 复位引脚 | FPGA_RESET | P15 | 逻辑复位相关信号 |
| 专用复位键 | RST / S6 | 未给出 FPGA IO | 用于逻辑复位，属于专用按键 |
| 专用配置擦除键 | PROG / S5 | 未给出 FPGA IO | 用于擦除 FPGA 配置，属于专用按键 |

## 2. 通用按键

手册明确写明：五个通用按键默认低电平，按下时输出高电平。

| 功能 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| 通用按键 0 | PB0 / S0 | R11 |
| 通用按键 1 | PB1 / S1 | R17 |
| 通用按键 2 | PB2 / S2 | R15 |
| 通用按键 3 | PB3 / S3 | V1 |
| 通用按键 4 | PB4 / S4 | U4 |

## 3. 开关输入

手册写明板上有 8 个拨码开关和 1 个 8 位 DIP 开关。PDF 文本抽取时两组都显示为 SW0 到 SW7，因此这里按两组独立资源整理；后续如果要写约束文件，请再对照原理图或 PDF 页面确认最终物理命名。

### 3.1 8 个拨码开关

| 开关 | FPGA 管脚 |
| --- | --- |
| SW0 | R1 |
| SW1 | N4 |
| SW2 | M4 |
| SW3 | R2 |
| SW4 | P2 |
| SW5 | P3 |
| SW6 | P4 |
| SW7 | P5 |

### 3.2 8 位 DIP 开关

| 开关 | FPGA 管脚 |
| --- | --- |
| SW0 | T5 |
| SW1 | T3 |
| SW2 | R3 |
| SW3 | V4 |
| SW4 | V5 |
| SW5 | V2 |
| SW6 | U2 |
| SW7 | U3 |

## 4. LED 指示灯

手册明确写明：LED 在 FPGA 输出高电平时点亮。

| LED | 手册标号 | FPGA 管脚 | 颜色 |
| --- | --- | --- | --- |
| D1_0 | LED1_0 | K3 | Green |
| D1_1 | LED1_1 | M1 | Green |
| D1_2 | LED1_2 | L1 | Green |
| D1_3 | LED1_3 | K6 | Green |
| D1_4 | LED1_4 | J5 | Green |
| D1_5 | LED1_5 | H5 | Green |
| D1_6 | LED1_6 | H6 | Green |
| D1_7 | LED1_7 | K1 | Green |
| D2_0 | LED2_0 | K2 | Green |
| D2_1 | LED2_1 | J2 | Green |
| D2_2 | LED2_2 | J3 | Green |
| D2_3 | LED2_3 | H4 | Green |
| D2_4 | LED2_4 | J4 | Green |
| D2_5 | LED2_5 | G3 | Green |
| D2_6 | LED2_6 | G4 | Green |
| D2_7 | LED2_7 | F6 | Green |

## 5. 七段数码管

手册明确写明：数码管为共阴极数码管。公共极输入低电平，段选端和片选端都需要高电平才会点亮对应位置。也就是说，常用控制信号按有效高处理。

### 5.1 段选引脚

| 段选 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| A0 | CA0 | B4 |
| B0 | CB0 | A4 |
| C0 | CC0 | A3 |
| D0 | CD0 | B1 |
| E0 | CE0 | A1 |
| F0 | CF0 | B3 |
| G0 | CG0 | B2 |
| DP0 | DP0 | D5 |
| A1 | CA1 | D4 |
| B1 | CB1 | E3 |
| C1 | CC1 | D3 |
| D1 | CD1 | F4 |
| E1 | CE1 | F3 |
| F1 | CF1 | E2 |
| G1 | CG1 | D2 |
| DP1 | DP1 | H2 |

### 5.2 位选 / 片选引脚

| 位选 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| DN0_K1 | BIT1 | G2 |
| DN0_K2 | BIT2 | C2 |
| DN0_K3 | BIT3 | C1 |
| DN0_K4 | BIT4 | H1 |
| DN1_K1 | BIT5 | G1 |
| DN1_K2 | BIT6 | F1 |
| DN1_K3 | BIT7 | E1 |
| DN1_K4 | BIT8 | G6 |

## 6. VGA 接口

VGA 接口通过 14 位信号线与 FPGA 连接，红、绿、蓝三个颜色通道各 4 位，另外还有行同步和场同步信号。

| 功能 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| Red 0 | VGA_R0 | F5 |
| Red 1 | VGA_R1 | C6 |
| Red 2 | VGA_R2 | C5 |
| Red 3 | VGA_R3 | B7 |
| Green 0 | VGA_G0 | B6 |
| Green 1 | VGA_G1 | A6 |
| Green 2 | VGA_G2 | A5 |
| Green 3 | VGA_G3 | D8 |
| Blue 0 | VGA_B0 | C7 |
| Blue 1 | VGA_B1 | E6 |
| Blue 2 | VGA_B2 | E5 |
| Blue 3 | VGA_B3 | E7 |
| H-SYNC | VGA_HSYNC | D7 |
| V-SYNC | VGA_VSYNC | C4 |

说明：手册文本只给出了引脚与分辨率位宽，没有明确写出同步信号极性；如果项目需要 VGA 时序，请结合标准 VGA 时序或原理图再确认。

## 7. 串口与 USB-UART/JTAG

手册说明该接口可用于 FPGA 配置和串口通信。UART 帧格式为无校验、1 位停止位。

| 功能 | 手册标号 | FPGA 管脚 | 方向备注 |
| --- | --- | --- | --- |
| UART RX | UART_RX | T4 | FPGA 串口发送端 |
| UART TX | UART_TX | N5 | FPGA 串口接收端 |

## 8. USB 转 PS/2 接口

| 功能 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| PS2_CLK | PS2_CLK | K5 |
| PS2_DATA | PS2_DATA | L4 |

说明：板卡通过 PIC24FJ128 将 USB 键盘鼠标转换为标准 PS/2 协议，手册写明不支持 USB 集线器，只能连接一个鼠标或键盘。

## 9. 音频接口

| 功能 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| 音频 PWM | AUDIO_PWM | T1 |
| 音频 SD | AUDIO_SD# | M6 |

说明：音频输出由低通滤波器驱动，FPGA 侧通常输出 PWM 或 PDM 波形。

## 10. 蓝牙模块

蓝牙模块型号为 BLE-CC41-A，手册写明默认波特率为 9600bps，支持 AT 命令。

| 功能 | 手册标号 | FPGA 管脚 | 方向备注 |
| --- | --- | --- | --- |
| UART_RX | BT_RX | N2 | FPGA 串口发送端 |
| UART_TX | BT_TX | L3 | FPGA 串口接收端 |

## 11. 通用扩展 I/O（J5）

手册说明 J5 提供 32 个双向 IO，并支持过流过压保护。以下为 2x18 连接器的完整 pin 对照。

| 连接器脚位 | 手册标号 | FPGA 管脚 |
| --- | --- | --- |
| 1 | AD2P_15 | B16 |
| 2 | AD2N_15 | B17 |
| 3 | AD10P_15 | A15 |
| 4 | AD10N_15 | A16 |
| 5 | AD3P_15 | A13 |
| 6 | AD3N_15 | A14 |
| 7 | AD11P_15 | B18 |
| 8 | AD11N_15 | A18 |
| 9 | AD9P_15 | F13 |
| 10 | AD9N_15 | F14 |
| 11 | AD8P_15 | B13 |
| 12 | AD8N_15 | B14 |
| 13 | AD0P_15 | D14 |
| 14 | AD0N_15 | C14 |
| 15 | IO_L4P | B11 |
| 16 | IO_L4N | A11 |
| 17 | IO_L11P | E15 |
| 18 | IO_L11N | E16 |
| 19 | IO_L12P | D15 |
| 20 | IO_L12N | C15 |
| 21 | IO_L13P | H16 |
| 22 | IO_L13N | G16 |
| 23 | IO_L14P | F15 |
| 24 | IO_L14N | F16 |
| 25 | IO_L15P | H14 |
| 26 | IO_L15N | G14 |
| 27 | IO_L16P | E17 |
| 28 | IO_L16N | D17 |
| 29 | IO_L17P | K13 |
| 30 | IO_L17N | J13 |
| 31 | IO_L18P | H17 |
| 32 | IO_L18N | G17 |

## 12. 快速结论

- 最常用输入：SYS_CLK、FPGA_RESET、通用按键、拨码开关、DIP 开关。
- 最常用输出：LED、七段数码管、VGA、UART、蓝牙 UART。
- 常见外设通信：PS/2、USB-UART/JTAG、J5 扩展 IO。
- 需要有效电平时，优先记住这三条：按键默认低按下高，LED 高电平点亮，七段数码管片选和段选都按高有效处理。
