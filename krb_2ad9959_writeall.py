""" krb_2ad9959_writeall.py 
	last modified 2/2/2018 by ldm

	Write single frequencies to 3 ad9959 boards using opalkelly xem6001 board equipped
	with Xilinx Spartan-6 FPGA (XC6SLX16-2FTG256C) using the dds3_ad9959.bit bit file.

	Source files (including vhd files are in C:\Users\KRbG2\Desktop\Luigi\DDS\KRb3DDSAD9959\)
"""

channels = [
	{'name' : 'Up Leg Double Pass', 'address' : [0,0],  'frequency' : 71.35},
	{'name' : 'Up Leg Experiment', 'address' : [0,1],  'frequency' : 73.0},
	{'name' : 'Down Leg After Cavity', 'address' : [0,2],  'frequency' : 78.6},
	{'name' : 'Down Leg Experiment', 'address' : [0,3],  'frequency' : 76.6},
	{'name' : 'dds1-0', 'address' : [1,0],  'frequency' : 0},
	{'name' : 'dds1-1', 'address' : [1,1],  'frequency' : 0},
	{'name' : 'dds1-2', 'address' : [1,2],  'frequency' : 0},
	{'name' : 'dds1-3', 'address' : [1,3],  'frequency' : 0},
	{'name' : 'dds0-0', 'address' : [2,0],  'frequency' : 0},
	{'name' : 'dds0-0', 'address' : [2,1],  'frequency' : 0},
	{'name' : 'dds0-0', 'address' : [2,2],  'frequency' : 0},
	{'name' : 'dds0-0', 'address' : [2,3],  'frequency' : 0}
	]

multiplier = 20
vcogain = True
clock = 20

####################################################################################

def freq2word(frequency, clock):
	#Convert frequency in MHz to tuning word
	resolution = 2**32
	tuningword = int(frequency*resolution/clock)
	return "{0:032b}".format(tuningword)

def wordsplit(word):
	#Split tuning word for passing to fpga
	return int(tuningword[0:16],2), int(tuningword[16:32],2)

def cselect(dds, channel, multiplier, vcogain):
	#Generate words for channel selection and clock configuration
	x1 = ["0"]*8
	x1[3 - channel] = "1"
	x2 = "{0:05b}".format(multiplier)
	x3 = str(1*vcogain)
	x4 = "{0:02b}".format(dds + 1)
	x = "".join(x1) + x2 + x3 + x4
	return int(x,2)

import ok 
from time import sleep

fp = ok.FrontPanel()
print("There are {} connected OpalKelly device(s).".format(fp.GetDeviceCount()))


serialno = fp.GetDeviceListSerial(0)
fp.OpenBySerial(serialno)
print("Opened communications with " + fp.GetDeviceID() +'.')
x = fp.ConfigureFPGA("./dds3_ad9959.bit")

for k in channels:
	tuningword = freq2word(float(k['frequency']), clock*multiplier)
	ep02, ep01 = wordsplit(tuningword)
	ep00 = cselect(k['address'][0],k['address'][1],multiplier,vcogain)

	print("{0} MHz written to {1}".format(k['frequency'],k['name']))

	fp.SetWireInValue(0x00, ep00)
	fp.SetWireInValue(0x01, ep01)
	fp.SetWireInValue(0x02, ep02)
	fp.UpdateWireIns()

	sleep(0.001)

	fp.SetWireInValue(0x00, 0)
	fp.UpdateWireIns()
fp.Close()