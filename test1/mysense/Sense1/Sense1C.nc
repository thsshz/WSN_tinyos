#include "Timer.h"
#include "SensirionSht11.h"
#include "wsnMsg.h"

module Sense1C
{
  uses {
    interface Boot;
    interface Packet;
    interface Leds;
    interface AMSend as AMSender0;
    interface AMSend as AMSender2;
    interface PacketAcknowledgements as Ack0;
    interface PacketAcknowledgements as Ack2;
    interface Receive as Receive0;
    interface Receive as Receive2;
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

  //set the frequency
  event message_t* Receive0.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(frequency_msg_t)) {
      //change its frequency
      frequency_msg_t *fpkt = (frequency_msg_t*)payload;
      // check if the data is from the right place
      if(fpkt->head == FEQ_HEAD){
      	call TimerCollect.stop();
      	call TimerCollect.startPeriodic(fpkt->frequency);

      	//send the frequency change to the node 2
        call Ack2.requestAck(msg);
      	if (call AMSender2.send(RARE_NODE_ID, msg, sizeof(frequency_msg_t)) == SUCCESS)    	{
    	}
      }
    }
    return msg;
  }

  //transmit the package from node 2
  event message_t* Receive2.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(sample_msg_t)) {
      sample_msg_t *smkt = (sample_msg_t*)payload;
      // check if the data is from the right place
      if(smkt->head == SMP_HEAD && smkt->nodeId == RARE_NODE_ID){
        if(!dataFull){
          sample_msg_t *spkt = (sample_msg_t*)(call Packet.getPayload(dataQueue[dataIn],sizeof(sample_msg_t)));
          spkt->head = smkt->head;
          spkt->temp = smkt->temp;
          spkt->humidity = smkt->humidity;
          spkt->photo = smkt->photo;
          spkt->nodeId = smkt->nodeId;
          spkt->seqNo = smkt->seqNo;
          spkt->time = smkt->time;

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
    call Ack0.requestAck(dataQueue[dataOut]);
    if (call AMSender0.send(BASE_STATION_ID, dataQueue[dataOut], sizeof(sample_msg_t)) == SUCCESS)    {
    }
    else
      {
	post dataSendTask();
      }
  }

  event void AMSender0.sendDone(message_t* msg, error_t error) {
    if (error != SUCCESS){
    }
    else
      atomic
	if (msg == dataQueue[dataOut])
	  {
            if(call Ack0.wasAcked(msg) == TRUE){
              // change the queue
	      if (++dataOut >= DATA_QUEUE_LEN)
	        dataOut = 0;
	      if (dataFull)
	        dataFull = FALSE;
            }
	  }
    
    post dataSendTask();
  }

  event void AMSender2.sendDone(message_t* msg, error_t error){
     if(call Ack2.wasAcked(msg) == FALSE){
       call Ack2.requestAck(msg);
       call AMSender2.send(RARE_NODE_ID, msg, sizeof(frequency_msg_t)); 
     }
  }
}
