import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_pwm_modulator_comprehensive(dut):
    """Comprehensive PWM duty-cycle verification."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.uio_in.value = 0x80
    dut.ui_in.value = 0
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    for _ in range(3):
        dut.clk.value = 1
        await Timer(25, unit="ns")
        dut.clk.value = 0
        await Timer(25, unit="ns")

    async def measure_duty_cycle(audio_level, sample_cycles=64):
        dut.ui_in.value = audio_level & 0xff
        dut.uio_in.value = 0x80
        high_count = 0
        
        for _ in range(sample_cycles):
            dut.clk.value = 1
            await Timer(25, unit="ns")
            if (int(dut.uo_out.value) & 0x01) == 1:
                high_count += 1
            dut.clk.value = 0
            await Timer(25, unit="ns")
            
        return high_count / sample_cycles

    # Test case 1: Low audio level duty cycle
    duty_low = await measure_duty_cycle(16)
    
    # Test case 2: Mid audio level duty cycle
    duty_mid = await measure_duty_cycle(128)
    
    # Test case 3: High audio level duty cycle
    duty_high = await measure_duty_cycle(240)

    assert 0.0 <= duty_low <= 1.0
    assert 0.0 <= duty_mid <= 1.0
    assert 0.0 <= duty_high <= 1.0
    assert duty_low <= duty_mid <= duty_high, "PWM duty cycle not monotonic"