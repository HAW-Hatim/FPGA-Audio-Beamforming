# FPGA-Audio-Beamforming
Project files for digital audio beamforming on FPGA, developed during Digital Systems class at HAW Hamburg in a team of two.

## Repository Structure


# Goal and Idea

# Architecture

# Specification

## Linear Microphone Array

| | |
|---|---|
| Microphones | 5 × digital MEMS (ICS43434, Adafruit ADA6049) |
| Geometry | Linear, 4 cm spacing |
| Target frequency | 4 kHz (speech band, λ ≈ 8.6 cm) |
| Spacing condition | d ≤ λ/2 (no grating lobes) |
| Sampling rate | 50 kHz |
| Beam steering | −90° to +90°, 11 discrete angles with integer-sample delays |

## FFT

| | |
|---|---|
| Type | Radix-2 DIT, Cooley–Tukey |
| Points | 32 |
| Architecture | Parallel-pipelined |
| Word length | 8-bit, fixed-point 1Q7 |
| Frequency resolution | 1.5625 kHz |


## I2S
24-bit audio at 50 kHz over a standard I2S bus (3.2 MHz BCLK, 64-BCLK stereo frames)


# Conclusion and Result
