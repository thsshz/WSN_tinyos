#ifndef WSN_MSG_H
#define WSN_MSG_H

// 节点1、2采样数据
// 节点1、2读取传感器数据后直接发出，不需用公式处理
// 由电脑读取数据时处理
typedef nx_struct sample_msg {
    nx_uint16_t head;
    nx_uint16_t nodeId; // 采集节点的ID
    nx_uint16_t seqNo; // 样本序列号（每个节点都从1开始）
    nx_uint16_t temp; // 温度
    nx_uint16_t humidity; // 湿度
    nx_uint16_t photo; // 光照
    nx_uint16_t time; // 时间（从采样开始经过的毫秒数，用Timer.getNow()获取）
} sample_msg_t;

typedef nx_struct frequency_msg{
    nx_uint16_t head;
    nx_uint16_t frequency; // 设定的采样频率
} frequency_msg_t;

enum {
    BASE_STATION_ID = 0,
    MIDDLE_NODE_ID = 1,
    RARE_NODE_ID = 2,
    AM_SAMPLE_MSG = 0x89,
    AM_FREQUENCY_MSG = 0x90,
    FEQ_HEAD = 0x16cb,
    SMP_HEAD = 0x2e3f,
};

#endif
