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

enum {
    BROADCAST_ID = 1000,
    RESULT_ID = 0,
    COMPUTE1_ID = 67,
    COMPUTE2_ID = 68,
    RECEIVER_ID = 69,
    AM_DATA_MSG = 0,
    AM_REQUEST_MSG = 0x90,
    AM_RESPONSE_MSG = 0x91
};

#endif
