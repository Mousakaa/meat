# Xilinx design constraints (XDC) file for Kria KV Carrier Card - Rev 1

# copied over from Kria_K26_SOM_Rev1.xdc so we only have to add 1 .xdc file
set_property PACKAGE_PIN F10      [get_ports "IIC_1_0_sda_io"] ;# Bank  45 VCCO - som240_1_b13 - IO_L5N_HDGC_45 (som240_1_d17)
set_property PACKAGE_PIN G11      [get_ports "IIC_1_0_scl_io"] ;# Bank  45 VCCO - som240_1_b13 - IO_L5P_HDGC_45 (som240_1_d16)

set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_p[1]"]; # Net name HPA12_P (som240_1_a9)
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_n[1]"]; # Net name HPA12_N (som240_1_a10)
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_p[0]"]; # Net name HPA11_P (som240_1_b10)
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_data_n[0]"]; # Net name HPA11_N (som240_1_b11)
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_clk_p"]; # Net name HPA10_CC_P (som240_1_c12)
set_property IOSTANDARD  MIPI_DPHY_DCI [get_ports "mipi_phy_if_0_clk_n"]; # Net name HPA10_CC_N (som240_1_c13)
set_property IOSTANDARD  LVCMOS33 [get_ports "IIC_1_0_scl_io"]; # Net name HDA00_CC (som240_1_d16)
set_property IOSTANDARD  LVCMOS33 [get_ports "IIC_1_0_sda_io"]; # Net name HDA01 (som240_1_d17)

set_property SLEW SLOW [get_ports "IIC_1_0_scl_io"]; # Net name HDA00_CC
set_property SLEW SLOW [get_ports "IIC_1_0_sda_io"]; # Net name HDA01t

set_property DRIVE 4   [get_ports "IIC_1_0_scl_io"]; # Net name HDA00_CC
set_property DRIVE 4   [get_ports "IIC_1_0_sda_io"]; # Net name HDA01
#
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_clk_n"]; # Net name HPA10_CC_N
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_clk_p"]; # Net name HPA10_CC_P
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_n[0]"]; # Net name HPA11_N
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_p[0]"]; # Net name HPA11_P
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_n[1]"]; # Net name HPA12_N
set_property DIFF_TERM_ADV TERM_100 [get_ports "mipi_phy_if_0_data_p[1]"];  # Net name HPA12_P

# RPI_ENABLE
set_property PACKAGE_PIN F11      [get_ports "rpi_enable"] ;# Bank  45 VCCO - som240_1_b13 - IO_L6N_HDGC_45 (som240_1_a15)
set_property IOSTANDARD  LVCMOS33 [get_ports "rpi_enable"]; # Net name HDA09 (som240_1_a15)
set_property SLEW SLOW            [get_ports "rpi_enable"]; # Net name HDA09 (som240_1_a15)
set_property DRIVE 4              [get_ports "rpi_enable"]; # Net name HDA09
                                                         
# PSU_ENABLE                                             
set_property PACKAGE_PIN J12      [get_ports "psu_enable"]; # som240_1_a16
set_property IOSTANDARD  LVCMOS33 [get_ports "psu_enable"];
set_property SLEW        SLOW     [get_ports "psu_enable"];
set_property DRIVE       4        [get_ports "psu_enable"];
                                                          
# FAN ENABLE                                              
set_property PACKAGE_PIN A12      [get_ports "fan_disable"];
set_property IOSTANDARD  LVCMOS33 [get_ports "fan_disable"];
set_property SLEW        SLOW     [get_ports "fan_disable"];
set_property DRIVE       4        [get_ports "fan_disable"];