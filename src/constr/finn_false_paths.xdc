# FINN XPM CDC false-path constraints (project-level override)
# Replaces finn_design.xdc current_instance scoping that crashes Vivado
# (SIGSEGV in readXDCForRefNameScoppedCells when resolving scoped paths)
set_false_path -to [get_cells -hierarchical -regexp {.*xpm_cdc_sync_rst.*syncstages_ff_reg\[0\]}]
