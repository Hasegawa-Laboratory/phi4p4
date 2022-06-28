parser MyIngressParser3(packet_in packet,
    out headers hdr,
    out metadata meta,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    #include "ingress_parser.p4"
}

control MyIngressControl3(inout headers hdr,
    inout metadata meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    #include "ingress_control.p4"
}

control MyIngressDeparser3(
    packet_out packet, 
    inout headers hdr, 
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    #include "ingress_deparser.p4"    
}

parser MyEgressParser3(
    packet_in packet,
    out headers hdr,
    out metadata meta,
    out egress_intrinsic_metadata_t eg_intr_md) {
    #include "egress_parser.p4"
}

control MyEgressControl3(
    inout headers hdr,
    inout metadata meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    #include "egress_control.p4"
}

control MyEgressDeparser3(
    packet_out packet,
    inout headers hdr,
    in metadata meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    #include "egress_deparser.p4"
}

Pipeline(
    MyIngressParser3(),
    MyIngressControl3(),
    MyIngressDeparser3(),
    MyEgressParser3(),
    MyEgressControl3(),
    MyEgressDeparser3()) pipe3;