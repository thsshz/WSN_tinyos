#include "data.h"

module ReceiverC {
	uses {
		interface Boot;
		interface Packet;
		interface Leds;
		interface AMSend as AMSender;
		interface PacketAcknowledgements as Ack;
		interface Receive as DataReceive;
		interface Receive as RequestReceive;
		interface SplitControl as AMControl;
	}
}
implementation {
	enum {
		DATA_QUEUE_LEN = 12
	};
	uint32_t dataArray[2001] = {0};
	message_t  dataQueueBufs[DATA_QUEUE_LEN];
	message_t  * ONE_NOK dataQueue[DATA_QUEUE_LEN];
	uint8_t    dataIn, dataOut;
	bool       dataBusy, dataFull;
	bool busy = FALSE;
 	message_t pkt;
 	response_msg_t responseData;

 	task void dataSendTask();

 	event void Boot.booted() {
		uint8_t i;

		for (i = 0; i < DATA_QUEUE_LEN; i++)
			dataQueue[i] = &dataQueueBufs[i];
		dataIn = dataOut = 0;
		dataBusy = FALSE;
		dataFull = FALSE;

		responseData.nodeId = TOS_NODE_ID;
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {

		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {

	}

	event message_t* DataReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(data_msg_t)) {
			data_msg_t *dpkt = (data_msg_t*)payload;
			dataArray[dpkt->sequence_number] = dpkt->random_integer;
		}
		return msg;
	}

	event message_t* RequestReceive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(request_msg_t)) {
			request_msg_t *req_pkt = (request_msg_t*)payload;
			response_msg_t *res_pkt = (response_msg_t*)(call Packet.getPayload(dataQueue[dataIn], sizeof(response_msg_t)));

			if (req_pkt->nodeId == COMPUTE1_ID || req_pkt->nodeId == COMPUTE2_ID) {
				if (!dataFull) {
					res_pkt->nodeId = req_pkt->nodeId;
					res_pkt->sequence_number = req_pkt->sequence_number;
					res_pkt->random_integer = dataArray[req_pkt->sequence_number];
					if (++dataIn >= DATA_QUEUE_LEN)
						dataIn = 0;
					if (dataIn == dataOut)
						dataFull = TRUE;
					if (!dataBusy) {
						post dataSendTask();
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
		if (call AMSender.send(COMPUTE1_ID, dataQueue[dataOut], sizeof(response_msg_t)) == SUCCESS)    {
			call Leds.led1Toggle();
		}
		else
		{
			post dataSendTask();
		}
	}

	event void AMSender.sendDone(message_t* msg, error_t error) {
		if (error == SUCCESS) {
			atomic
			if (msg == dataQueue[dataOut]) {
					if (++dataOut >= DATA_QUEUE_LEN)
						dataOut = 0;
					if (dataFull)
						dataFull = FALSE;
			}
			post dataSendTask();
		}
	}

}