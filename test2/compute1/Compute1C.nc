#include "Timer.h"
#include "data.h"
#include "AM.h"

module Compute1C
{
  uses {
    interface Boot;
    interface Packet;
    interface AMPacket;
    interface Leds;
    interface AMSend as RequestSend;
    interface AMSend as ResultSend;
    interface PacketAcknowledgements as RequestAck;
    interface Receive as DataReceive;
    interface Receive as ResponseReceive;
    interface Receive as AckReceive;
    interface SplitControl as AMControl;
  }
}
implementation
{
  enum {
    DATA_QUEUE_LEN = 2000,
    LOST_QUEUE_LEN = 21,
  };
  uint32_t sort_data[DATA_QUEUE_LEN + 1];
  uint32_t present_data;
  uint16_t sort_number = 0;
  message_t  dataQueueBufs[LOST_QUEUE_LEN];
  message_t  * ONE_NOK dataQueue[LOST_QUEUE_LEN];
  uint16_t lost_data[LOST_QUEUE_LEN];  
  uint8_t    dataIn, dataOut;
  bool       dataBusy, dataFull;
  uint16_t lost_number = 0;
  uint32_t min = 0;
  uint32_t max = 0;
  uint32_t median = 0;
  uint32_t sum = 0;
  uint32_t average;

  bool receive_result = 0;
  bool if_sort = 0;
  message_t result_pkt;
  uint16_t expect_number = 1;

  void dataSortTask();
  task void resultSendTask();
  task void dataSendTask();
  task void quickSortTask();

  void quick_sort(uint32_t s[], uint32_t l, uint32_t r);

  event void Boot.booted() {
    uint8_t i;
    for (i = 0; i < LOST_QUEUE_LEN; i++) {
      dataQueue[i] = &dataQueueBufs[i];
      lost_data[i] = 0;
    }
    dataIn = dataOut = 0;
    dataBusy = FALSE;
    dataFull = FALSE;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    if (err == SUCCESS){
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err){
  }

  event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(data_msg_t) && if_sort == 0) {
      data_msg_t *dpkt = (data_msg_t*)payload;
      if (dpkt->sequence_number == expect_number) {
        expect_number++;
        present_data = dpkt->random_integer;
        dataSortTask();
      }
      else if (dpkt->sequence_number > expect_number) {
        uint16_t i;
        for (i = expect_number; i < dpkt->sequence_number; i++) {
          if (!dataFull){
            atomic {
              request_msg_t *rpkt = (request_msg_t*)(call Packet.getPayload(dataQueue[dataIn],sizeof(request_msg_t)));
              rpkt->nodeId = COMPUTE1_ID;
              rpkt->sequence_number = i;
              lost_data[dataIn] = i;
              lost_number++;
              if (++dataIn >= LOST_QUEUE_LEN)
                dataIn = 0;
              if (dataIn == dataOut)
                dataFull = TRUE;
              if (!dataBusy){
                post dataSendTask();
                dataBusy = TRUE;
              }
            }
          }
        }
        expect_number = dpkt->sequence_number + 1;
      }
      else if (expect_number > 1980 && dpkt->sequence_number < 10) {
        uint16_t i;
        for (i = expect_number; i <= DATA_QUEUE_LEN; i++) {
          if (!dataFull){
            atomic {
              request_msg_t *rpkt = (request_msg_t*)(call Packet.getPayload(dataQueue[dataIn],sizeof(request_msg_t)));
              rpkt->nodeId = COMPUTE1_ID;
              rpkt->sequence_number = i;
              lost_data[dataIn] = i;
              lost_number++;
              if (++dataIn >= LOST_QUEUE_LEN)
                dataIn = 0;
              if (dataIn == dataOut)
                dataFull = TRUE;
              if (!dataBusy){
                post dataSendTask();
                dataBusy = TRUE;
              }
            }
          }
        }
        expect_number = dpkt->sequence_number + 1;
      }
    }
    return msg;
  }

  event message_t* AckReceive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(ack_msg_t)) {
      ack_msg_t *apkt = (ack_msg_t*)payload;
      if (apkt->group_id == GROUP_ID) {
        receive_result = 1;
      }
    }
    return msg;
  }


  void dataSortTask() {
    atomic{
      sort_data[sort_number + 1] = present_data;
      sort_number++;
      sum += present_data;
      if(sort_number == DATA_QUEUE_LEN){
        post quickSortTask();
      }
    }
  }

  task void quickSortTask() {
    quick_sort(sort_data, 1, DATA_QUEUE_LEN);
    min = sort_data[1];
    max = sort_data[DATA_QUEUE_LEN];
    median = (sort_data[1000] + sort_data[1001]) / 2;
    if_sort = 1;
    call Leds.led2Toggle();
    post resultSendTask();
  }

  task void resultSendTask() {
    result_msg_t *repkt = (result_msg_t*)(call Packet.getPayload(&result_pkt,sizeof(result_msg_t)));
    if(repkt == NULL) {
      return;
    }
    repkt->group_id = GROUP_ID;
    repkt->max = max;
    repkt->min = min;
    repkt->sum = sum;
    repkt->average = sum / DATA_QUEUE_LEN;
    repkt->median = median;

    call AMControl.start();
    if (call ResultSend.send(AM_BROADCAST_ADDR, &result_pkt, sizeof(result_msg_t)) == SUCCESS) {
      
    }
    else
    {
      post resultSendTask();
    }
  }

  event void ResultSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS) {
      post resultSendTask();
    }
    else {
      call Leds.led0Toggle();
      post resultSendTask();
    }
  }

  task void dataSendTask() {
    atomic
    if (dataIn == dataOut && !dataFull)
    {
      dataBusy = FALSE;
      return;
    }
    if (call RequestSend.send(RECEIVER_ID, dataQueue[dataOut], sizeof(request_msg_t)) == SUCCESS) {
      call Leds.led1Toggle();
    }
    else
    {
      post dataSendTask();
    }
  }

  event void RequestSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS){
    }
    else{
      atomic
      if (msg == dataQueue[dataOut])
      {
        if (++dataOut >= LOST_QUEUE_LEN)
          dataOut = 0;
        if (dataFull)
          dataFull = FALSE;
      }
    }
    post dataSendTask();
  }

  event message_t* ResponseReceive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(response_msg_t) && lost_number > 0) {
      response_msg_t *rpkt = (response_msg_t*)payload;
      if (rpkt->nodeId == COMPUTE1_ID) {
        uint8_t i;
        atomic{
          for (i = 0; i < LOST_QUEUE_LEN; i++) {
            if (lost_data[i] == rpkt->sequence_number) {
              present_data = rpkt->random_integer;
              dataSortTask();
              lost_data[i] = 0;
              lost_number--;
              break;
            }
          }
        }
      }
    }
    return msg;
  }

  void quick_sort(uint32_t s[], uint32_t l, uint32_t r)  
  {  
    uint32_t i, j, x;  
    if (l < r)  
    {  
      i = l;  
      j = r;  
      x = s[i];  
      while (i < j)  
      {  
        while(i < j && s[j] > x)   
          j--;
        if(i < j)   
          s[i++] = s[j];  
        while(i < j && s[i] < x)   
          i++;
        if(i < j)   
          s[j--] = s[i];
      }
      s[i] = x;  
      quick_sort(s, l, i-1);
      quick_sort(s, i+1, r);  
    }  
  }
}
