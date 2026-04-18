## EGO1 board constraints for the vending machine demo.
## Source: EGO1_Pinout_Reference.md / Ego1_UserManual_v2.2.pdf
##
## Mapping used by this design:
## - clk           -> SYS_CLK (100 MHz)
## - rst_n         -> FPGA_RESET
## - btn_coin_1    -> PB0
## - btn_coin_2    -> PB1
## - btn_coin_5    -> PB2
## - btn_confirm   -> PB3
## - btn_cancel    -> PB4
## - btn_sel[1:0]  -> slide switch group SW0/SW1 (R1/N4)
## - led[7:0]      -> LED1_0 .. LED1_7
## - seg/an/dp     -> first 4 digits of the onboard 8-digit 7-segment display
##
## Notes:
## - Push buttons are documented as idle-low, pressed-high.
## - LEDs are active high.
## - 7-segment segment and digit-enable signals are active high on EGO1.
## - Confirm reset polarity on your board. The RTL expects rst_n to be active low.

set_property IOSTANDARD LVCMOS33 [get_ports {clk rst_n btn_coin_1 btn_coin_2 btn_coin_5 btn_confirm btn_cancel}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_sel[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*] an[*] dp led[*]}]

## Clock and reset
set_property PACKAGE_PIN P17 [get_ports clk]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]
set_property PACKAGE_PIN P15 [get_ports rst_n]

## General purpose buttons
set_property PACKAGE_PIN R11 [get_ports btn_coin_1]
set_property PACKAGE_PIN R17 [get_ports btn_coin_2]
set_property PACKAGE_PIN R15 [get_ports btn_coin_5]
set_property PACKAGE_PIN V1  [get_ports btn_confirm]
set_property PACKAGE_PIN U4  [get_ports btn_cancel]

## Slide switches (first switch bank)
set_property PACKAGE_PIN R1 [get_ports {btn_sel[0]}]
set_property PACKAGE_PIN N4 [get_ports {btn_sel[1]}]

## 7-segment segments for digit bank 0
set_property PACKAGE_PIN B4 [get_ports {seg[0]}]
set_property PACKAGE_PIN A4 [get_ports {seg[1]}]
set_property PACKAGE_PIN A3 [get_ports {seg[2]}]
set_property PACKAGE_PIN B1 [get_ports {seg[3]}]
set_property PACKAGE_PIN A1 [get_ports {seg[4]}]
set_property PACKAGE_PIN B3 [get_ports {seg[5]}]
set_property PACKAGE_PIN B2 [get_ports {seg[6]}]
set_property PACKAGE_PIN D5 [get_ports dp]

## First 4 digits
set_property PACKAGE_PIN G2 [get_ports {an[0]}]
set_property PACKAGE_PIN C2 [get_ports {an[1]}]
set_property PACKAGE_PIN C1 [get_ports {an[2]}]
set_property PACKAGE_PIN H1 [get_ports {an[3]}]

## LED1 bank
set_property PACKAGE_PIN K3 [get_ports {led[0]}]
set_property PACKAGE_PIN M1 [get_ports {led[1]}]
set_property PACKAGE_PIN L1 [get_ports {led[2]}]
set_property PACKAGE_PIN K6 [get_ports {led[3]}]
set_property PACKAGE_PIN J5 [get_ports {led[4]}]
set_property PACKAGE_PIN H5 [get_ports {led[5]}]
set_property PACKAGE_PIN H6 [get_ports {led[6]}]
set_property PACKAGE_PIN K1 [get_ports {led[7]}]
