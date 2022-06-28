#include "siphash_def.p4"
#include "tb_decrypt.p4"
#include "tb_set_port.p4"
#include "tb_stack_encrypt.p4"

Hash<bit<32>>(HashAlgorithm_t.IDENTITY) copy32_0;

apply {
    if(hdr.phi.recirculated == 1w0) {
        /* Pass 1 */
        sip_2_a();sip_3_a();sip_3_b();sip_4_a();
        hdr.meta.v0_0 = hdr.meta.v1_0;

        SIP_ROUND();
        hdr.meta.v0_0 = hdr.meta.v1_0;
        SIP_ROUND();
        hdr.meta.v0_0 = hdr.meta.v1_0;

        hdr.phi.recirculated = 1;

    } else if(hdr.phi.mode == 2w3 && hdr.phi.handshake_phase != 2w3) {
        /* Pass 2 (Path Request) */
        SIP_ROUND();
        hdr.meta.v0_0 = hdr.meta.v1_0;

        hdr.meta.v0_0 = hdr.meta.v0_0 ^ hdr.meta.v0_1;
        hdr.meta.v0_2 = hdr.meta.v0_2 ^ hdr.meta.v0_3;
        hdr.meta.otp = copy32_0.get(hdr.meta.v0_0 ^ hdr.meta.v0_2);

        tb_decrypt.apply();
        tb_set_port.apply();
        tb_stack_encrypt.apply();
        hdr.phi.recirculated = 0;
        hdr.meta.setInvalid();

    } else {
        /* Pass 2 (IP) */
        hdr.phi.recirculated = 0;
        hdr.meta.setInvalid();
    }
}
