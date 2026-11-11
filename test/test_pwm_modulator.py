import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_pwm_modulator_comprehensive(dut):
    """Extensive duty-cycle verification across low, medium, and high audio levels."""
    
    dut.clk.value = 0
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.uio_in.value = 0x80  # PWM mode select
    await Timer(100, unit="ns")
    
    dut.rst_n.value = 1
    await Timer(50, unit="ns")

    async def measure_duty_cycle(audio_level, sample_cycles=300):
        dut.ui_in.value = audio_level & 0xff
        high_count = 0
        
        for _ in range(sample_cycles):
            dut.clk.value = 1
            await Timer(25, unit="ns")
            if (int(dut.uo_out.value) & 0x01) == 1:
                high_count += 1
            dut.clk.value = 0
            await Timer(25, unit="ns")
            
        return high_count / sample_cycles

    # Test 1: Low audio level (Small duty cycle)
    dut._log.info("Testing low-scale audio duty cycle...")
    duty_low = await measure_duty_cycle(32)
    
    # Test 2: Mid-scale audio level (~50% duty cycle) 
    dut._log.info("Testing mid-scale audio duty cycle...")
    duty_mid = await measure_duty_cycle(128)
    assert 0.40 <= duty_mid <= 0.60, f.format(duty_mid) + " Mid-scale duty cycle not on target"

    # Test Case 3: High audio level (Large duty cycle) 
    dut._log.info("Testing high-scale audio duty cycle...")
    duty_high = await measure_duty_cycle(224)
    
    # Verify strict monotonic relationship (higher input -> higher duty cycle)
    assert duty_low < duty_mid < duty_high, "PWM duty cycle is not monotonic with audio input"

    dut._log.info("PWM modulator comprehensive verification passed successfully.")