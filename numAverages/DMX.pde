/*
  Copyright (c) 2008 Andres Colubri

  This source is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This code is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  A copy of the GNU General Public License is available on the World
  Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also
  obtain it by writing to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

import processing.serial.*;

// This class encapsulates the handling of DMX messages through the Serial port.
// This first version only implements writting messages.
public class DMX
{
    // Constructor where the parent PApplet object, the string identifying the port ("COM1", "COM2", etc.),
    // the baudrate	and the number of channels are specified.
    DMX(PApplet parent, String port, int rate, int size)
    {
        serial = new Serial(parent, port, rate);
        
        universeSize = size;
        int dataSize = universeSize + 1;
        message = new byte[universeSize + 6];
        message[0] = DMX_PRO_MESSAGE_START;
        message[1] = DMX_PRO_SEND_PACKET;
        message[2] = byte(dataSize & 255);  
        message[3] = byte((dataSize >> 8) & 255);
        message[4] = 0;
        for (int i = 1; i <= universeSize; i++)
        {
            message[4 + i] = byte(0);
        }
        message[universeSize + 5] = DMX_PRO_MESSAGE_END;
    }
  
    // Writes value to the channel, if the value is different from the last written.
    void setDMXChannel(int channel, int value)
    {
        if (message[channel + 5] != byte(value))
        {
            message[channel + 5] = byte(value);
            serial.write(message);
        }
    }
    
	// Serial port to communicate with the DMX USB adapter.
    private Serial serial;
    
	// Number of channels.
    private int universeSize;
	
    // Format of the dmx message:
    // message[0] = DMX_PRO_MESSAGE_START;
    // message[1] = DMX_PRO_SEND_PACKET;
    // message[2] = byte(dataSize & 255);  
    // message[3] = byte((dataSize >> 8) & 255);
    //     message[4] = 0;
    // message[4 + 1] = value in channel 0
    // message[4 + 2] = value in channel 1
    // ...
    // message[4 + universeSize] = value in channel universeSize - 1
    // message[4 + universeSize + 1] = DMX_PRO_MESSAGE_END
    // where dataSize = universeSize + 1;  	
    private byte[] message;
    
    private byte DMX_PRO_MESSAGE_START = byte(0x7E);
    private byte DMX_PRO_MESSAGE_END = byte(0xE7);
    private byte DMX_PRO_SEND_PACKET = byte(6);    
}
