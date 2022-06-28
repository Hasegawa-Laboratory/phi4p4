import os
import sys
import ipaddress
import hashlib
from scapy.all import *

if sys. version_info.major != 2:
    raise RuntimeError('Run it with python 2')

sys.path.append(os.path.join(sys.argv[1], 'install/lib/python2.7/site-packages/tofino'))
import bfrt_grpc.client as gc

print('Creating FIB...')
fib = {}
with open('./bgp_fib/rib_wain.txt') as f:
    for line in f:
        line = line.rstrip()
        
        prefix = ipaddress.ip_network(unicode(line.split(' ')[0]), strict=False)
        netaddr = prefix.network_address
        netmask = prefix.netmask
        fib[(netaddr, netmask)] = 0
        
out_ports = list([i for i in range(0, 64, 8)] + [i for i in range(128, 192, 8)] + \
    [i for i in range(256, 320, 8)] + [i for i in range(384, 448, 8)])

for i, key in enumerate(fib):
    h = hashlib.md5(str(key[0]) + str(key[1])).hexdigest()
    fib[key] = out_ports[int(h, 16) % len(out_ports)]

fibs = [{}, {}, {}, {}]
pipe_map = {0x00000000: 0, 0x01000000: 1, 0x10000000: 2, 0x11000000: 3}

for key in fib:
    int_addr = int(key[0])
    pipe = pipe_map[int_addr & 0x11000000]
    fibs[pipe][key] = fib[key]


print('Connecting to Tofino...')
grpc_addr = 'localhost:50052'
client_id = 0
device_id = 0
is_master = False
notifications = None
perform_bind = True

interface = gc.ClientInterface(grpc_addr, client_id=client_id,
        device_id=device_id, is_master=is_master, notifications=notifications)
bfrt_info = interface.bfrt_info_get()
p4_name = bfrt_info.p4_name_get()
if perform_bind:
    interface.bind_pipeline_config(p4_name)
target = gc.Target(device_id=0, pipe_id=0xFFFF)


print('Adding recirculation rules...')
recir_ports = [
    [i for i in range(4, 64, 8)],
    [i for i in range(132, 192, 8)],
    [i for i in range(260, 320, 8)],
    [i for i in range(388, 448, 8)]
]

for stored_pipe in range(4):
    key_list = []
    data_list = []
    recir_table = bfrt_info.table_get('MyIngressControl%d.tb_set_recirculation_port' % stored_pipe)

    ether_type = gc.KeyTuple('hdr.ethernet.ether_type', 0x0800, (1 << 16) - 1)
    ether_type_X = gc.KeyTuple('hdr.ethernet.ether_type', 0, 0)

    mode = gc.KeyTuple('hdr.phi.mode', 3, (1 << 2) - 1)
    mode_X = gc.KeyTuple('hdr.phi.mode', 0, 0)

    phase = gc.KeyTuple('hdr.phi.handshake_phase', 3, (1 << 2) - 1)
    phase_X = gc.KeyTuple('hdr.phi.handshake_phase', 0, 0)

    for remote_pipe in range(4):
        for i, recir_port in enumerate(recir_ports[remote_pipe]):
            rand_1 = gc.KeyTuple('hdr.meta.recirculation_random', i, (1 << 3) - 1)
            dst = gc.KeyTuple('hdr.phi_handshake.plain_dst', [0x00000000, 0x01000000, 0x10000000, 0x11000000][remote_pipe], 0x11000000)

            key_list.append(recir_table.make_key([ether_type, mode_X, phase_X, rand_1, dst]))
            data_list.append(recir_table.make_data([gc.DataTuple('port', recir_port)], 'MyIngressControl%d.set_recirculation_port' % stored_pipe))

    for remote_pipe in range(4):
        for i, recir_port in enumerate(recir_ports[remote_pipe]):
            rand_2 = gc.KeyTuple('hdr.meta.recirculation_random', i | remote_pipe << 3, (1 << 5) - 1)
            dst_X = gc.KeyTuple('hdr.phi_handshake.plain_dst', 0, 0)

            key_list.append(recir_table.make_key([ether_type_X, mode, phase, rand_2, dst_X]))
            data_list.append(recir_table.make_data([gc.DataTuple('port', recir_port)], 'MyIngressControl%d.set_recirculation_port' % stored_pipe))

    for remote_pipe in range(4):
        for i, recir_port in enumerate(recir_ports[remote_pipe]):
            rand_1 = gc.KeyTuple('hdr.meta.recirculation_random', i, (1 << 3) - 1)
            dst = gc.KeyTuple('hdr.phi_handshake.plain_dst', [0x00000000, 0x01000000, 0x10000000, 0x11000000][remote_pipe], 0x11000000)

            key_list.append(recir_table.make_key([ether_type_X, mode, phase_X, rand_1, dst]))
            data_list.append(recir_table.make_data([gc.DataTuple('port', recir_port)], 'MyIngressControl%d.set_recirculation_port' % stored_pipe))

    for remote_pipe in range(4):
        for i, recir_port in enumerate(recir_ports[remote_pipe]):
            rand_2 = gc.KeyTuple('hdr.meta.recirculation_random', i | remote_pipe << 3, (1 << 5) - 1)
            dst_X = gc.KeyTuple('hdr.phi_handshake.plain_dst', 0, 0)

            key_list.append(recir_table.make_key([ether_type_X, mode_X, phase_X, rand_2, dst_X]))
            data_list.append(recir_table.make_data([gc.DataTuple('port', recir_port)], 'MyIngressControl%d.set_recirculation_port' % stored_pipe))

    recir_table.entry_add(target, key_list, data_list)


print('Adding forwarding rules...')
for pipe in range(4):
    forwarding_table = bfrt_info.table_get('MyIngressControl%d.tb_fowarding' % pipe)
    forwarding_table.info.key_field_annotation_add("hdr.phi_handshake.plain_dst", "ipv4")
    
    key_list = []
    data_list = []
    for key in fibs[pipe]:
        key_list.append(
            forwarding_table.make_key([gc.KeyTuple('hdr.phi_handshake.plain_dst', str(key[0]), prefix_len=bin(int(key[1])).count('1'))]) 
        )
        data_list.append(
            forwarding_table.make_data([gc.DataTuple('egress_port', fibs[pipe][key])], 'MyIngressControl%d.set_forwarding_port' % pipe) 
        )
    forwarding_table.entry_add(target, key_list, data_list)

