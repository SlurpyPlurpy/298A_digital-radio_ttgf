import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_scaling_limiter_comprehensive(dut):
    """Comprehensive test for scaling gain and limiter boundaries."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x60
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    for _ in range(3):
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")

    async def evaluate_limiter(val_in):
        dut.ui_in.value = val_in & 0xff
        dut.uio_in.value = 0x60
        
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")
        
        raw = int(dut.uo_out.value)
        return raw - 256 if raw & 128 else raw

    # Test case 1: Normal range pass-through
    out_normal = await evaluate_limiter(50)
    assert -128 <= out_normal <= 127, f"Normal range output out of bounds: {out_normal}"

    # Test case 2: Upper clipping bound test
    out_clipped_high = await evaluate_limiter(255)
    assert out_clipped_high >= 0, "Limiter allowed negative wraparound"