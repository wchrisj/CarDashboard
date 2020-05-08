#define PS2_FLAGS           (int *) 0x2010
#define PS2_CONTROL         (int *) 0x2020

#define PS2_DATA_OUT        (int *) 0x2040
#define PS2_DATA_IN         *(int *) 0x2030

#define LEDS                *(int *) 0x2000

#define PS2_WRITE           0
#define PS2_START           1

#define PS2_FLAG_RECEIVED   0
#define PS2_FLAG_SEND       1

void sendData(int data){
    *PS2_CONTROL |= (1 << PS2_WRITE);
    *PS2_DATA_OUT = data;
    *PS2_CONTROL |= (1 << PS2_START);
    *PS2_CONTROL = (1 << PS2_WRITE);
    // *PS2_CONTROL = 0;
    // *PS2_CONTROL &= ~(1 << PS2_START);
    for(int i = 0; i<1000; i++){}
}

unsigned char receiveData(){
    *PS2_CONTROL = 0;
    LEDS |= 0x30000;
    while(!(*PS2_FLAGS & (1 << PS2_FLAG_RECEIVED))){}
    LEDS &= 0x0;
    unsigned char data = PS2_DATA_IN;
    // *PS2_CONTROL = (1 << PS2_START); // Zet write = 0 en start = 1
    return data;
}

void moveUp(){
    sendData(0x08);
    sendData(0x00);
    sendData(0x01);
    sendData(0x00);
}

void moveDown(){
    sendData(0x28);
    sendData(0x00);
    sendData(0xFF);
}

void moveLeft(){
    sendData(0x18);
    sendData(0xFF);
    sendData(0x00);
}

void moveRight(){
    sendData(0x08);
    sendData(0x01);
    sendData(0x00);
}

int main(){
    // volatile int *LEDS = (int *)0x2000;
    // sendData(0xFF);
    LEDS = receiveData();
    // while(1){
        // *LEDS = *PS2_DATA_IN;
        // if(*PS2_FLAGS & (1 << PS2_FLAG_SEND)){
        //     LEDS |= 0xFF;
        // }
        // moveUp();
        // moveUp();
        // moveUp();
        // moveUp();
        // moveUp();
    // }

    return 0;
}
