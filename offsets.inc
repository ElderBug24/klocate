
_offset_filebuf_ptr      equ 0
_offset_filebuf_len      equ 8
_offset_filebuf_fd       equ 16
_offset_filebuf_capacity equ 24

_offset_p_sq_entries  equ 0
_offset_p_cq_entries  equ 4
_offset_p_flags       equ 8
_offset_p_sq_idle     equ 16
_offset_p_features    equ 20
_offset_p_sq_head     equ 40
_offset_p_sq_tail     equ 44
_offset_p_sq_flags    equ 56
_offset_p_cq_head     equ 80
_offset_p_cq_tail     equ 84
_offset_p_cq_cqes     equ 100

_offset_sqe_opcode    equ 0
_offset_sqe_flags     equ 1
_offset_sqe_fd        equ 4
_offset_sqe_off       equ 8
_offset_sqe_addr      equ 16
_offset_sqe_len       equ 24
_offset_sqe_user_data equ 32

_offset_cqe_user_data equ 0
_offset_cqe_res       equ 8

