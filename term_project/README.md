# OMR state change and MG90S bring-up

Open `OMR_state_change/OMR_state_change.xpr` with Vivado 2019.1, or
run the batch build from any writable directory:

```powershell
vivado -mode batch -source <path-to-OMR_state_change>/build_servo.tcl
```

The build creates `OMR_state_change.runs/impl_1/system_wrapper.bit` and
`OMR_state_change.sdk/system_wrapper.hdf` under the Vivado project.

In Xilinx SDK 2019.1, import the HDF as a hardware platform, create an
empty standalone application for `ps7_cortexa9_0` with a fresh BSP, and
add `OMR_state_change.sdk/OMR_state_change_app/src/main.c`. Build the app
and run it on the board with the matching bitstream over JTAG.

| Button | PWM command |
| --- | --- |
| PB0 | 1500 us center |
| PB1 | 1400 us |
| PB2 | 1600 us |
| PB3 | Disable pulses |

AXI GPIO at 0x41210000 accepts pulse width in microseconds. Values from
1000 to 2000 are applied at the next 20 ms frame boundary. All other
values, including the reset default of 0, disable the output.

PWM is routed to J14 pin 14 (FPGA P20, GPIO6). Connect external 5 V to the
servo and share ground with J14 pin 13. Confirm the servo accepts the
board's 3.3 V PWM or use a 5 V AHCT buffer. Test with the flip mechanism
disconnected before calibrating the two positions.
