COMPONENT=SenseApp1C

CLEAN_EXTRA = *.class SampleMsg.java FreqMsg.java

CFLAGS += -I$(TOSDIR)/lib/T2Hack

SampleMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=SampleMsg wsnMsg.h sample_msg -o $@

FreqMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=FreqMsg wsnMsg.h frequency_msg -o $@

include $(MAKERULES)
