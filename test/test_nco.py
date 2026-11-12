import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_nco_comprehensive(dut):
    """RTL-only: fixed 455 kHz NCO, independent of the ADC sample input."""
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    async def read_nco(sample):
        dut.ui_in.value = sample & 0xff
        dut.clk.value = 0
        await Timer(500, unit="ns")
        dut.clk.value = 1
        await Timer(500, unit="ns")
        raw_val = int(dut.user_project.sine_reference.value)
        return raw_val - 256 if raw_val & 128 else raw_val

    # Test case 1: Fixed phase step, including when the ADC input changes.
    # This replaces the old externally selectable/zero tuning-word checks.
    phase = 0
    positive = [0,12,25,37,49,60,71,81,90,98,103,109,113,117,120,123,
                124,123,120,117,113,109,103,98,90,81,71,60,49,37,25,12]
    sine = positive + [-v for v in positive]
    waveform = []
    for i in range(4096):
        val = await read_nco(i & 0xff)
        phase = (phase + 7633633) & 0xffffff
        assert int(dut.user_project.u_nco.phase_acc.value) == phase
        assert val == sine[phase >> 18]
        waveform.append(val)
        assert -127 <= val <= 127, f"Sine wave out of range: {val}"

    # Test case 2: Both waveform peaks are reached.
    assert max(waveform) >= 110
    assert min(waveform) <= -110
