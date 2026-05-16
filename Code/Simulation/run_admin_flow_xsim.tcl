set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir .. ..]]
set design_dir [file normalize [file join $repo_root Code Design]]
set sim_dir    [file normalize [file join $repo_root Code Simulation]]
set scratch_dir [file normalize [file join $sim_dir .xsim_tmp]]

file mkdir $scratch_dir
cd $scratch_dir

puts "Compiling admin flow design and simulation sources..."
xvlog -sv -work freshlib \
  "$design_dir/numeric_input_buffer.sv" \
  "$design_dir/data_manager.sv" \
  "$design_dir/auth_engine.sv" \
  "$design_dir/admin_engine.sv" \
  "$design_dir/admin_mode_subsystem.sv" \
  "$design_dir/test_design.v" \
  "$sim_dir/admin_flow_integration_tb.sv"

puts "Elaborating admin_flow_integration_tb..."
xelab -debug typical freshlib.admin_flow_integration_tb -L freshlib -s admin_flow_tb

puts "Running simulation..."
xsim admin_flow_tb -runall
