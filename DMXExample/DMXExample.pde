import processing.serial.*;

static byte DMX_PRO_MESSAGE_START = byte(0x7E);
static byte DMX_PRO_MESSAGE_END = byte(0xE7);
static byte DMX_PRO_SEND_PACKET = byte(6);

Serial dmx;
int universeSize = 512;// lower = faster updates.. 
byte[] channelValues;

void setup() {
  size(640, 480);
  frameRate(40);
  
  channelValues = new byte[universeSize];

  for(int i = 0; i < universeSize; i++) {
    channelValues[i] = byte(0);
  }
  
    println(Serial.list());

  dmx = new Serial(this, Serial.list()[0], 115200);

}

void draw() {
  //for( int i = 0; i < 512; i++ ) {
        setDMXChannel( 2, 255 );
    setDMXChannel( 1, 255 );
  //}
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
