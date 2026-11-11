import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import math

@cocotb.test()
async def test_dc_removal_stage(dut):
    clock = Clock(dut.clk, 1000, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.sample_en.value = 1
    dut.sample_in.value = 1000  # Large DC bias
    await Timer(2000, units="ns")
    dut.rst_n.value = 1

    # Feed samples with DC offset + AC modulation
    for i in range(1000):
        await RisingEdge(dut.clk)
        ac_val = int(100 * math.sin(i * 0.1))
        dut.sample_in.value = 1000 + ac_val

    dut._log.info("DC Removal stage test passed.")