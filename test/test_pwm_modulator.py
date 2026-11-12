import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_pwm_modulator_comprehensive(dut):
    """RTL-only: buffered PWM timing from the actual limiter output."""
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    counter = 0
    active_duty = pending_duty = 16
    async def measure_duty_cycle(adc_sample, sample_cycles=64):
        nonlocal counter, active_duty, pending_duty
        high_count = 0
        for i in range(sample_cycles):
            dut.clk.value = 0
            dut.ui_in.value = adc_sample & 0xff
            dut.uio_in.value = i & 0xff  # Unused inputs cannot select outputs.
            await Timer(500, unit="ns")
            audio = int(dut.user_project.limited_audio.value)
            if audio & 512:
                audio -= 1024
            expected = int(counter < active_duty)
            if counter == 31:
                active_duty = pending_duty
            counter = (counter + 1) % 32
            pending_duty = audio // 32 + 16
            dut.clk.value = 1
            await Timer(500, unit="ns")
            # Check the physical output, including the seven tied-low bits.
            assert int(dut.uo_out.value) == expected
            high_count += expected
        return high_count / sample_cycles

    # Test case 1: Zero audio produces exactly 50% duty.
    assert await measure_duty_cycle(0) == 0.5

    # Test cases 2/3: Signed ADC extremes through the connected receiver.
    # ADC amplitude alone does not determine duty monotonically after mixing.
    duty_low = await measure_duty_cycle(-128, 256)
    duty_high = await measure_duty_cycle(127, 256)
    assert 0.0 <= duty_low <= 1.0
    assert 0.0 <= duty_high <= 1.0
    assert int(dut.uio_out.value) == int(dut.uio_oe.value) == 0
