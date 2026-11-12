import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_dc_removal_comprehensive(dut):
    """RTL-only: average tracking using the actual FIR output as input."""
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    avg = 0
    def wrap25(value):
        # Match the original 25-bit arithmetic; overflow is not corrected here.
        return (value + (1 << 24)) % (1 << 25) - (1 << 24)

    async def send_sample(val):
        nonlocal avg
        dut.clk.value = 0
        dut.ui_in.value = val & 0xff
        await Timer(500, unit="ns")
        fir = int(dut.user_project.fir_sum.value)
        if fir & 8192:
            fir -= 16384
        avg = wrap25(avg + (wrap25((fir << 11) - avg) // 512))
        dut.clk.value = 1
        await Timer(500, unit="ns")
        # Both the FIR and average have updated; audio_out is combinational.
        fir = int(dut.user_project.fir_sum.value)
        if fir & 8192:
            fir -= 16384
        raw = int(dut.user_project.dc_removed_audio.value)
        out = raw - 16384 if raw & 8192 else raw
        assert out == wrap25((fir << 11) - avg) // 2048
        return out

    # Test case 1: Zero input test.
    for _ in range(20):
        assert await send_sample(0) == 0

    # Test case 2: A phase-aligned carrier produces a DC component after mixing.
    # Constant ADC values would instead be multiplied by the oscillating NCO.
    outputs_under_bias = []
    for _ in range(4000):
        reference = int(dut.user_project.sine_reference.value)
        if reference & 128:
            reference -= 256
        outputs_under_bias.append(await send_sample(reference))
    initial_level = sum(abs(v) for v in outputs_under_bias[30:100]) / 70
    settled_level = sum(abs(v) for v in outputs_under_bias[-200:]) / 200
    # Residual mixer ripple is expected; require strong removal of the average.
    assert initial_level > 100
    assert settled_level < initial_level / 10

    # Reset must clear the average immediately, without a clock edge.
    dut.clk.value = 0
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    assert int(dut.user_project.u_dc_rem.avg_reg.value) == 0
    assert int(dut.user_project.dc_removed_audio.value) == 0
