#include "Timer.h"
#include "SensirionSht11.h"
#include "wsnMsg.h"

module Sense2C
{
  uses {

    interface Boot;
    interface Packet;
    interface Leds;
    interface AMSend;
    interface Receive;
    interface PacketAcknowledgements as Ack1;
    interface SplitControl as AMControl;
    interface Timer<TMilli> as TimerCollect;
    interface Read<uint16_t> as readTemp;
    interface Read<uint16_t> as readHumidity;
    interface Read<uint16_t> as readPhoto;
  }
}
implementation
{

   enum {
      DATA_QUEUE_LEN = 12,
    };
    message_t  dataQueueBufs[DATA_QUEUE_LEN];
    message_t  * ONE_NOK dataQueue[DATA_QUEUE_LEN];
    uint8_t    dataIn, dataOut;
    bool       dataBusy, dataFull;

  // sampling frequency in binary milliseconds
  #define SAMPLING_FREQUENCY 100
  bool busy = FALSE;
  message_t pkt;
  sample_msg_t rawData;
  uint16_t id = 0;
 
  task void dataSendTask();  

  event void Boot.booted() {
    uint8_t i;

    for (i = 0; i < DATA_QUEUE_LEN; i++)
      dataQueue[i] = &dataQueueBufs[i];
    dataIn = dataOut = 0;
    dataBusy = FALSE;
    dataFull = FALSE;

    rawData.nodeId = TOS_NODE_ID;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    if (err == SUCCESS){
      call TimerCollect.startPeriodic(SAMPLING_FREQUENCY);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err){
  }

  event void TimerCollect.fired() 
  {
    call readTemp.read();
    call readHumidity.read();
    call readPhoto.read();

    //send the message
   if (!dataFull){
      
      //set the data
      sample_msg_t *spkt = (sample_msg_t*)(call Packet.getPayload(dataQueue[dataIn],sizeof(sample_msg_t)));	
      id++;
      spkt->head = SMP_HEAD;
      spkt->temp = rawData.temp;
      spkt->humidity = rawData.humidity;
      spkt->photo = rawData.photo;
      spkt->nodeId = rawData.nodeId;
      spkt->seqNo = id;
      spkt->time = call TimerCollect.getNow();

      if (++dataIn >= DATA_QUEUE_LEN)
	 dataIn = 0;
      if (dataIn == dataOut)
	 dataFull = TRUE;
      if (!dataBusy){
	 post dataSendTask(); //send the mseeage
	 dataBusy = TRUE;
      }
    }
  }

  event void readTemp.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
      rawData.temp = data;     
    }
  }
  event void readHumidity.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
      rawData.humidity = data;
    }
  }
  event void readPhoto.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
      rawData.photo = data;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(frequency_msg_t)) {
      frequency_msg_t *fpkt = (frequency_msg_t*)payload;

      // check if the data is from the right place
      if(fpkt->head == FEQ_HEAD){
      	call TimerCollect.stop();
      	call TimerCollect.startPeriodic(fpkt->frequency);
      	call Leds.led2Toggle();
      }
    }
    return msg;
  }

  task void dataSendTask() {
    atomic
      if (dataIn == dataOut && !dataFull)
	{
	  dataBusy = FALSE;
	  return;
	}
    call Ack1.requestAck(dataQueue[dataOut]);
    if (call AMSend.send(MIDDLE_NODE_ID, dataQueue[dataOut], sizeof(sample_msg_t)) == SUCCESS)    {
    }
    else
      {
	post dataSendTask();
      }
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS){
    }
    else
      atomic
	if (msg == dataQueue[dataOut])
	  {
            if(call Ack1.wasAcked(msg) == TRUE){
	      if (++dataOut >= DATA_QUEUE_LEN)
	        dataOut = 0;
	      if (dataFull)
	        dataFull = FALSE;
            }
	  }
    
    post dataSendTask();
  }
}
