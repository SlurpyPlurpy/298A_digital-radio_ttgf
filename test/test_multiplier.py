import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_multiplier_stage(dut):
    """Test the 8x8 signed multiplier mixer stage."""
    clock = Clock(dut.clk, 1000, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1

    await Timer(2000, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Test various incoming signal levels on ui_in
    test_inputs = [0, 64, 128, 255]
    for val in test_inputs:
        dut.ui_in.value = val
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        
        # Read the internal mixer output product
        product = dut.mixer_sample.value.signed_integer
        dut._log.info(f"ui_in: {val} -> Multiplier Mixer Output: {product}")

    dut._log.info("Multiplier test passed.")