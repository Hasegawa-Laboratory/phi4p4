Hash<bit<16>>(HashAlgorithm_t.IDENTITY) copy16_0;
Hash<bit<16>>(HashAlgorithm_t.IDENTITY) copy16_1;

action decrypt_backward_stack() {
    hdr.phi_stack_top.ingress_port = hdr.phi_stack_top.ingress_port ^ copy16_0.get(hdr.meta.otp[31:16]);
    hdr.phi_stack_top.egress_port = hdr.phi_stack_top.egress_port ^ copy16_1.get(hdr.meta.otp[15:0]);
}

action decrypt_forward_stack() {
    hdr.phi_stack_bottom.ingress_port = hdr.phi_stack_bottom.ingress_port ^ copy16_0.get(hdr.meta.otp[31:16]);
    hdr.phi_stack_bottom.egress_port = hdr.phi_stack_bottom.egress_port ^ copy16_1.get(hdr.meta.otp[15:0]);
}

table tb_decrypt {
    key = {
        hdr.phi.mode: exact;
        hdr.phi.handshake_phase: exact;
    }
    actions = {
        NoAction;
        decrypt_forward_stack;
        decrypt_backward_stack;
    }

    const size = 8;
    const default_action = NoAction();
    const entries = {
        (2w0, 2w0) : decrypt_forward_stack();
        (2w1, 2w0) : decrypt_backward_stack();
        (2w3, 2w0) : NoAction();
        (2w3, 2w1) : decrypt_backward_stack();
        (2w3, 2w2) : NoAction();
        (2w3, 2w3) : decrypt_backward_stack();
    }
}
