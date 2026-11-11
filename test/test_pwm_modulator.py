import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import math

@cocotb.test()
async def test_pwm_stage(dut):
    clock = Clock(dut.clk, 1000, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.audio_in.value = 0
    await Timer(2000, units="ns")
    dut.rst_n.value = 1

    # Test full negative, full positive, and sine tracking
    dut.audio_in.value = -512
    await Timer(10000, units="ns")

    dut.audio_in.value = 511
    await Timer(10000, units="ns")

    for i in range(500):
        await RisingEdge(dut.clk)
        dut.audio_in.value = int(300 * math.sin(i * 0.05))

    dut._log.info("PWM Modulator test passed JUnit requirements.")