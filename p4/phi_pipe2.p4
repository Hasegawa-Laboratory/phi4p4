parser MyIngressParser2(packet_in packet,
    out headers hdr,
    out metadata meta,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    #include "ingress_parser.p4"
}

control MyIngressControl2(inout headers hdr,
    inout metadata meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    #include "ingress_control.p4"
}

control MyIngressDeparser2(
    packet_out packet, 
    inout headers hdr, 
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    #include "ingress_deparser.p4"    
}

parser MyEgressParser2(
    packet_in packet,
    out headers hdr,
    out metadata meta,
    out egress_intrinsic_metadata_t eg_intr_md) {
    #include "egress_parser.p4"
}

control MyEgressControl2(
    inout headers hdr,
    inout metadata meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    #include "egress_control.p4"
}

control MyEgressDeparser2(
    packet_out packet,
    inout headers hdr,
    in metadata meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    #include "egress_deparser.p4"
}

Pipeline(
    MyIngressParser2(),
    MyIngressControl2(),
    MyIngressDeparser2(),
    MyEgressParser2(),
    MyEgressControl2(),
    MyEgressDeparser2()) pipe2;