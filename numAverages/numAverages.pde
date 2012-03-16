// Input FFT
// original code by Marius Watz <http://www.unlekker.net>
// modified by Krister Olsson <http://www.tree-axis.com>

// Showcase for new FFT processing options in Ess v2. 
// Clicking and dragging changes FFT damping

// Created 27 May 2006

import krister.Ess.*;

import processing.serial.*;

static byte DMX_PRO_MESSAGE_START = byte(0x7E);
static byte DMX_PRO_MESSAGE_END = byte(0xE7);
static byte DMX_PRO_SEND_PACKET = byte(6);

Serial dmx;
int universeSize = 48;// lower = faster updates.. 
byte[] channelValues;

int bufferSize;
int steps;
float limitDiff;
int numAverages=16;
float myDamp=.1f;
float maxLimit,minLimit;

FFT myFFT;
AudioInput myInput;

void setup () {
  size(700,221);
  
  //frameRate( 40 );

  // start up Ess
  Ess.start(this);  

  // set up our AudioInput
  bufferSize=512;
  myInput=new AudioInput(bufferSize);

  // set up our FFT
  myFFT=new FFT(bufferSize*2);
  myFFT.equalizer(true);

  // set up our FFT normalization/dampening
  minLimit=.005;
  maxLimit=.05;
  myFFT.limits(minLimit,maxLimit);
  myFFT.damp(myDamp);
  myFFT.averages(numAverages);

  // get the number of bins per average 
  steps=bufferSize/numAverages;

  // get the distance of travel between minimum and maximum limits
  limitDiff=maxLimit-minLimit;

  frameRate(40);         

  myInput.start();
  
  
  channelValues = new byte[universeSize];

  for(int i = 0; i < universeSize; i++) {
    channelValues[i] = byte(0);
  }
  
    println(Serial.list());

  dmx = new Serial(this, Serial.list()[0], 115200);

}

void draw() {
  background(0,0,255);

  // draw the waveform 

  stroke(255,100);
  int interp=(int)max(0,(((millis()-myInput.bufferStartTime)/(float)myInput.duration)*myInput.size));

  for (int i=0;i<bufferSize;i++) {
    float left=160;
    float right=160;

    if (i+interp+1<myInput.buffer2.length) {
      left-=myInput.buffer2[i+interp]*50.0;
      right-=myInput.buffer2[i+1+interp]*50.0;
    }

    line(10+i,left,11+i,right);
  }

  noStroke();
  fill(255,128);

  // draw the spectrum

  for (int i=0; i<bufferSize; i++) {
    rect(10+i,10,1,myFFT.spectrum[i]*200);
  }

  // draw our averages
  for(int i=0; i<numAverages; i++) {
    //fill(255,128);
    //rect(10+i*steps,10,steps,myFFT.averages[i]*200);
    //fill(255);
    int index = i*3;
    //rect(10+i*steps,(int)(10+myFFT.maxAverages[i]*200),steps,1);
    setDMXChannel( index, int( myFFT.maxAverages[i] * (255/(index+1)) ) );
    //setDMXChannel( i+1, int( myFFT.maxAverages[i] * 255 ) );
    setDMXChannel( index+1, int( myFFT.maxAverages[i] * 0 ) );
    setDMXChannel( index+2, int( myFFT.maxAverages[i] * 0 ) );
    //setDMXChannel( i+2, int( myFFT.maxAverages[i] * 255 ) );
    //println( myFFT.maxAverages[i] * 255 );
    //rect(10+i*steps,10,1,200);
  }
  println("");
  
  // complete the frame around our averages
  rect(10+numAverages*steps,10,1,201);
  rect(10,10,bufferSize,1);
  rect(10,210,bufferSize,1);

  // draw the range of normalization
  rect(600,10,50,1);
  rect(600,210,50,1);

  float percent=max(0,(myFFT.max-minLimit)/limitDiff);
  
  fill(255,128);
  rect(600,(int)(11+198*percent),50,1);
  rect(600,11,50,(int)(198*percent)); 

  // draw our damper slider
  fill(255);
  rect(660,10,30,1);
  rect(660,210,30,1);
  fill(255,128);
  rect(660,(int)(11+198*myDamp),30,1);
}

void mouseDragged() {
  mousePressed(); 
}

void mousePressed() {
  // set our damper
  myDamp=mouseY/(float)height;
  if (myDamp>1) myDamp=1;
  else if(myDamp<0) myDamp=0;

  myFFT.damp(myDamp);  
}

public void audioInputData(AudioInput theInput) {
  myFFT.getSpectrum(myInput);
}


int getDMXChannel(int channel) {
  return int(channelValues[channel]);
}

void setDMXChannel(int channel, int value) {
  if(channelValues[channel] != byte(value)) {
    channelValues[channel] = byte(value);
    byte[] data = new byte[universeSize+1];

    data[0] = 0; // DMX command byte..

    for(int i = 0; i < universeSize; i++)
    {
	data[i+1] = channelValues[i];
    }
    
    dmxMessage( DMX_PRO_SEND_PACKET, data );
  }
}

void dmxMessage( byte messageType, byte[] data ) {
  byte[] message;
  int dataSize = data.length;
  message = new byte[5 + dataSize];
  
  message[0] = DMX_PRO_MESSAGE_START;
  
  message[1] = messageType;
  
  message[2] = byte(dataSize & 255);
  message[3] = byte((dataSize >> 8) & 255);
  
  // there's probably a faster way to do this...
  for(int i = 0; i < dataSize; i++) {
    message[i+4] = data[i];  
  }
  
  message[4 + dataSize] = DMX_PRO_MESSAGE_END;

  dmx.write(message);
}
