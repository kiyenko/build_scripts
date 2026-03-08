puts "Creating BD wrapper for project $env(PROJECT_NAME)"
set BD_FILE $env(BD_FILE)
set PROJECT_FILE $env(PROJECT_FILE)
set SRC_TOP_FILE $env(SRC_TOP_FILE)

open_project $PROJECT_FILE
make_wrapper -files [get_files [pwd]/$BD_FILE] -top
add_files -norecurse [pwd]/$SRC_TOP_FILE
