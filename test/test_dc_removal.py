import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_dc_removal_comprehensive(dut):
    """Comprehensive test for DC removal filter."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x50
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    for _ in range(3):
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")

    async def send_sample(val):
        dut.ui_in.value = val & 0xff
        dut.uio_in.value = 0x50
        
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")
        
        raw = int(dut.uo_out.value)
        return raw - 256 if raw & 128 else raw

    # Test case 1: Zero input test
    for _ in range(20):
        out = await send_sample(0)
        assert -2 <= out <= 2, f"Zero input test failed: expected ~0, got {out}"

    # Test case 2: Constant DC bias step test
    outputs_under_bias = []
    for _ in range(100):
        out = await send_sample(100)
        outputs_under_bias.append(out)

    initial_spike = abs(outputs_under_bias[2])
    settled_value = abs(outputs_under_bias[-1])
    
    assert settled_value < initial_spike, "DC removal filter failed to track DC bias!"
    assert settled_value <= 5, f"DC bias not fully removed: settled at {settled_value}"