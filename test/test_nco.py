import cocotb
from cocotb.triggers import Timer
import math

@cocotb.test()
async def test_nco_comprehensive(dut):
    """Comprehensive test for NCO phase accumulator and sine ROM lookup across multiple tuning words."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    await Timer(50, unit="ns")

    async def clock_pulse():
        dut.clk.value = 1
        await Timer(50, unit="ns")
        dut.clk.value = 0
        await Timer(50, unit="ns")

    async def read_nco_output(tuning_word):
        # Set tuning word via ui_in, select NCO observation mode via uio_in bits
        dut.ui_in.value = tuning_word & 0xff
        dut.uio_in.value = 0x20  # Control flag indicating NCO select
        await clock_pulse()
        
        # Convert signed 8-bit output
        raw_val = int(dut.uo_out.value)
        if raw_val & 0x80:
            signed_val = raw_val - 256
        else:
            signed_val = raw_val
        return signed_val

    # Test 1: Zero tuning word 
    dut._log.info("Testing zero tuning word...")
    val_zero = await read_nco_output(0)
    for _ in range(10):
        val = await read_nco_output(0)
        assert val == val_zero, "NCO output drifted while tuning word was zero"

    # Test 2: Slow frequency step 
    dut._log.info("Testing slow step frequency...")
    samples_tw1 = []
    for _ in range(64):  
        val = await read_nco_output(1)
        samples_tw1.append(val)
        # Verify strict amplitude boundaries of our 8-bit signed ROM
        assert -124 <= val <= 124, f"Value {val} exceeded ROM bounds"

    # Verify that it forms a valid wave shape
    max_val = max(samples_tw1)
    min_val = min(samples_tw1)
    assert max_val >= 120 and min_val <= -120, "NCO failed to reach full scale amplitudes"

    # Test 3: Faster frequency step 
    dut._log.info("Testing faster step frequency...")
    samples_tw4 = []
    for _ in range(32):
        val = await read_nco_output(4)
        samples_tw4.append(val)
        assert -124 <= val <= 124

    dut._log.info("NCO verification passed test cases.")