#include "data.h"

configuration ReceiverAppC {
}
implementation {
	components MainC, LedsC;
	components ReceiverC as App;
	components ActiveMessageC;
	components new AMSenderC(AM_RESPONSE_MSG);
	components new AMReceiverC(AM_REQUEST_MSG) as Receiver0;
	components new AMReceiverC(AM_DATA_MSG) as Receiver1;

	App.Leds -> LedsC;
	App.Boot -> MainC;
	App.Packet -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSender -> AMSenderC;
	App.DataReceive -> Receiver1;
	App.RequestReceive -> Receiver0;
	App.Ack -> AMSenderC;
}