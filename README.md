# Multiscale Event Accumulation over Time (MEAT)

This project contains the hardware definition files for the event accumulation module described in [this paper](LINK_TO_THE_PAPER). It is optimized for use with the GenX320 Prophesee event camera on a Kria KV260 FPGA board.

## Scripts

### Create a Standalone MEAT IP

The `create_standalone_ip.tcl` script generates the MEAT module for use in a separate Vivado project. It can be executed with the following command :

```sh
vivado -mode batch -source create_standalone_ip.tcl
```

### Build an Example Project

The `genx320_example.tcl` script builds an example project in the `vivado_project` directory. It can be executed with the following command :

```sh
vivado -source genx320_example.tcl
```

This will open the Vivado GUI and create the design, after which simulation, synthesis and implementation runs can be launched.

### Using the IP in a Pipeline

This event accumulation IP was created to work in tandem with the S3-YOLO detection model hardware accelerator described in the paper mentioned above. To generate the full hardware design, you need to first [generate the FINN accelerator](LINK_TO_S3_YOLO) for S3-YOLO with stitched IP and DCP checkpoint, and then run one of the `s3_yolo_pipeline` scripts with the following command :

```sh
vivado -source s3_yolo_pipeline.tcl -tclargs ABSOLUTE/PATH/TO/FINN/OUTPUTS/stitched_ip/ip
```

This will open the Vivado GUI and create the design, after which simulation, synthesis and implementation runs can be launched.

The `s3_yolo_pipeline.tcl` script will generate a pipeline that allows to read both the accumulated event frames and the inference results, while the `s3_yolo_pipeline_inference_only.tcl` will only allow the inference results to be read without the attached frame (this design can have higher throughput and uses less memory resources, in case the FINN accelerator is too big).

The `s3_yolo_pipeline_color_convert.tcl` script is the same pipeline as `s3_yolo_pipeline.tcl`, with an added `color_convert` hardware module that recolors the accumulated event frame in the FPGA (instead of on the CPU) before it is read out, using the same invocation :

```sh
vivado -source s3_yolo_pipeline_color_convert.tcl -tclargs ABSOLUTE/PATH/TO/FINN/OUTPUTS/stitched_ip/ip
```

## Software Drivers

### Camera Driver

This design can be used for a standalone Vitis application, using the official drivers from Metavision for the GenX320 camera, or with the PYNQ framework, in which case a custom driver for the camera can be found [here](https://gitlab.imt-atlantique.fr/a24gauda/genx320_pynq), along with an example application using the above `genx320_example` design.

### S3-YOLO Pipeline Driver

For the S3-YOLO hardware implementations, a specialized driver relying on the GenX320 driver mentioned above can be found [here](https://gitlab.imt-atlantique.fr/a24gauda/s3_yolo_driver).
