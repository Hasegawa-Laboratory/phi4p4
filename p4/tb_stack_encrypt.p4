Hash<bit<16>>(HashAlgorithm_t.IDENTITY) copy16_2;
Hash<bit<16>>(HashAlgorithm_t.IDENTITY) copy16_3;

action stack_rot_bw() {
    hdr.phi_stack_top.setInvalid();
    hdr.phi_stack_bottom.setValid();
    hdr.phi_stack_bottom.ingress_port = hdr.phi_stack_top.ingress_port ^ copy16_2.get(hdr.meta.otp[31:16]);
    hdr.phi_stack_bottom.egress_port = hdr.phi_stack_top.egress_port ^ copy16_3.get(hdr.meta.otp[15:0]);
    hdr.phi_stack_bottom.nonce = hdr.meta.nonce ^ CONST_3;
}

action stack_rot_fw() {
    hdr.phi_stack_bottom.setInvalid();
    hdr.phi_stack_top.setValid();
    hdr.phi_stack_top.ingress_port = hdr.phi_stack_bottom.ingress_port ^ copy16_2.get(hdr.meta.otp[31:16]);
    hdr.phi_stack_top.egress_port = hdr.phi_stack_bottom.egress_port ^ copy16_3.get(hdr.meta.otp[15:0]);
    hdr.phi_stack_top.nonce = hdr.meta.nonce ^ CONST_3;
}

action stack_push() {
    hdr.phi_stack_bottom.setInvalid();
    hdr.phi_stack_top.setValid();

    hdr.phi_stack_top.ingress_port = hdr.meta.ingress_port ^ copy16_2.get(hdr.meta.otp[31:16]);
    hdr.phi_stack_top.egress_port = hdr.meta.egress_port ^ copy16_3.get(hdr.meta.otp[15:0]);
    hdr.phi_stack_top.nonce = hdr.meta.nonce ^ CONST_3;
}

action stack_revise() {
    hdr.phi_stack_top.ingress_port = hdr.phi_stack_top.ingress_port ^ copy16_2.get(hdr.meta.otp[31:16]);
    hdr.phi_stack_top.egress_port = hdr.meta.egress_port ^ copy16_3.get(hdr.meta.otp[15:0]);
    hdr.phi.handshake_phase = 2w2;
}

table tb_stack_encrypt {
    key = {
        hdr.phi.mode: exact;
        hdr.phi.handshake_phase: exact;
        hdr.meta.is_midway: ternary;
    }
    actions = {
        NoAction;
        stack_rot_fw;
        stack_rot_bw;
        stack_push;
        stack_revise;
    }
    const size = 8;
    const default_action = NoAction();
    const entries = {
        (2w0, 2w0, _) : stack_rot_fw();
        (2w1, 2w0, _) : stack_rot_bw();
        (2w3, 2w0, _) : stack_push();
        (2w3, 2w1, 16w0x0 &&& 16w0x1FF) : stack_rot_bw();
        (2w3, 2w1, _) : stack_revise();
        (2w3, 2w2, _) : stack_push();
        (2w3, 2w3, _) : stack_rot_bw();
    }
}
