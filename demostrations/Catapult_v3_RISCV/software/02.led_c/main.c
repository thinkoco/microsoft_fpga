#define LED_OUT_CTRL      *((volatile unsigned int  *)( 0x10012008 ))
#define LED_OUT_VALU      *((volatile unsigned int  *)( 0x1001200C ))

int main()
{
	int i;
	LED_OUT_CTRL = 0x7;
	for(;;){
		LED_OUT_VALU = 0;
		for(i=0x170000;i>=0;i--);
		LED_OUT_VALU = 5;
		for(i=0x170000;i>=0;i--);
	}
	return 0;
}

