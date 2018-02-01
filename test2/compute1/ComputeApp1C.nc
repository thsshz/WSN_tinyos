#include "data.h"
configuration ComputeApp1C { 
} 

implementation {   
  components MainC, LedsC;
  components Compute1C as App;
  components ActiveMessageC;
  components new AMSenderC(AM_REQUEST_MSG) as RequestSender;
  components new AMSenderC(0) as ResultSender;
  components new AMReceiverC(AM_DATA_MSG) as DataReceiver;
  components new AMReceiverC(AM_ACK_MSG) as AckReceiver;
  components new AMReceiverC(AM_RESPONSE_MSG) as ResponseReceiver;

  App.Boot -> MainC;

  App.Leds -> LedsC;
  App.Packet -> ResultSender;
  App.AMControl -> ActiveMessageC;
  App.RequestSend -> RequestSender;
  App.ResultSend -> ResultSender;
  App.RequestAck -> RequestSender;
  // App.ResultAck -> ResultSender;
  App.DataReceive -> DataReceiver;
  App.ResponseReceive -> ResponseReceiver;
  App.AckReceive -> AckReceiver;
  App.AMPacket -> ResultSender;
}
