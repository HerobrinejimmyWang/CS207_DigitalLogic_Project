set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir .. ..]]
set design_dir [file normalize [file join $repo_root Code Design]]
set sim_dir    [file normalize [file join $repo_root Code Simulation]]
set scratch_dir [file normalize [file join $sim_dir .xsim_keypad_tmp]]
if {![info exists sim_lib]} {
  set sim_lib freshlib
}

file mkdir $scratch_dir
cd $scratch_dir

puts "Compiling keypad admin flow design and simulation sources into library '$sim_lib'..."
exec xvlog -sv -work $sim_lib \
  "$design_dir/input_event_router.v" \
  "$design_dir/key_decoder.v" \
  "$design_dir/matrix_keypad_scanner.v" \
  "$design_dir/keypad_event_frontend.v" \
  "$design_dir/numeric_input_buffer.v" \
  "$design_dir/data_manager.v" \
  "$design_dir/auth_engine.v" \
  "$design_dir/admin_engine.v" \
  "$design_dir/admin_mode_subsystem.v" \
  "$sim_dir/keypad_admin_flow_integration_tb.v"

puts "Elaborating keypad_admin_flow_integration_tb..."
exec xelab -debug typical $sim_lib.keypad_admin_flow_integration_tb -L $sim_lib -s keypad_admin_flow_tb

puts "Running simulation..."
exec xsim keypad_admin_flow_tb -runall
