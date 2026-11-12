import cocotb
from cocotb.triggers import Timer
import numpy as np
import matplotlib.pyplot as plt

@cocotb.test()
async def test_nco_455khz(dut):

    CLK_FREQ = 20_000_000
    CLK_PERIOD = 50
    EXPECTED_FREQ = 455_000
    NUM_SAMPLES = 2000

    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x20

    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    # Capture NCO waveform
    waveform = []

    for _ in range(NUM_SAMPLES):

        dut.clk.value = 1
        await Timer(25, unit="ns")

        raw = int(dut.uo_out.value)
        value = raw - 256 if raw & 128 else raw

        waveform.append(value)

        dut.clk.value = 0
        await Timer(25, unit="ns")

    # Detect positive zero crossings
    crossings = []

    for i in range(1, len(waveform)):
        if waveform[i-1] <= 0 and waveform[i] > 0:
            crossings.append(i)

    assert len(crossings) >= 5, "NCO waveform not detected!"

    # Calculate frequency
    periods = np.diff(crossings)
    avg_period = np.mean(periods)

    measured_freq = CLK_FREQ / avg_period

    assert abs(measured_freq - EXPECTED_FREQ) / EXPECTED_FREQ < 0.02, (
        f"Expected 455 kHz, measured {measured_freq:.2f} Hz"
    )

    # Plot waveform
    time_us = np.arange(NUM_SAMPLES) / CLK_FREQ * 1e6

    plt.figure(figsize=(10, 4))
    plt.plot(time_us, waveform)

    plt.title("NCO Output: 455 kHz")
    plt.xlabel("Time (us)")
    plt.ylabel("Sine Output")
    plt.grid()

    plt.tight_layout()
    plt.savefig("nco_waveform.png")
    plt.close()

    dut._log.info(f"Measured NCO frequency: {measured_freq:.2f} Hz")
    dut._log.info("NCO test PASSED!")
