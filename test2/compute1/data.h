#ifndef DATA_H
#define DATA_H

typedef nx_struct data_msg {
    nx_uint16_t sequence_number;
    nx_uint32_t random_integer;
} data_msg_t;

typedef nx_struct request_msg {
    nx_uint8_t nodeId;
    nx_uint16_t sequence_number;
} request_msg_t;

typedef nx_struct response_msg {
    nx_uint8_t nodeId;
    nx_uint16_t sequence_number;
    nx_uint32_t random_integer;
} response_msg_t;

typedef nx_struct result_msg {
    nx_uint8_t group_id;
    nx_uint32_t max;
    nx_uint32_t min;
    nx_uint32_t sum;
    nx_uint32_t average;
    nx_uint32_t median;
} result_msg_t;

typedef nx_struct ack_msg {
    nx_uint8_t group_id;
}ack_msg_t;

enum {
    GROUP_ID = 23,
    BROADCAST_ID = 1000,
    RESULT_ID = 0,
    COMPUTE1_ID = 67,
    COMPUTE2_ID = 68,
    RECEIVER_ID = 69,
    AM_DATA_MSG = 0,
    AM_ACK_MSG = 0,
    AM_REQUEST_MSG = 0x90,
    AM_RESPONSE_MSG = 0x91,
    AM_RESULT_MSG = 0,
};

#endif
