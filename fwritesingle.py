import numpy as np 

def freq2word(frequency, clock):
	resolution = 2**32
	tuningword = int(frequency*resolution/clock)
	return "{0:032b}".format(tuningword)

def wordsplit(word):
	return int(tuningword[0:16],2), int(tuningword[16:32],2)

def cselect(dds, channel, multiplier, vcogain):
	x1 = ["0"]*8
	x1[3 - channel] = "1"

	x2 = "{0:05b}".format(multiplier)
	x3 = str(1*vcogain)
	x4 = "{0:02b}".format(dds + 1)

	x = "".join(x1) + x2 + x3 + x4

	return int(x,2)

dds = 0
channel = 0
clock = 20
multiplier = 20
frequency = 26

tuningword = freq2word(frequency, clock*multiplier)
ep02, ep01 = wordsplit(tuningword)
ep00 = cselect(dds,channel,multiplier,True)

import ok 
from time import sleep

fp = ok.FrontPanel()
print("There are {} connected device(s).".format(fp.GetDeviceCount()))


serialno = fp.GetDeviceListSerial(0)
fp.OpenBySerial(serialno)



print("Opened communications with " + fp.GetDeviceID() +'.')
x = fp.ConfigureFPGA("./dds3_ad9959.bit")


fp.SetWireInValue(0x00, ep00)
fp.SetWireInValue(0x01, ep01)
fp.SetWireInValue(0x02, ep02)
fp.UpdateWireIns()

sleep(0.001)

fp.SetWireInValue(0x00, 0)
fp.UpdateWireIns()
fp.Close()