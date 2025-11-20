puts "Exporting project $env(PROJECT_NAME)"
set PROJECT_NAME $env(PROJECT_NAME)

open_project project/project.xpr
write_hw_platform -fixed -include_bit -force -file ./project/TOP_wrapper.xsa
