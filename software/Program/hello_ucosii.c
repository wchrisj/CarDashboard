/*
 * How the triangle works
 * 				A
 *
 * 		BA				AC
 *
 *
 * B			BC			C
 *
 *https://www.mathsisfun.com/algebra/trig-solving-sss-triangles.html
 */
#include <stdio.h>
#include "includes.h"
#include <math.h>

#define ledA_center (int*)0x00041060
#define ledB_center (int*)0x00041050
#define ledC_center (int*)0x00041040
#define leds 		(int*)0x00041030
#define PS2_loc		*(int *) 0x41020

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    find_leds_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define FIND_LEDS_PRIORITY      		1

/* Definition of variables */
int triangle[3][2];			//0=a 1=b 2=c [0]=x [1]=y
int triangle_sides[3];		//0=BA 1=AC 2=BC
double triangle_angles[3];	//0=a 1=b 2=c

/* Skeleton functions */
int calc_side(int x1, int x2, int y1, int y2);
double calc_angle(int s1, int s2, int s3);

/* Prints "Hello World" and sleeps for three seconds */
void find_leds(void* pdata)
{
	printf("Gestart");
	*leds = 0xFFFF;
  while (1)
  { 
	int a = *ledA_center;
	int xPos_a = a % 320;
	int yPos_a = (a-xPos_a)/320;
	triangle[0][0] = xPos_a;
	triangle[0][1] = yPos_a;

	int b = *ledB_center;
	int xPos_b = b % 320;
	int yPos_b = (b-xPos_b)/320;
	triangle[1][0] = xPos_b;
	triangle[1][1] = yPos_b;

	int c = *ledC_center;
	int xPos_c = c % 320;
	int yPos_c = (c-xPos_c)/320;
	triangle[2][0] = xPos_c;
	triangle[2][1] = yPos_c;

	//BA
	triangle_sides[0] = calc_side(triangle[1][0],triangle[0][0],triangle[1][1],triangle[0][1]);
	//AC
	triangle_sides[1] = calc_side(triangle[0][0],triangle[2][0],triangle[0][1],triangle[2][1]);
	//BC
	triangle_sides[2] = calc_side(triangle[1][0],triangle[2][0],triangle[1][1],triangle[2][1]);

	//A
	triangle_angles[0] = calc_angle(triangle_sides[0], triangle_sides[1], triangle_sides[2]);
	//B
	triangle_angles[1] = calc_angle(triangle_sides[0], triangle_sides[2], triangle_sides[1]);
	//C
	triangle_angles[2] = calc_angle(triangle_sides[1], triangle_sides[2], triangle_sides[0]);
	double difference = triangle_angles[1] - triangle_angles[2];
	printf("Lengths\n");
    printf("BA: %i\n", triangle_sides[0]);
    printf("AC: %i\n", triangle_sides[1]);
    printf("BC: %i\n", triangle_sides[2]);
    printf("Angles\n");
    printf("A: %f\n", triangle_angles[0]);
    printf("B: %f\n", triangle_angles[1]);
    printf("C: %f\n", triangle_angles[2]);
    printf("Difference: %f\n", difference);
    printf("---------------\n");

    if(difference == 0) {
    	*leds = 256;
    	PS2_loc = 0;
    } else if (difference < 0.02 && difference > 0){
    	*leds = 512;
    	PS2_loc = 1;
    } else if (difference < 0.04 && difference > 0.02) {
    	*leds = 1536;
    	PS2_loc = 3;
    } else if (difference < 0.06 && difference > 0.04) {
    	*leds = 3584;
    	PS2_loc = 5;
    } else if (difference < 0.08 && difference > 0.06) {
    	*leds = 7680;
    	PS2_loc = 7;
    } else if (difference < 0.10 && difference > 0.08) {
    	*leds = 15872;
    	PS2_loc = 9;
    } else if (difference < 0.12 && difference > 0.10) {
    	*leds = 32256;
    	PS2_loc = 11;
    } else if (difference < 0.14 && difference > 0.12) {
    	*leds = 65024;
    	PS2_loc = 13;
    } else if (difference < 0.16 && difference > 0.14) {
    	*leds = 130560;
    	PS2_loc = 15;
    } else if (difference > -0.02 && difference < 0) {
    	*leds = 128;
    	PS2_loc = -1;
    } else if (difference > -0.04 && difference < -0.02) {
    	*leds = 192;
    	PS2_loc = -3;
    } else if (difference > -0.06 && difference < -0.04) {
    	*leds = 224;
    	PS2_loc = -5;
    } else if (difference > -0.08 && difference < -0.06) {
    	*leds = 240;
    	PS2_loc = -7;
    } else if (difference > -0.10 && difference < -0.08) {
    	*leds = 248;
    	PS2_loc = -9;
    } else if (difference > -0.12 && difference < -0.10) {
    	*leds = 252;
    	PS2_loc = -11;
    } else if (difference > -0.14 && difference < -0.12) {
    	*leds = 254;
    	PS2_loc = -13;
    } else if (difference > -0.16 && difference < -0.14) {
    	*leds = 255;
    	PS2_loc = -15;
    }

    OSTimeDlyHMSM(0, 0, 0, 5);
  }
}

int calc_side(int x1, int x2, int y1, int y2)
{
	int x_diff = x1 - x2;
	int y_diff = y1 - y2;
	if(y_diff < 0)
		y_diff = (y_diff)*(-1);
	if(x_diff < 0)
		x_diff = (x_diff)*(-1);
	int powed = pow(y_diff, 2) + pow(x_diff, 2);
	if(powed < 0)
		powed = (powed)*(-1);
	return sqrt(powed);
}

double calc_angle(int s1, int s2, int s3)
{
	return cos((pow(s1, 2)+pow(s2, 2)-pow(s3, 2))/(2*s1*s2));
}

int main(void)
{
  
  OSTaskCreateExt(find_leds,
                  NULL,
                  (void *)&find_leds_stk[TASK_STACKSIZE-1],
                  FIND_LEDS_PRIORITY,
                  FIND_LEDS_PRIORITY,
                  find_leds_stk,
                  TASK_STACKSIZE,
                  NULL,
                  0);

  OSStart();
  return 0;
}
