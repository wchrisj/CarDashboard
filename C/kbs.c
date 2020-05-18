#define PS2_LOC           *(int *) 0x2040

int main(){
    PS2_LOC = -15;
    while(1){
    }

    return 0;
}
