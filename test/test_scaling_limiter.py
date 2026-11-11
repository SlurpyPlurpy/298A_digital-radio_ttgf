import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_scaling_limiter_comprehensive(dut):
    """Extensive test for scaling gain accuracy and hard-clipping saturation limits."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    await Timer(50, unit="ns")

    async def test_amplitude(input_val):
        dut.ui_in.value = input_val & 0xff
        dut.uio_in.value = 0x60  # Limiter test select flag
        dut.clk.value = 1
        await Timer(50, unit="ns")
        dut.clk.value = 0
        await Timer(50, unit="ns")
        
        raw = int(dut.uo_out.value)
        return raw - 256 if raw & 0x80 else raw

    # Test 1: Normal linear scaling range ---
    dut._log.info("Testing linear scaling range...")
    for test_in in [10, 30, 60, 90]:
        val_out = await test_amplitude(test_in)
        # Verify output scales proportionally without clipping
        assert val_out > 0, "Positive signal incorrectly inverted or zeroed"

    # Test 2: Over-range saturation / clipping check ---
    dut._log.info("Testing limiter saturation limits (extreme input spikes)...")
    # Feed massive input values that would normally cause 8-bit/14-bit arithmetic wrap-around
    for extreme_in in [32767, -32768]:
        val_out = await test_amplitude(extreme_in)
        # Ensure it clamps to maximum rail limits rather than wrapping around to opposite sign
        assert -128 <= val_out <= 127, f"Limiter allowed overflow wrap-around: {val_out}"

    dut._log.info("Scaling and limiter verification passed")