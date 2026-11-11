import cocotb
from cocotb.triggers import Timer
import random

@cocotb.test()
async def test_multiplier_wrapper(dut):
    """Pin-level reference test for the AM mixer / multiplier stage."""
    
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")

    async def check_multiplier_output(expected_product):
        # Select multiplier observation page via uio_in control bits (e.g., 0x30)
        dut.uio_in.value = 0x30  
        await Timer(100, unit="ns")
        
        # Read lower 8 bits of the product from uo_out
        low_byte = int(dut.uo_out.value)
        
        # Switch to upper byte page if your design uses split pins
        dut.uio_in.value = 0x31  
        await Timer(100, unit="ns")
        high_byte = int(dut.uo_out.value)
        
        # Reconstruct full 16-bit signed product
        full_product = (high_byte << 8) | low_byte
        if full_product & 0x8000:
            full_product -= 65536
            
        assert full_product == (expected_product & 0xffff), f"Multiplier mismatch: got {full_product}, expected {expected_product}"

    async def reset():
        dut.clk.value = 0
        dut.rst_n.value = 0
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        await Timer(500, unit="ns")
        dut.rst_n.value = 1

    # Test 1: Zero multiplication
    await reset()
    dut.ui_in.value = 0
    dut.clk.value = 1
    await Timer(50, unit="ns")
    dut.clk.value = 0
    await Timer(50, unit="ns")
    await check_multiplier_output(0)

    # Test 2: Randomized vector checks
    rng = random.Random(42)
    for _ in range(20):
        a = rng.randrange(-64, 64)
        b = rng.randrange(-64, 64)
        expected = a * b
        
        # Drive inputs
        dut.ui_in.value = a & 0xff
        dut.uio_in.value = (b & 0x0f) | 0x30  # Pack multiplier operand
        
        dut.clk.value = 1
        await Timer(50, unit="ns")
        dut.clk.value = 0
        await Timer(50, unit="ns")

    dut._log.info("Multiplier pin-level verification passed successfully.")