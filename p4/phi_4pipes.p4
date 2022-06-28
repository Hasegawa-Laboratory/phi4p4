#include <core.p4>
#include <tna.p4>

#include "common/headers.p4"
#include "common/util.p4"

#define FIB_SIZE 135000

#define CONST_0 32w0x70736575;
#define CONST_1 32w0x6e646f6d;
#define CONST_2 32w0x6e657261;
#define CONST_3 32w0x79746573;

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_IPV6 = 0x86DD;
const bit<8> TYPE_TCP = 0x6;
const bit<4> VERSION_IPV4 = 0x4;
const bit<4> VERSION_IPV6 = 0x6;

const bit<9> RECIRCULATION_PORT0 = 68;
const bit<9> RECIRCULATION_PORT1 = 196;
const bit<9> RECIRCULATION_PORT2 = 324;
const bit<9> RECIRCULATION_PORT3 = 452;

typedef bit<9> port_id_t;

header metadata {
}

header phi_h {
    /*
        mode:
        00 -> data transfer, forward
        01 -> data transfer, backward
        11 -> handshake

        handshake_phase:
        00 -> data transfer
        00 -> source to helper
        01 -> helper to midway
        10 -> midway to destination
        11 -> destination to source
    */
    bit<2> mode;
    bit<2> handshake_phase;
    bit<1> recirculated;
    bit<91> padding;
}

header phi_handshake_h {
    bit<32> padding;
    bit<32> plain_dst;
}

header phi_stack_item_h {
    bit<16> ingress_port;
    bit<16> egress_port;
    bit<32> nonce;
}

header phi_stack_body_h {
    bit<896> mid_items;
    bit<32> last_ports;
    bit<32> last_nonce;
}

header meta_h {
    bit<32> nonce;

    bit<16> ingress_port;
    bit<16> egress_port;

    bit<16> is_midway;
    bit<8> recirculation_random;

    bit<32> otp;
    bit<32> v0_0;
    bit<32> v0_1;
    bit<32> v0_2;
    bit<32> v0_3;
    bit<32> v1_0;
    bit<32> v1_1;
    bit<32> v1_2;
    bit<32> v1_3;
}

struct headers {
    ethernet_h ethernet;
    phi_h phi;
    phi_handshake_h phi_handshake;

    phi_stack_item_h phi_stack_top;
    phi_stack_body_h phi_stack_body;
    phi_stack_item_h phi_stack_bottom;

    meta_h meta;
}

#include "phi_pipe0.p4"
#include "phi_pipe1.p4"
#include "phi_pipe2.p4"
#include "phi_pipe3.p4"

Switch(pipe0, pipe1, pipe2, pipe3) main;
