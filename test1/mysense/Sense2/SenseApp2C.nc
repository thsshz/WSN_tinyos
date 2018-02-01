#include "wsnMsg.h"
#include "SensirionSht11.h"

configuration SenseApp2C { 
} 

implementation {   
  components MainC, LedsC;
  components Sense2C as App;
  components new SensirionSht11C();
  components new HamamatsuS1087ParC();
  components new TimerMilliC() as TimerCollect;
  components ActiveMessageC;
  components new AMSenderC(AM_SAMPLE_MSG);
  components new AMReceiverC(AM_FREQUENCY_MSG);

  App.Leds -> LedsC;
  App.Boot -> MainC;
  App.TimerCollect -> TimerCollect;

  App.readTemp -> SensirionSht11C.Temperature;
  App.readHumidity -> SensirionSht11C.Humidity;
  App.readPhoto -> HamamatsuS1087ParC;

  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.Ack1 -> AMSenderC;
}
