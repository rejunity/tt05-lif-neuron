import cocotb
import struct
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

BN_SCALE = 1
BN_ADD = 0

def popcount(x):
    return bin(x).count("1")

# def neuron(x, w, last_u, shift = 0, threshold = 5, bn_scale = 1, bn_addend = 0):
def neuron(x, w, last_u, shift = 0, threshold = 5, bn_scale = BN_SCALE, bn_addend = BN_ADD):
    # print(x, w, x&w, x & ~w)
    psp = popcount(x & w) - popcount(x & ~w)
    psp = psp * bn_scale + bn_addend
    # print("popcount", u, last_u)
    decayed_u = last_u 
    if shift > 0:
        decayed_u -= decayed_u >> shift
    u = psp + decayed_u
    spike = (u >= threshold)
    if spike:
        u -= threshold
    return spike, u

### TESTS #####################################################################

@cocotb.test()
async def test_neuron_excitatory(dut):
    await reset(dut)
    u = 0
    x = 0b0000_0001
    w = 0b1111_1111

    dut._log.info(f"load weights {w}")
    await setup_weight(dut, w)
    print_chip_state(dut)

    dut._log.info(f"input {x}")
    await setup_input(dut, x)
    print_chip_state(dut)

    dut._log.info("execute")
    for i in range(16):
        await execute(dut, 1)
        print_chip_state(dut)
        spike, u = neuron(x=0b0000_0001, w=0b1111_1101, last_u=u)
        assert dut.uo_out[0] == spike
        #assert dut.uo_out[0] == [0,0,0,0, 1,0,0,0, 0,1,0,0][i]

@cocotb.test()
async def test_neuron_inhibitory(dut):
    await reset(dut)
    u = 0
    x=0b0000_0001
    w=0b1111_1110

    dut._log.info(f"load weights {w}")
    await setup_weight(dut, w)
    print_chip_state(dut)

    dut._log.info(f"input {x}")
    await setup_input(dut, x)

    dut._log.info("execute")
    for i in range(16):
        await execute(dut, 1)
        print_chip_state(dut)
        spike, u = neuron(x=0b0000_0001, w=0b1111_1110, last_u=u)
        assert dut.uo_out[0] == spike

@cocotb.test()
async def test_neuron_overflow(dut):
    await reset(dut)

    dut._log.info("load +1 weights")
    for n in range(16):
        await setup_weight(dut, 0b1111_1111)

    dut._log.info("set all inputs +1")
    for n in range(16):
        await setup_input(dut, 0b1111_1111)
        # await setup_input(dut, 0b1111_0101)
        # await setup_input(dut, 0b1111_0011)
    print_chip_state(dut)

    dut._log.info("execute")
    for i in range(16):
        await execute(dut, 1)
        print_chip_state(dut)
        assert dut.uo_out[0] == 1 # constantly spiking

@cocotb.test()
async def test_neuron_underflow(dut):
    await reset(dut)

    dut._log.info("load -1 weights")
    for n in range(16):
        await setup_weight(dut, 0b0000_0000)

    dut._log.info("set all inputs +1")
    for n in range(16):
        await setup_input(dut, 0b1111_1111)

    print_chip_state(dut)

    dut._log.info("execute")
    for i in range(16):
        await execute(dut, 1)
        print_chip_state(dut)
        assert dut.uo_out[0] == 0 # never spiking

@cocotb.test()
async def test_neuron_16(dut):
    await reset(dut)
    u = 0

    dut._log.info("load weights 1111_1101_0000_0010")
    await setup_weight(dut, 0b1111_1101)
    await setup_weight(dut, 0b0000_0010)
    print_chip_state(dut)

    dut._log.info("set input 0000_0001_0000_0010")
    await setup_input(dut, 0b0000_0001)
    await setup_input(dut, 0b0000_0010)

    dut._log.info("execute")
    for i in range(16):
        await execute(dut, 1)
        spike, u = neuron(x=0b0000_0001_0000_0010, w=0b1111_1101_0000_0010, last_u=u)
        print_chip_state(dut, sim=(spike, u))
        # assert dut.uo_out[0] == spike

    await done(dut)

# @cocotb.test() # doesn't work with N_STAGES < 5
async def test_neuron_long(dut):
    await reset(dut)
    u = 0

    x=0b0000_0001_0000_0010_0000_0001_0000_0010
    w=0b1111_1101_0000_0010_1111_1101_0000_0010

    dut._log.info(f"load weights {bin(w)}")
    for v in struct.Struct('>I').pack(w):
        await setup_weight(dut, v)
    print_chip_state(dut)

    dut._log.info(f"set input {bin(x)}")
    for v in struct.Struct('>I').pack(x):
        await setup_input(dut, v)
    print_chip_state(dut)

    dut._log.info("execute")
    for i in range(16):
        await execute(dut, 1)
        spike, u = neuron(x, w, last_u=u)
        print_chip_state(dut, sim=(spike, u))
        assert dut.uo_out[0] == spike

    await done(dut)

@cocotb.test()
async def test_neuron_loop(dut):
    await reset(dut)

    for w in range(4):
        for x in range(1,5):

            dut.ui_in.value  = 0
            dut.uio_in.value = 0
            dut.rst_n.value = 0
            await ClockCycles(dut.clk, 10)
            dut.rst_n.value = 1
            await setup_params(dut)

            u = 0
            spike_train = []

            dut._log.info(f"load weights {bin(w)}")
            for v in struct.Struct('>I').pack(w):
                await setup_weight(dut, v)
            print_chip_state(dut)

            dut._log.info(f"set input {bin(x)}")
            for v in struct.Struct('>I').pack(x):
                await setup_input(dut, v)
            print_chip_state(dut)

            dut._log.info("execute")
            for i in range(16):
                await execute(dut, 1)
                spike, u = neuron(x, w, last_u=u)
                print_chip_state(dut, sim=(spike, u))
                assert dut.uo_out[0] == spike
                spike_train.append(dut.uo_out[0].value)

            dut._log.info(f"OK {sum(spike_train)} {str(spike_train).replace(', ', '')}")

    await done(dut)

@cocotb.test()
async def test_neuron_permute_all_input_weight(dut):
    await reset(dut)
    bn_scale = BN_SCALE

    input_range = (0, 32)
    for w in range(32):
        dut._log.info(f"weights: {bin(w)}, inputs: {input_range}")
        spike_counts = []
        for x in range(*input_range):

            dut.ui_in.value  = 0
            dut.uio_in.value = 0
            dut.rst_n.value = 0
            await ClockCycles(dut.clk, 10)
            dut.rst_n.value = 1
            await setup_params(dut, bn_scale=bn_scale)

            u = 0
            spike_train = []

            for v in struct.Struct('>I').pack(w):
                await setup_weight(dut, v)

            for v in struct.Struct('>I').pack(x):
                await setup_input(dut, v)

            for i in range(16):
                await execute(dut, 1)
                spike, u = neuron(x, w, last_u=u, bn_scale=bn_scale)
                assert dut.uo_out[0] == spike
                spike_train.append(dut.uo_out[0].value)

            spike_counts.append(sum(spike_train))
        dut._log.info(spike_counts)


    await done(dut)


@cocotb.test()
async def test_neuron_spike_train(dut):
    await reset(dut)
    x=0b1011_1011
    # x=1
    # x=0
    w=0b1111_1111

    lif = []
    pwm = []

    dut._log.info("load weights 1111_1101")
    await setup_weight(dut, w)
    print_chip_state(dut)

    dut._log.info("input 0000_0001")
    await setup_input(dut, x)

    for i in range(64):
        await execute(dut, 1)
        lif.append(dut.uo_out[0].value)
        pwm.append(dut.uo_out[1].value)

    print(lif, sum(lif))
    print(pwm, sum(pwm))

    xs=[]
    bits = 5
    alpha = 1.0/(bits**2)
    x = 0
    for v in pwm:
        x = alpha*v + (1-alpha)*x
        xs.append((2**bits)*x)
    print((2**bits)*x, sum(xs)/len(xs), "  ---   ", xs)


### UTILS #####################################################################

def print_chip_state(dut, sim=None):
    try:
        internal = dut.tt_um_rejunity_lif_uut
        print(  
                "X" if dut.uio_in.value & 1 else " ",
                "S" if dut.uio_in.value & 16 else " ",
                dut.ui_in.value, dut.uio_in.value, '|',
                internal.inputs.value, '*',
                internal.weights.value, '=',
                int(internal.neuron_lif.new_membrane), '|',
                "$" if internal.neuron_lif.is_spike == 1 else " ",
                f" vs {sim[1]}" if (sim != None) else "",
                dut.uo_out.value
                )
    except:
       print(dut.ui_in.value, dut.uio_in.value, ">", dut.uo_out.value)

async def reset(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 100, units="us")
    cocotb.start_soon(clock.start())

    dut.ui_in.value  = 0
    dut.uio_in.value = 0

    await ClockCycles(dut.clk, 2)

    # reset
    dut._log.info("reset {shift=0, threshold=5, batchnorm=(1,0) membrane=0}")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    print_chip_state(dut)
    await ClockCycles(dut.clk, 2)
    
    print_chip_state(dut)
    await setup_params(dut)


async def done(dut):
    dut._log.info("DONE!")

def get_output(dut):
    return int(dut.uo_out.value)
 
EXECUTE         = 1
SETUP_SYNC      = 1 << 4
SETUP_INPUT     = 0
SETUP_WEIGHT    = 0b001 << 1
SETUP_THRESHOLD = 0b010 << 1
SETUP_BIAS      = 0b011 << 1
SETUP_SHIFT     = 0b100 << 1
SETUP_BN_PARAMS = 0b110 << 1

async def setup_control(dut, control, v):
    dut.uio_in.value = control
    dut.ui_in.value = v
    await ClockCycles(dut.clk, 1)

    # dut.uio_in.value = control | SETUP_SYNC
    # await ClockCycles(dut.clk, 2)

async def setup_input(dut, x):
    await setup_control(dut, SETUP_INPUT, x)

async def setup_weight(dut, w):
    await setup_control(dut, SETUP_WEIGHT, w)

async def setup_params(dut, shift=0, threshold=5, bias=0, bn_scale=BN_SCALE, bn_add=BN_ADD):
    pass
    # await ClockCycles(dut.clk, 2)

    # if bn_scale == 1:
    #     bn_scale = 0b0100
    # elif bn_scale == 2:
    #     bn_scale = 0b0010
    # elif bn_scale == 4:
    #     bn_scale = 0b1100
    # elif bn_scale == 6:
    #     bn_scale = 0b1110
    # elif bn_scale == 8:
    #     bn_scale = 0b0011
    # elif bn_scale == 0.25:
    #     bn_scale = 0b1000
    # elif bn_scale == 0.5:
    #     bn_scale = 0b0001
    # elif bn_scale == 0.75:
    #     bn_scale = 0b1001
    # elif bn_scale == 1.5:
    #     bn_scale = 0b0101
    # elif bn_scale == 2.25:
    #     bn_scale = 0b1010
    # elif bn_scale == 4.5:
    #     bn_scale = 0b1101
    # else:
    #     bn_scale = 0b0100 # default to 1
    # await setup_control(dut, SETUP_THRESHOLD, threshold)
    # await setup_control(dut, SETUP_BIAS, bias)
    # await setup_control(dut, SETUP_SHIFT, shift)
    # await setup_control(dut, SETUP_BN_PARAMS, ((bn_add & 0xf) << 4) + bn_scale)

async def execute(dut, clk=1):
    dut.uio_in.value = EXECUTE
    await ClockCycles(dut.clk, clk)
