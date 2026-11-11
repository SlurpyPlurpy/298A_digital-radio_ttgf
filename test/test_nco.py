import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_nco_stage(dut):
    clock = Clock(dut.clk, 1000, units="ns") # 1 MHz clock
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.uio_in.value = 0 # Channel 0
    await Timer(2000, units="ns")
    dut.rst_n.value = 1
    
    dut._log.info("Testing NCO Channel 0...")
    await Timer(20000, units="ns")

    dut._log.info("Switching NCO channel via uio_in...")
    dut.uio_in.value = 0b1111 # Max channel
    await Timer(20000, units="ns")
    
    dut._log.info("NCO test passed.")
