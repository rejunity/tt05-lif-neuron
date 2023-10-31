import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles


def popcount(x):
    return bin(x).count("1")

def neuron(x, w, last_u, shift = 0, threshold = 5):
    u = popcount(x & w) - popcount(x & ~w)
    u = last_u + u - u >> shift
    spike = (u >= threshold)
    if spike:
        u -= threshold
    return spike, u

### TESTS #####################################################################

@cocotb.test()
async def test_neuron(dut):
    await reset(dut)
    u = 0

    dut._log.info("load weights 1111_1101")
    dut.uio_in.value = 1
    dut.ui_in.value = 0b1111_1101
    await ClockCycles(dut.clk, 1)
    print_chip_state(dut)

    dut._log.info("calculate")
    dut._log.info("input 0000_0001")
    dut.uio_in.value = 0
    dut.ui_in.value = 0b0000_0001
    await ClockCycles(dut.clk, 1)

    for i in range(16):
        await ClockCycles(dut.clk, 1)
        print_chip_state(dut)
        spike, u = neuron(x=0b0000_0001, w=0b1111_1101, last_u=u)
        dut.uo_out[0] == spike
        #assert dut.uo_out[0] == [0,0,0,0, 1,0,0,0, 0,1,0,0][i]

    # dut.ui_in.value = 0b0000_0011
    # dut._log.info("input 0000_0011")
    # await ClockCycles(dut.clk, 1)
    # for i in range(12):
    #     await ClockCycles(dut.clk, 1)
    #     # print(dut.tt_um_rejunity_telluride2023_neuron_uut.w.value,
    #     #         dut.tt_um_rejunity_telluride2023_neuron_uut.neuron_uut.w.value,
    #     #         dut.tt_um_rejunity_telluride2023_neuron_uut.neuron_uut.x.value,
    #     #         int(dut.tt_um_rejunity_telluride2023_neuron_uut.neuron_uut.u_out),
    #     #         dut.tt_um_rejunity_telluride2023_neuron_uut.neuron_uut.is_spike.value,
    #     #         dut.uo_out.value)
    #     assert dut.uo_out[0] == [0,0,0,0, 0,0,0,0, 0,0,0,0][i]

    await done(dut)

### UTILS #####################################################################

def print_chip_state(dut):
    try:
        internal = dut.tt_um_rejunity_lif_uut
        print(  dut.ui_in.value, '|',
                internal.x.value, '*',
                internal.w.value, '=',
                int(internal.neuron.u_out), '|',
                internal.neuron.is_spike.value,
                )
    except:
       print(dut.ui_in.value, dut.uio_in.value, ">", dut.uo_out.value)

async def reset(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.ui_in.value  = 0
    dut.uio_in.value = 0

    # reset
    dut._log.info("reset {shift=0, threshold=5, membrane=0}")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

async def done(dut):
    dut._log.info("DONE!")

def get_output(dut):
    return int(dut.uo_out.value)
