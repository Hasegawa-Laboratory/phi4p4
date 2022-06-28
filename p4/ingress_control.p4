Random<bit<32>>() random32_0;

action initialize0_new_nonce() {
    hdr.meta.v0_0 = CONST_0;
    hdr.meta.v0_1 = CONST_1;
    hdr.meta.v0_2 = CONST_2;
    hdr.meta.nonce = random32_0.get();
}

action initialize0_existing_nonce() {
    hdr.meta.v0_0 = CONST_0;
    hdr.meta.v0_1 = CONST_1;
    hdr.meta.v0_2 = CONST_2;
    hdr.meta.nonce = hdr.phi_stack_top.nonce;
}

table tb_initialize0 {
    key = {
        hdr.phi.recirculated: exact;
        hdr.phi.mode: exact;
        hdr.phi.handshake_phase: exact;
        }
    size = 16;
    actions = {
        NoAction;
        initialize0_new_nonce;
        initialize0_existing_nonce;
    }
    const default_action = NoAction();
    const entries = {
        (1w0, 2w0, 2w0) : initialize0_existing_nonce();
        (1w0, 2w1, 2w0) : initialize0_existing_nonce();
        (1w0, 2w3, 2w0) : initialize0_new_nonce();
        (1w0, 2w3, 2w1) : initialize0_existing_nonce();
        (1w0, 2w3, 2w2) : initialize0_new_nonce();
        (1w0, 2w3, 2w3) : initialize0_existing_nonce();
    }
}

action initialize1(bit<32> key0, bit<32> key1) {
    hdr.meta.setValid();
    hdr.meta.v0_0 = hdr.meta.v0_0 ^ key0;
    hdr.meta.v0_1 = hdr.meta.v0_1 ^ key1;
    hdr.meta.v0_2 = hdr.meta.v0_2 ^ key0;
    hdr.meta.v0_3 = hdr.meta.nonce ^ key1;
    hdr.meta.nonce = hdr.meta.nonce ^ CONST_3;
}

table tb_initialize1 {
    key = { 
        hdr.phi.recirculated: exact;
        }
    size = 2;
    actions = {
        NoAction;
        initialize1;
    }
    const default_action = NoAction();
    const entries = {
        1w0 : initialize1(32w0x01234567, 32w0x12345678);    // secret key
    }
}

#include "siphash_def.p4"
#include "tb_decrypt.p4"
#include "tb_set_port.p4"
#include "tb_stack_encrypt.p4"

action set_recirculation_port(port_id_t port) {
    ig_tm_md.ucast_egress_port = port;
}

table tb_set_recirculation_port {
    key = {
        hdr.ethernet.ether_type: ternary;
        hdr.phi.mode: ternary;
        hdr.phi.handshake_phase: ternary;
        hdr.meta.recirculation_random: ternary;
        hdr.phi_handshake.plain_dst: ternary;
    }
    actions = {
        set_recirculation_port;
    }
    const size = 128;
}

action set_forwarding_port(bit<9> egress_port) {
    hdr.meta.egress_port = (bit<16>)egress_port;
}

action drop() {
    ig_dprsr_md.drop_ctl = 7; 
}

// routing table
table tb_fowarding {
    key = {
        hdr.phi_handshake.plain_dst: lpm;
    }
    actions = {
        drop;
        set_forwarding_port;
    }
    const size = FIB_SIZE;
    const default_action = drop();
}

Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_0;
Random<bit<8>>() random8_0;

apply {

    if(hdr.phi.recirculated == 1w0) {
        /* Pass 1 */
        tb_initialize0.apply();
        tb_initialize1.apply();

        SIP_ROUND();
        hdr.meta.v0_0 = hdr.meta.v1_0;
        hdr.meta.recirculation_random = random8_0.get();
        SIP_ROUND();
        hdr.meta.v0_0 = hdr.meta.v1_0 ^ hdr.meta.nonce;
        hdr.meta.v0_2 = hdr.meta.v0_2 ^ 32w0xff;

        hdr.meta.ingress_port = 7w0 ++ ig_intr_md.ingress_port;
        tb_set_recirculation_port.apply();

        sip_1_a();sip_1_b();
    
    } else if (hdr.ethernet.ether_type == 0x0800 || hdr.phi.mode == 2w3 && hdr.phi.handshake_phase != 2w3) {
        /* Pass 2 (FIB) */
        tb_fowarding.apply();
        ig_tm_md.ucast_egress_port = hdr.meta.egress_port[8:0];
    
    } else {
        /* Pass 2 (Transmission) */
        SIP_ROUND();
        hdr.meta.v0_0 = hdr.meta.v1_0;

        hdr.meta.v0_0 = hdr.meta.v0_0 ^ hdr.meta.v0_1;
        hdr.meta.v0_2 = hdr.meta.v0_2 ^ hdr.meta.v0_3;

        hdr.meta.otp = copy32_0.get(hdr.meta.v0_0 ^ hdr.meta.v0_2);
        tb_decrypt.apply();
        tb_set_port.apply();
        ig_tm_md.ucast_egress_port = hdr.meta.egress_port[8:0];
        tb_stack_encrypt.apply();
        hdr.phi.recirculated = 0;
        hdr.meta.setInvalid();
        ig_tm_md.bypass_egress = 1w1;
    }
}