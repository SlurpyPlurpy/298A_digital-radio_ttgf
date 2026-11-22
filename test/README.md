# Digital radio verification

The design runs at 1 MHz (1,000 ns per clock), with two 11-sample FIR stages,
5/4 truncation, one FIR input register, eleven DC fractional bits, and a
limiter that divides by four. Keep the reference models aligned with any
future intentional changes to these choices.

## RTL tests

Run `make` in this directory. This simulates the Verilog source. Six module
tests inspect internal signals; `test_radio` additionally checks the complete
radio using only its external pins. The FIR model includes its input pipeline.

## Gate-level tests

Tiny Tapeout's `gl_test` job automatically runs `GATES=yes make`. The Makefile
then selects only `test_radio`: synthesized circuits can flatten or rename
the internal modules/signals used by the RTL tests. No workflow edits or
manual switching are required. The gate-level test is not skipped.

To run locally, install the matching GF180 PDK, set PDK_ROOT, and place the
generated powered submission netlist at `test/gate_level_netlist.v`. Then run
`make GATES=yes`. The CI action supplies the PDK and netlist automatically.

## External-output reference

`radio_model.py` independently calculates the fixed NCO table, mixer, direct
11-sample window sums, fixed-width DC tracking, limiter and buffered PWM.
`test_radio.py` compares every settled output sample against that model at
1 MHz. It covers silence, extreme/random ADC values, AM signals at 10% and
50% modulation, both limiter bounds, unused pins, and repeated resets.
It never reads internal DUT signals. The same test also runs on RTL.

This functional simulation does not replace routed static timing analysis
or audio-quality measurements. Existing NCO/mixer tests save waveform PNGs;
the testbench saves an FST waveform for GTKWave or Surfer.
