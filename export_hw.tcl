puts "Exporting project $env(PROJECT_NAME)"
set PROJECT_NAME $env(PROJECT_NAME)
set XSA_FILE $env(XSA_FILE)

open_project project/$PROJECT_NAME.xpr
write_hw_platform -fixed -include_bit -force -file $XSA_FILE
