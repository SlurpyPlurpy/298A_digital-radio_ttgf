import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_dc_removal_comprehensive(dut):
    """Extensive test for DC removal filter adaptation and convergence."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(100, unit="ns")
    
    # Release reset
    dut.rst_n.value = 1
    await Timer(50, unit="ns")

    async def clock_pulse():
        dut.clk.value = 1
        await Timer(50, unit="ns")
        dut.clk.value = 0
        await Timer(50, unit="ns")

    async def send_sample_and_get_output(sample_val):
        # Pack 14-bit signed sample across pins (ui_in + lower uio_in bits)
        dut.ui_in.value = sample_val & 0xff
        dut.uio_in.value = ((sample_val >> 8) & 0x3f) | 0x40  # DC mode flag
        await clock_pulse()
        
        raw_out = int(dut.uo_out.value)
        # Parse signed 8-bit output window from top-level pins
        return raw_out - 256 if raw_out & 0x80 else raw_out

    # Test 1: Zero input steady state 
    dut._log.info("Testing zero-input baseline...")
    for _ in range(10):
        out = await send_sample_and_get_output(0)
        assert abs(out) <= 2, f"Baseline drifted with zero input: {out}"

    # Test 2: Step DC Bias Convergence 
    dut._log.info("Testing convergence under a constant DC bias (Offset = +4000)...")
    dc_step = 4000
    outputs = []
    
    # Feed constant DC bias for many cycles to let the recursive filter adapt
    for _ in range(150):
        out = await send_sample_and_get_output(dc_step)
        outputs.append(out)

    # Verify that the final output settles close to zero (AC coupled)
    final_settled_value = outputs[-1]
    dut._log.info(f"Initial biased output: {outputs[0]}, Settled output: {final_settled_value}")
    assert abs(final_settled_value) < 15, "DC removal filter failed to adapt and filter out DC offset!"

    dut._log.info("DC removal comprehensive test passed successfully.")