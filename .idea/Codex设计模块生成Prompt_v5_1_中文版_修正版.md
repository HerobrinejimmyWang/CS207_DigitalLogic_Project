# Codex 设计模块生成 Prompt v5.1（中文修正版）

下面整段 prompt 可直接发给 Codex。

```text
你现在要为 SUSTech CS207 FPGA 饮料售货机项目编写 Verilog/SystemVerilog 设计代码。请严格按照以下最新版 v5 中文设计规则，不要使用旧版本设定。

【项目输入输出总原则】
1. 正式用户输入只使用 4x4 矩阵键盘。
2. 板载 reset 只作为系统复位。
3. 不要实现板载普通按键、拨码开关、DIP 开关作为业务输入。
4. 基础输出必须包含 LED、七段数码管、SALE_WAIT_TAKE 流水灯。
5. VGA 和 audio PWM 是 Bonus 输出，不能替代基础 LED/数码管输出。

【键盘规则】
键盘布局：
[1] [2] [3] [A]
[4] [5] [6] [B]
[7] [8] [9] [C]
[*] [0] [#] [D]

0-9：EV_DIGIT，永远只作为数字输入。
A：EV_PREV，允许时上一项。
D：EV_NEXT，允许时下一项。
B：EV_BACK，允许时返回上一层。
C：EV_HOME，允许时直接回 MAIN_MENU。
*：EV_CLEAR，清空当前输入。
#：EV_CONFIRM，确认；在 SALE_WAIT_TAKE 中表示已取货。

重要：
- 所有数字 ID 选择界面必须“数字选中 + # 确认”，不能按数字直接跳转。
- 0 绝对不能作为退出键。
- B/C 不是强制跳转键，必须由当前子模块判断是否允许，并输出 *_back_req / *_home_req。

【不可中断状态】
1. SALE_DISPENSE：所有键静默忽略，0.5-1 秒后自动进入 SALE_WAIT_TAKE。
2. SALE_WAIT_TAKE：只有 # 表示取货；A/B/C/D/*/0-9 全部静默忽略；5 秒 timeout 触发回收退款。
3. ALARM_MODE：所有键静默忽略；不能返回、不能回主菜单、不能重新输入密码；alarm_done 后自动回 MAIN_MENU。

【普通无效输入】
普通交互页面中无效输入必须显示 INVALID INPUT 1 秒，然后返回原页面。
例外：SALE_DISPENSE、SALE_WAIT_TAKE、ALARM_MODE 中非法键静默忽略，不显示 INVALID INPUT。

【模块边界】
输入模块只把按键转换为抽象事件，不改业务状态。
核心业务只根据事件和数据改变状态，不关心 pin 或 VGA 绘制。
输出模块只读取 ui_snapshot，不修改库存、价格、销售额或 FSM 状态。

data_manager 是唯一数据拥有者，保存 price[0..3]、stock[0..3]、enabled[0..3]、sales_total。
sale_engine/admin_engine 只能通过请求信号修改数据，不能直接写数据寄存器。

【商品初始值】
1 COLA  price=5 stock=5 enabled=1
2 TEA   price=6 stock=5 enabled=1
3 JUICE price=7 stock=5 enabled=1
4 WATER price=3 stock=5 enabled=1

【密码规则】
管理模式前进入 auth_engine。
密码为两位 BCD，默认 42，内部 8'h42。
输入方式：4、2、#。
密码错 1/2 次：显示 WRONG PASSWORD 1 秒后回 AUTH_INPUT。
密码连续错 3 次：触发 alarm_trigger，进入 ALARM_MODE。
ALARM_MODE 不能被任何按键中断，等待 alarm_done 自动回 MAIN_MENU。


【矩阵键盘链路命名要求】
matrix_keypad_scanner 的输出必须命名为：
- scan_key_valid
- scan_key_row
- scan_key_col
key_decoder 的输入必须使用同名端口：
- scan_key_valid
- scan_key_row
- scan_key_col
key_decoder 的输出必须命名为：
- key_valid
- key_code
input_event_router 的输入必须使用同名端口：
- key_valid
- key_code
不要使用与上游输出不一致的 decoder 输入端口名。

【你本次要实现的模块】
请只实现下面指定的一个模块，不要生成其它模块代码，不要生成 XDC。
MODULE_TO_IMPLEMENT = <在这里填模块名，例如 sale_engine>

可选模块名：
reset_sync, tick_gen, matrix_keypad_scanner, key_decoder, input_event_router, numeric_input_buffer,
main_mode_fsm, data_manager, sale_engine, order_timer, auth_engine, admin_engine, error_manager,
ui_snapshot_packer, led_controller, sevenseg_controller, buzzer_controller, audio_pwm_driver,
vga_timing, font_rom, text_renderer, vga_page_renderer, vga_system

【接口要求】
优先使用文档中的模块输入输出变量名。如果你需要新增内部信号可以自由添加，但不要改变模块职责。
所有时序 always 块必须使用非阻塞赋值。
所有组合 always 块必须给默认值，避免 latch。
所有输出请求信号如 *_req、*_done、*_valid 建议为一周期脉冲。
必须包含清晰注释，说明状态机每个状态的含义。

【测试要求】
生成模块后，请同时给一个最小 testbench 或自检建议，覆盖至少：
1. reset 后初始状态；
2. 合法输入路径；
3. 无效输入路径；
4. B/C 在允许与不允许状态中的区别；
5. 如果模块涉及 SALE_WAIT_TAKE 或 ALARM_MODE，必须验证非法键静默忽略。

现在请根据 MODULE_TO_IMPLEMENT 只生成该模块的可综合 Verilog 代码。
```
