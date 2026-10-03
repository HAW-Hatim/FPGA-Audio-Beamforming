# FPGA-Audio-Beamforming
Project files for real-time digital audio beamforming on FPGA Basys 3 board, developed during Digital Systems class at HAW Hamburg in a team of two.

## Repository Structure
```
.
├── Blockdiagrams/     Block diagrams for all VHDL modules
├── Constraints/       Basys 3 pin constraints (.xdc)
├── Results/           Beamformed audio, array setup photos, VGA spectrum
├── Scripts/           Python/Matlab scripts for twiddle factors and delay tables
├── Simulation/        Testbenches for simulation
├── Sources/           VHDL source files
├── LICENSE
└── README.md
```

---


# Goal
Our goal was to implement and verify delay-and-sum (DAS) beamforming for audio signals picked up by a self-made linear microphone array. We defined success as: signals from the intended direction measurably amplified (or at least less attenuated) compared to other directions, verified either aurally or through the FFT spectrum.
The workload was split into two parts:
- I2S transceiver and VGA display
- DAS algorithm and FFT


# Architecture

 ## Top_Beamformer_Analysis

 
 ### FFT_TOP
 - Parallelisation of incoming summed audio from Top_Beamformer
 - Performing FFT
 - Output magnitude spectrum

 ### VGA_TOP
 - Live display of magnitude spectrum


 ## Top_Beamformer
 
 ### clk_wiz_I2S
 
 ### i2s_top_5mic
 
 ### delay_and_sum
 
 ### Angle_To_Delay
 - Switch position
 ### Seven_segment_display
- Display the angle (-90° to 90°) that was entered 
 

 
# Specification

## Linear Microphone Array

| | |
|---|---|
| **Microphones** | 5 × digital MEMS (ICS43434, Adafruit ADA6049) |
| **Geometry** | Linear, 4 cm spacing |
| **Target frequency** | 4 kHz (speech band, λ ≈ 8.6 cm) |
| **Spacing condition** | d ≤ λ/2 (no grating lobes) |
| **Sampling rate** | 50 kHz |
| **Beam steering** | −90° to +90°, 11 discrete angles with integer-sample delays |

<p align="center">
  <img src="Results/Setup.jpg" alt="Linear mic array" width="45%">
</p>

## FFT

| | |
|---|---|
| **Type** | Radix-2 DIT, Cooley–Tukey |
| **Points** | 32 |
| **Architecture** | Parallel-pipelined |
| **Word length** | 8-bit, fixed-point 1Q7 |
| **Frequency resolution** | 1.5625 kHz |


## I2S
24-bit audio at 50 kHz over a standard I2S bus (3.2 MHz BCLK, 64-BCLK stereo frames)


# Conclusion and Result

To sum up, we successfully implemented the delay-and-sum algorithm for audio beamforming. We also added visual and aural verification on the FPGA, confirming that the beamformer works. The results are shown below.

The first image shows the FFT spectrum rendered on the VGA display. The second shows the measured audio amplitude when the beamforming angle was switched from 90° to −90°, demonstrating the directional response of the array.

<p align="center">
  <img src="Results/fft_spectrum.jpg" alt="FFT spectrum on VGA display" width="45%">
  <img src="Results/1khz_90deg_to_minus90deg.jpg" alt="Beamforming amplitude measurement" width="45%">
</p>

Despite achieving a usable audio beamforming platform, several aspects can be improved.

The FFT works and is usable for verification, but it is far from optimal. The fully parallel-pipelined architecture is well suited to high-data-rate applications and was chosen for its simplicity of implementation, but it consumes a large amount of FPGA resources. Our application does not need those data rates — it is limited by a slow source (I2S receiver, f_s = 50 kHz) and a slow consumer (VGA monitor, 60 fps). A possible improvement is an in-place butterfly calculation, which would reduce resource usage at the cost of longer computation time.

Other improvements we considered include comparing our implementation against the Vivado FFT IP block, streaming FFT results to a PC over USB for deeper analysis, and adding a waterfall plot to the VGA display.
