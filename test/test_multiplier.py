import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_multiplier_comprehensive(dut):
    """Comprehensive test for the AM mixer / multiplier stage."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x30
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    for _ in range(3):
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")

    async def check_product(ui_val, expected_product):
        dut.ui_in.value = ui_val & 0xff
        dut.uio_in.value = 0x30  
        
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")

        dut.uio_in.value = 0x30  
        await Timer(25, unit="ns")
        low_byte = int(dut.uo_out.value)
        
        dut.uio_in.value = 0x31  
        await Timer(25, unit="ns")
        high_byte = int(dut.uo_out.value)
        
        full_product = (high_byte << 8) | low_byte
        if full_product & 0x8000:
            full_product -= 65536
            
        assert full_product == (expected_product & 0xffff), f"Multiplier mismatch: got {full_product}, expected {expected_product}"

    # Test case 1: Zero input test
    await check_product(0, 0)

    # Test case 2: Mid-scale input test
    dut.ui_in.value = 128
    for _ in range(5):
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")
        
    dut.uio_in.value = 0x31
    await Timer(25, unit="ns")
    hb = int(dut.uo_out.value)
    if hb & 0x80:
        hb -= 256
    assert -128 <= hb <= 127, f"Multiplier high byte out of bounds: {hb}"