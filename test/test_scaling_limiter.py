import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_scaling_limiter_comprehensive(dut):
    """RTL-only: scaling and clipping of the actual DC-removal output."""
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    async def evaluate_limiter(val_in):
        dut.clk.value = 0
        dut.ui_in.value = val_in & 0xff
        await Timer(500, unit="ns")
        dut.clk.value = 1
        await Timer(500, unit="ns")
        audio = int(dut.user_project.dc_removed_audio.value)
        if audio & 8192:
            audio -= 16384
        raw = int(dut.user_project.limited_audio.value)
        actual = raw - 1024 if raw & 512 else raw
        expected = max(-512, min(511, audio // 4))
        assert actual == expected, f"Limiter: got {actual}, expected {expected}"
        return actual

    # Test case 1: Normal range pass-through.
    assert await evaluate_limiter(0) == 0
    for _ in range(40):
        await evaluate_limiter(50)

    # Test case 2: Strong aligned/opposite-sign carriers exercise both limits.
    observed = set()
    for sign in [1, -1]:
        for _ in range(200):
            reference = int(dut.user_project.sine_reference.value)
            if reference & 128:
                reference -= 256
            observed.add(await evaluate_limiter(sign * reference))
    assert 511 in observed, "Positive clipping was not exercised"
    assert -512 in observed, "Negative clipping was not exercised"
