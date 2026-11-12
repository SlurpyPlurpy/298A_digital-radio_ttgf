import cocotb
from cocotb.triggers import Timer
import numpy as np
import matplotlib
matplotlib.use("Agg")  # Save plots without a display, including in CI.
import matplotlib.pyplot as plt

@cocotb.test()
async def test_mixer_455khz(dut):

    CLK_FREQ = 1_000_000
    CLK_PERIOD = 1000

    IF_FREQ = 455_000
    AUDIO_FREQ = 1_000

    AMPLITUDE = 70
    MODULATION_INDEX = 0.7

    NUM_SAMPLES = 2000

    # Initialize DUT
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1

    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")

    dut.rst_n.value = 1

    # Generate AM input and capture mixer output
    input_waveform = []
    mixer_waveform = []

    for n in range(NUM_SAMPLES):

        t = n / CLK_FREQ

        # Generate AM modulated 455 kHz signal
        envelope = (
            1 + MODULATION_INDEX *
            np.cos(2 * np.pi * AUDIO_FREQ * t)
        )

        carrier = np.sin(2 * np.pi * IF_FREQ * t)  # Match the NCO reset phase.

        input_signal = AMPLITUDE * envelope * carrier

        input_sample = int(np.clip(
            round(input_signal), -128, 127
        ))

        input_waveform.append(input_sample)

        # Apply input to mixer
        dut.ui_in.value = input_sample & 0xFF

        # Capture before the rising edge: the NCO still represents sample n.
        # Reading after the edge would pair this input with the next NCO sample.
        await Timer(CLK_PERIOD // 2, unit="ns")
        reference = int(dut.user_project.sine_reference.value)
        if reference & 0x80:
            reference -= 256

        raw = int(dut.user_project.mixer_sample.value)
        mixer_value = raw - 65536 if raw & 0x8000 else raw
        assert mixer_value == input_sample * reference, (
            f"Sample {n}: got {mixer_value}, expected {input_sample * reference}"
        )
        mixer_waveform.append(mixer_value)

        # Advance the FIR and NCO to the next sample.
        dut.clk.value = 1
        await Timer(CLK_PERIOD // 2, unit="ns")
        dut.clk.value = 0

    # Check mixer output is not constant
    assert max(mixer_waveform) > min(mixer_waveform), \
        "Mixer output is constant!"

    # Plot input and mixer output
    time_us = np.arange(NUM_SAMPLES) / CLK_FREQ * 1e6

    fig, axes = plt.subplots(2, 1, figsize=(12, 8))

    axes[0].plot(time_us, input_waveform)
    axes[0].set_title("AM Input - 455 kHz")
    axes[0].set_ylabel("Amplitude")
    axes[0].grid()

    axes[1].plot(time_us, mixer_waveform)
    axes[1].set_title("Mixer Output - 455 kHz Downconversion")
    axes[1].set_xlabel("Time (us)")
    axes[1].set_ylabel("Amplitude (signed 16-bit product)")
    axes[1].grid()

    plt.tight_layout()
    plt.savefig("mixer_455khz.png")
    plt.close()

    dut._log.info(
        f"Mixer maximum: {max(mixer_waveform)}"
    )

    dut._log.info(
        f"Mixer minimum: {min(mixer_waveform)}"
    )

    dut._log.info("Mixer test passed")
