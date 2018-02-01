#include "wsnMsg.h"
#include "SensirionSht11.h"

configuration SenseApp1C { 
} 

implementation {   
  components MainC, LedsC;
  components Sense1C as App;
  components new SensirionSht11C();
  components new HamamatsuS1087ParC();
  components new TimerMilliC() as TimerCollect;
  components ActiveMessageC;
  components new AMSenderC(AM_SAMPLE_MSG) as Sender0;
  components new AMSenderC(AM_FREQUENCY_MSG) as Sender2;
  components new AMReceiverC(AM_FREQUENCY_MSG) as Receiver0;
  components new AMReceiverC(AM_SAMPLE_MSG) as Receiver2;

  App.Boot -> MainC;
  App.TimerCollect -> TimerCollect;

  App.readTemp -> SensirionSht11C.Temperature;
  App.readHumidity -> SensirionSht11C.Humidity;
  App.readPhoto -> HamamatsuS1087ParC;

  App.Leds -> LedsC;
  App.Packet -> Sender0;
  App.AMControl -> ActiveMessageC;
  App.AMSender0 -> Sender0;
  App.AMSender2 -> Sender2;
  App.Ack0 -> Sender0;
  App.Ack2 -> Sender2;
  App.Receive0 -> Receiver0;
  App.Receive2 -> Receiver2;
}
