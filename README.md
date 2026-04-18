# Verilog Vending Machine

这是一个基于 `Verilog + Vivado + Artix-7` 的教学演示版自动售货机工程。

当前实现包含：

- 4 种商品，价格固定为 `3/5/7/9`
- 按键模拟投币 `1/2/5`
- `btn_sel[1:0]` 选择商品
- `btn_confirm` 发起购买
- `btn_cancel` 取消并退款
- 数码管显示 `状态码 / 商品号 / 金额`
- LED 显示 `库存和状态`

## 目录结构

- `src/`: RTL 源码
- `tb/`: 仿真 testbench
- `vivado/`: Vivado TCL 与 XDC 模板

## 数码管显示约定

4 位数码管从高位到低位显示：

- 第 4 位：状态码
- 第 3 位：商品编号
- 第 2 位：金额十位
- 第 1 位：金额个位

状态码定义：

- `0`: 正常
- `1`: 金额不足或退款中
- `2`: 缺货
- `3`: 出货成功/找零显示

## LED 约定

- `led[3:0]`: 当前选中商品库存
- `led[4]`: 出货成功状态
- `led[5]`: 缺货
- `led[6]`: 金额不足/取消
- `led[7]`: `dispense_pulse`

## 运行仿真

```bash
make sim
```

如果本机已安装 `iverilog`，命令会编译所有 `src/*.v` 和 `tb/vending_top_tb.v`，然后执行 testbench。

## Vivado 使用

1. 打开 Vivado Tcl Console
2. 切到工程根目录
3. 执行：

```tcl
source vivado/create_project.tcl
```

4. 默认会加载 EGO1 约束文件 [ego1_vending_machine.xdc](/Users/a123/Documents/verilog_vending_machine/vivado/ego1_vending_machine.xdc:1)
5. 重点确认 `rst_n` 在你板上的实际极性是否与 RTL 一致
6. 运行 Synthesis / Implementation / Generate Bitstream

## 注意事项

- 已提供 EGO1 板专用 `.xdc`
- 芯片型号使用 `xc7a35tcsg324-1`
- 当前实现按 EGO1 手册将数码管和 LED 作为高电平有效处理
- 项目仍保留 [vending_machine_template.xdc](/Users/a123/Documents/verilog_vending_machine/vivado/vending_machine_template.xdc:1) 作为通用模板
