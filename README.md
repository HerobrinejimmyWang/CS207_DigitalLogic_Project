# Vending_machine Project

**Notice:**
当前 admin_mode_subsystem.sv (line 1) 假设外部会提供互斥的 auth_mode_en 和 admin_mode_en，也就是它负责共享缓冲和模块集成，但不在内部自动把 auth_ok 直接升级成 ADMIN_MODE。这和后面接 main_mode_fsm 的方式要先对齐。