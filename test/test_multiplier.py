import cocotb
from cocotb.triggers import Timer

@cocotb.test()
async def test_multiplier_comprehensive(dut):
    """RTL-only: check the connected mixer using its actual NCO operand."""
    dut.clk.value = 0
    dut.rst_n.value = 1
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(10, unit="ns")
    dut.rst_n.value = 0
    await Timer(100, unit="ns")
    dut.rst_n.value = 1

    async def check_product(ui_val):
        dut.ui_in.value = ui_val & 0xff
        dut.clk.value = 0
        await Timer(500, unit="ns")
        dut.clk.value = 1
        await Timer(500, unit="ns")

        reference = int(dut.user_project.sine_reference.value)
        if reference & 0x80:
            reference -= 256
        full_product = int(dut.user_project.mixer_sample.value)
        if full_product & 0x8000:
            full_product -= 65536
        expected_product = ui_val * reference
        assert full_product == expected_product, (
            f"Multiplier mismatch: got {full_product}, expected {expected_product}"
        )

    # Test case 1: Zero input test.
    await check_product(0)

    # Test case 2: Signed input extremes and intermediate values.
    for _ in range(64):
        for value in [-128, -127, -1, 0, 1, 64, 127]:
            await check_product(value)
