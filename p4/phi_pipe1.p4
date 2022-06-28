parser MyIngressParser1(packet_in packet,
    out headers hdr,
    out metadata meta,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    #include "ingress_parser.p4"
}

control MyIngressControl1(inout headers hdr,
    inout metadata meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    #include "ingress_control.p4"
}

control MyIngressDeparser1(
    packet_out packet, 
    inout headers hdr, 
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    #include "ingress_deparser.p4"    
}

parser MyEgressParser1(
    packet_in packet,
    out headers hdr,
    out metadata meta,
    out egress_intrinsic_metadata_t eg_intr_md) {
    #include "egress_parser.p4"
}

control MyEgressControl1(
    inout headers hdr,
    inout metadata meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    #include "egress_control.p4"
}

control MyEgressDeparser1(
    packet_out packet,
    inout headers hdr,
    in metadata meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    #include "egress_deparser.p4"
}

Pipeline(
    MyIngressParser1(),
    MyIngressControl1(),
    MyIngressDeparser1(),
    MyEgressParser1(),
    MyEgressControl1(),
    MyEgressDeparser1()) pipe1;