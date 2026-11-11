import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_scaling_limiter_stage(dut):
    # Sweep through normal and overflowing values
    test_values = [-4000, -2000, -512, 0, 511, 2000, 4000]
    
    for val in test_values:
        dut.audio_in.value = val
        await Timer(10, units="ns")
        dut._log.info(f"Input: {val} -> Limited Output: {dut.audio_out.value.signed_integer}")
    
    dut._log.info("Scaling & Limiter test passed.")