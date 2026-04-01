
################################################################
# This is a generated script based on design: MEAT
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following command from Vivado Tcl console:
# 	source create_standalone_ip.tcl
# Or start Vivado with :
# 	vivado -source create_standalone_ip.tcl

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project MEAT vivado_project -part xck26-sfvc784-2LV-c
   set_property BOARD_PART xilinx.com:kv260_som:part0:1.4 [current_project]
}

# ADD SOURCE FILES
add_files [glob ./src/*.vhd]
add_files -fileset sim_1 [glob ./src/sim/*.vhd]
add_files -fileset constrs_1 ./src/constr/kv260_direct.xdc

# Set all VHDL files to VHDL 2008 except for the one used in the BD
set_property file_type {VHDL 2008} [get_files -regexp ".*(?<!TOP)\.vhd"]

# Set testbench as top
set_property top tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

set bCheckIPsPassed 1

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
MEAT_5_OUTS_TOP\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

##################################################################
# PACKAGE IP
##################################################################

ipx::package_project -root_dir . -vendor imt-atlantique.fr -library user -taxonomy /UserIP

set_property name MEAT [ipx::current_core]
set_property display_name MEAT [ipx::current_core]
set_property description {Multiscale Event Accumulation over Time} [ipx::current_core]
set_property vendor imt-atlantique.fr [ipx::current_core]

set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]

ipx::save_core [ipx::current_core]
ipx::check_integrity -quiet -xrt [ipx::current_core]
ipx::archive_core ./MEAT_1.0.zip [ipx::current_core]
ipx::unload_core component_1
