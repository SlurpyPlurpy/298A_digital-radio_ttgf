import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_nco_comprehensive(dut):
    """Comprehensive test for NCO phase accumulator and sine ROM lookup."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0x20
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    for _ in range(3):
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")

    async def read_nco(tuning_word):
        dut.ui_in.value = tuning_word & 0xff
        dut.uio_in.value = 0x20
        
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")
        
        raw_val = int(dut.uo_out.value)
        return raw_val - 256 if raw_val & 128 else raw_val

    # Test case 1: Zero tuning word
    val_initial = await read_nco(0)
    for _ in range(15):
        val = await read_nco(0)
        assert val == val_initial, "NCO output drifted while tuning word was zero!"

    # Test case 2: Standard frequency step
    waveform = []
    for _ in range(64):
        val = await read_nco(4)
        waveform.append(val)
        assert -127 <= val <= 127, f"NCO output {val} exceeded limits!"

    max_peak = max(waveform)
    min_peak = min(waveform)
    
    assert max_peak >= 110, f"Sine wave positive peak too low: {max_peak}"
    assert min_peak <= -110, f"Sine wave negative peak too high: {min_peak}"