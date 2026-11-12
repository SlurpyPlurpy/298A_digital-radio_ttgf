import cocotb
from cocotb.triggers import Timer
import numpy as np
import matplotlib.pyplot as plt

@cocotb.test()
async def test_mixer_455khz(dut):

    CLK_FREQ = 20_000_000
    CLK_PERIOD = 50

    IF_FREQ = 455_000
    AUDIO_FREQ = 1_000

    AMPLITUDE = 70
    MODULATION_INDEX = 0.7

    NUM_SAMPLES = 2000

    # Initialize DUT
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1

    dut.ui_in.value = 0
    dut.uio_in.value = 0x30

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

        carrier = np.cos(2 * np.pi * IF_FREQ * t)

        input_signal = AMPLITUDE * envelope * carrier

        input_sample = int(np.clip(
            round(input_signal), -128, 127
        ))

        input_waveform.append(input_sample)

        # Apply input to mixer
        dut.ui_in.value = input_sample & 0xFF

        # Rising edge
        dut.clk.value = 1
        await Timer(CLK_PERIOD // 2, unit="ns")

        raw = int(dut.uo_out.value)

        # Mixer low byte is selected by uio_in[0] = 0
        mixer_value = raw - 256 if raw & 0x80 else raw

        mixer_waveform.append(mixer_value)

        # Falling edge
        dut.clk.value = 0
        await Timer(CLK_PERIOD // 2, unit="ns")

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
    axes[1].set_ylabel("Amplitude (low byte)")
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
