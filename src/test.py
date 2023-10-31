import cocotb
import struct
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

    dut.uio_in.value = 2
    for i in range(16):
        await ClockCycles(dut.clk, 1)
        print_chip_state(dut)
        spike, u = neuron(x=0b0000_0001, w=0b1111_1101, last_u=u)
        dut.uo_out[0] == spike
        #assert dut.uo_out[0] == [0,0,0,0, 1,0,0,0, 0,1,0,0][i]

@cocotb.test()
async def test_neuron_16(dut):
    await reset(dut)
    u = 0

    dut._log.info("load weights 1111_1101_0000_0010")
    dut.uio_in.value = 1
    dut.ui_in.value = 0b1111_1101
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b0000_0010
    await ClockCycles(dut.clk, 1)
    print_chip_state(dut)

    dut._log.info("set input 0000_0001_0000_0010")
    dut.uio_in.value = 0
    dut.ui_in.value = 0b0000_0001
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b0000_0010
    await ClockCycles(dut.clk, 1)

    dut._log.info("calculate")
    dut.uio_in.value = 2
    for i in range(16):
        await ClockCycles(dut.clk, 1)
        print_chip_state(dut)
        spike, u = neuron(x=0b0000_0001_0000_0010, w=0b1111_1101_0000_0010, last_u=u)
        dut.uo_out[0] == spike

    await done(dut)

@cocotb.test()
async def test_neuron_long(dut):
    await reset(dut)
    u = 0

    x=0b0000_0001_0000_0010_0000_0001_0000_0010
    w=0b1111_1101_0000_0010_1111_1101_0000_0010

    dut._log.info(f"load weights {bin(w)}")
    dut.uio_in.value = 1
    for v in struct.Struct('>I').pack(w):
        dut.ui_in.value = v
        await ClockCycles(dut.clk, 1)
    print_chip_state(dut)

    dut._log.info(f"set input {bin(x)}")
    dut.uio_in.value = 0
    for v in struct.Struct('>I').pack(x):
        dut.ui_in.value = v
        await ClockCycles(dut.clk, 1)
    print_chip_state(dut)

    dut._log.info("calculate")
    dut.uio_in.value = 2
    for i in range(16):
        await ClockCycles(dut.clk, 1)
        print_chip_state(dut)
        spike, u = neuron(x, w, last_u=u)
        dut.uo_out[0] == spike

    await done(dut)

@cocotb.test()
async def test_neuron_loop(dut):

    for w in range(4):
        for x in range(1,5):
            await reset(dut)
            u = 0
            spike_train = []

            dut._log.info(f"load weights {bin(w)}")
            dut.uio_in.value = 1
            for v in struct.Struct('>I').pack(w):
                dut.ui_in.value = v
                await ClockCycles(dut.clk, 1)
            print_chip_state(dut)

            dut._log.info(f"set input {bin(x)}")
            dut.uio_in.value = 0
            for v in struct.Struct('>I').pack(x):
                dut.ui_in.value = v
                await ClockCycles(dut.clk, 1)
            print_chip_state(dut)

            dut._log.info("calculate")
            dut.uio_in.value = 2
            for i in range(16):
                await ClockCycles(dut.clk, 1)
                # print_chip_state(dut)
                spike, u = neuron(x, w, last_u=u)
                dut.uo_out[0] == spike
                spike_train.append(dut.uo_out[0].value)

            dut._log.info(f"OK {sum(spike_train)} {str(spike_train).replace(', ', '')}")


    await done(dut)

@cocotb.test()
async def test_neuron_long_loop(dut):
    await reset(dut)

    input_range = (0, 64)
    for w in range(64):
        dut._log.info(f"weights: {bin(w)}, inputs: {input_range}")
        spike_counts = []
        for x in range(*input_range):

            dut.rst_n.value = 0
            await ClockCycles(dut.clk, 10)
            dut.rst_n.value = 1

            u = 0
            spike_train = []

            dut.uio_in.value = 1
            for v in struct.Struct('>I').pack(w):
                dut.ui_in.value = v
                await ClockCycles(dut.clk, 1)

            dut.uio_in.value = 0
            for v in struct.Struct('>I').pack(x):
                dut.ui_in.value = v
                await ClockCycles(dut.clk, 1)

            dut.uio_in.value = 2
            for i in range(16):
                await ClockCycles(dut.clk, 1)
                spike, u = neuron(x, w, last_u=u)
                dut.uo_out[0] == spike
                spike_train.append(dut.uo_out[0].value)

            spike_counts.append(sum(spike_train))
        dut._log.info(spike_counts)


    await done(dut)

### UTILS #####################################################################

def print_chip_state(dut):
    try:
        internal = dut.tt_um_rejunity_lif_uut
        print(  "W" if dut.uio_in.value & 1 else "I",
                "X" if dut.uio_in.value & 2 else " ",
                dut.ui_in.value, '|',
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
