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

    positive_clipping = False
    negative_clipping = False

    async def evaluate_limiter(val_in):
        nonlocal positive_clipping, negative_clipping
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
        scaled = audio // 4
        positive_clipping |= scaled > 511
        negative_clipping |= scaled < -512
        expected = max(-512, min(511, scaled))
        assert actual == expected, f"Limiter: got {actual}, expected {expected}"
        return actual

    # Test case 1: Normal range pass-through.
    assert await evaluate_limiter(0) == 0
    for _ in range(40):
        await evaluate_limiter(50)

    # Test case 2: Aligned/opposite-sign sine carriers check realistic inputs.
    observed = set()
    for sign in [1, -1]:
        for _ in range(200):
            reference = int(dut.user_project.sine_reference.value)
            if reference & 128:
                reference -= 256
            observed.add(await evaluate_limiter(sign * reference))
    # Test case 3: Full-scale square carriers stress both clipping branches.
    # The extra FIR shift lowers gain, so the sine stimulus above alone no
    # longer guarantees positive clipping. All ADC inputs remain in range.
    for sign in [1, -1]:
        for _ in range(200):
            reference = int(dut.user_project.sine_reference.value)
            if reference & 128:
                reference -= 256
            carrier = 127 if reference >= 0 else -127
            observed.add(await evaluate_limiter(sign * carrier))
    assert positive_clipping, "Positive clipping branch was not exercised"
    assert negative_clipping, "Negative clipping branch was not exercised"
    assert 511 in observed, "Positive clipping was not exercised"
    assert -512 in observed, "Negative clipping was not exercised"
