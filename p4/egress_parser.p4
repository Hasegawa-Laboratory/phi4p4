TofinoEgressParser() tofino_parser;

state start {
    tofino_parser.apply(packet, eg_intr_md);
    transition parse_ethernet;
}

state parse_ethernet {
    packet.extract(hdr.ethernet);
    transition parse_phi_header;
}

state parse_phi_header {
    packet.extract(hdr.phi);
    transition parse_phi_handshake;
}

state parse_phi_handshake {
    packet.extract(hdr.phi_handshake);
    
    transition select(hdr.phi.mode, hdr.phi.handshake_phase) {
        (2w0, 2w0): parse_phi_stack_forward;
        (2w1, 2w0): parse_phi_stack_backward;

        (2w3, 2w0) : parse_phi_stack_forward;
        (2w3, 2w1) : parse_phi_stack_backward;
        (2w3, 2w2) : parse_phi_stack_forward;

        (2w3, 2w3) : parse_phi_stack_backward;
        default: reject;
    }
}

state parse_phi_stack_forward {
    packet.extract(hdr.phi_stack_body);
    packet.extract(hdr.phi_stack_bottom);
    transition parse_meta;
}

state parse_phi_stack_backward {
    packet.extract(hdr.phi_stack_top);
    packet.extract(hdr.phi_stack_body);
    transition parse_meta;
}

state parse_meta {
    packet.extract(hdr.meta);
    transition accept;
}