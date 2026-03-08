puts "Building project $env(PROJECT_NAME)"
set PROJECT_FILE $env(PROJECT_FILE)
set JOBS $env(JOBS)

open_project $PROJECT_FILE
launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
wait_on_run impl_1

