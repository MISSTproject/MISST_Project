# M.I.S.S.T Project

## Introduction
The Modular Injection System and Sampling Template (M.I.S.S.T) is intended to be used as a SoC fault injector for a bus-based system architecture like most micro-processors today. MISST will be able to run fault campaigns composed of a series of fault injections to a target DUT followed by sampling data from the DUT. After every sampling event, MISST resets the target DUT to repeat the process with a new set of faults. Users can configure MISST fault injection and sampling behavior via a memory mapped interface.

MISST was designed to be as board independent as possible. The MISST system core implements MISST logic and does not change across implementations. The Adapter module changes between implementations across boards and acts as an interface between MISST core and use case hardware.

### Original Implementation

The MISST system was originally developed on a PYNQ-Z1 development board. Details concerning MISST implementation on the PYNQ board is referred to as "original implementation". Further details can be found in the Design Guide.

Source code has been synthesized and simulated with Xilinx Vivado 2017.4 tools. 

## Useful Documents and Links
* User Guide: Contains helpful hints about implementation, possible improves, and how to use various software such as Visio, Xilinx Vivado, and Xilinx SDK.
* Design Guide: Describes MISST implementation, and original implementation.
* [PYNQ-Z1 Documentation and Support Files](https://reference.digilentinc.com/reference/programmable-logic/pynq-z1/start): Contains links to referrence manual and required files for the PYNQ board in Vivado like the constraints file for the board and configuration file for the hard processor.

## Project Status
This is an on going project overseen by Prof. Joseph Callenes-Sloan, and started by Froylan Aguirre in the Spring quarter of 2018. Anyone is welcome to contribute.
