// Princeton HalfSipHash

Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_a_1;
Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_a_3;
Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_b_0;
Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_c_1;
Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_c_3;
Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_d_2;

action sip_1_a(){
	hdr.meta.v1_0 = hdr.meta.v0_0 + hdr.meta.v0_1;
	hdr.meta.v1_2 = hdr.meta.v0_2 + hdr.meta.v0_3;
	hdr.meta.v1_1  = copy32_a_1.get({hdr.meta.v0_1[26:0] ++ hdr.meta.v0_1[31:27]});
}

action sip_1_b(){
	hdr.meta.v1_3 = copy32_a_3.get({hdr.meta.v0_3[23:0] ++ hdr.meta.v0_3[31:24]});
}

action sip_2_a(){
	hdr.meta.v0_1 = hdr.meta.v1_1 ^ hdr.meta.v1_0;
	hdr.meta.v0_3 = hdr.meta.v1_3 ^ hdr.meta.v1_2;
	hdr.meta.v0_0 = hdr.meta.v1_0[15:0] ++ hdr.meta.v1_0[31:16];
	hdr.meta.v0_2 = hdr.meta.v1_2;
}

action sip_3_a(){
	hdr.meta.v1_2 = hdr.meta.v0_2 + hdr.meta.v0_1;
	hdr.meta.v1_0 = hdr.meta.v0_0 + hdr.meta.v0_3;
	hdr.meta.v1_1 = copy32_c_1.get({hdr.meta.v0_1[18:0] ++ hdr.meta.v0_1[31:19]});
}

action sip_3_b(){
	hdr.meta.v1_3 = copy32_c_3.get({hdr.meta.v0_3[24:0] ++ hdr.meta.v0_3[31:25]});
}

action sip_4_a(){
	hdr.meta.v0_1 = hdr.meta.v1_1 ^ hdr.meta.v1_2;
	hdr.meta.v0_3 = hdr.meta.v1_3 ^ hdr.meta.v1_0;
	hdr.meta.v0_2 = hdr.meta.v1_2[15:0] ++ hdr.meta.v1_2[31:16];
}

#define SIP_ROUND() sip_1_a();sip_1_b();sip_2_a();sip_3_a();sip_3_b();sip_4_a()
