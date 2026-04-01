# Multiscale Event Accumulation over Time (MEAT)

This project contains the hardware definition files for the event accumulation module described in [this paper](). It is optimized for use with the GenX320 Prophesee event camera on a Kria KV260 FPGA board.

## Scripts

### Create a standalone MEAT IP

The `create_standalone_ip.tcl` script generates the MEAT module for use in a separate Vivado project. It can be executed with the following command :

```sh
vivado -mode batch -source create_standalone_ip.tcl
```

### Build an example project

The `genx320_example.tcl` script builds an example project in the `vivado_project` directory. It can be executed with the following command :

```sh
vivado -source genx320_example.tcl
```

This will open the Vivado GUI and create the design, after which simulation, synthesis and implementation runs can be launched.
