set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize [file join $script_dir .. ..]]
set design_dir [file normalize [file join $repo_root Code Design]]
set sim_dir    [file normalize [file join $repo_root Code Simulation]]
set scratch_dir [file normalize [file join $sim_dir .xsim_tmp]]

file mkdir $scratch_dir
cd $scratch_dir

puts "Compiling admin flow design and simulation sources..."
exec xvlog -sv -work freshlib \
  "$design_dir/numeric_input_buffer.v" \
  "$design_dir/data_manager.v" \
  "$design_dir/auth_engine.v" \
  "$design_dir/admin_engine.v" \
  "$design_dir/admin_mode_subsystem.v" \
  "$sim_dir/admin_flow_integration_tb.v"

puts "Elaborating admin_flow_integration_tb..."
exec xelab -debug typical freshlib.admin_flow_integration_tb -L freshlib -s admin_flow_tb

puts "Running simulation..."
exec xsim admin_flow_tb -runall
