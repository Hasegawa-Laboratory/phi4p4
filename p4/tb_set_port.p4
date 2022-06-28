action check_midway() {
    hdr.meta.is_midway = hdr.phi_stack_top.ingress_port ^ hdr.meta.egress_port;
}

action set_port_from_stack_backward() {
    hdr.meta.egress_port = hdr.phi_stack_top.ingress_port;
}

action set_port_from_stack_forward() {
    hdr.meta.egress_port = hdr.phi_stack_bottom.egress_port;
}

table tb_set_port {
    key = {
        hdr.phi.mode: exact;
        hdr.phi.handshake_phase: exact;
    }
    actions = {
        NoAction;
        set_port_from_stack_backward;
        set_port_from_stack_forward;
        check_midway;
    }
    const size = 8;
    const default_action = NoAction();
    
    const entries = {
        (2w0, 2w0) : set_port_from_stack_forward();
        (2w1, 2w0) : set_port_from_stack_backward();
        (2w3, 2w3) : set_port_from_stack_backward();
        (2w3, 2w0) : check_midway();
        (2w3, 2w1) : check_midway();
        (2w3, 2w2) : check_midway();
    }
    
}
