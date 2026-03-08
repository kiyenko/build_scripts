puts "Add Project constraints"
set CONSTRAINTS_DIR $env(CONSTRAINTS_DIR)
set PROJECT_FILE $env(PROJECT_FILE)

open_project $PROJECT_FILE
update_compile_order -fileset sources_1
puts "Scan $CONSTRAINTS_DIR for xdc files"
add_files -fileset constrs_1 -scan_for_includes [ glob -nocomplain [pwd]/$CONSTRAINTS_DIR/*.xdc  ]
