/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 01/30/2012
* Description        : Main program body
*******************************************************************************/

/*******************************************************************************
* PAL timing Horizontal
* H-sync         4,70uS
* Front porch    1,65uS
* Active video  51,95uS
* Back porch     5,70uS
* Line total     64,0uS
*
* |                64.00uS                   |
* |4,70|1,65|          51,95uS          |5,70|
*
*            ---------------------------
*           |                           |
*           |                           |
*           |                           |
*       ----                             ----
* |    |                                     |
* -----                                      ----
*
* Vertical
* V-sync        0,576mS (9 lines)
* Frame         20mS (312,5 lines)
* Video signal  288 lines
*******************************************************************************/

/*******************************************************************************
* Port pins used
*
* Video out
* PA1   H-Sync and V-Sync
* PA5   Dot clock SPI1_SCK (NC)
* PA7   Video out SPI1_MOSI
* RS232
* PA9   USART1 Tx
* PA10  USART1 Rx
* Keyboard
* PA8   Keyboard clock in
* PA11  Keyboard data in
* Leds
* PC08  Led
* PC09  Led
* User button
* PA1   User button
*******************************************************************************/

/*******************************************************************************
* Video output
*                  330
* PA1     O-------[  ]---o---------O  Video output
*                  1k0   |
* PA7     O-------[  ]---o
*                        |
*                       ---
*                       | |  82
*                       ---
*                        |
* GND     O--------------o---------O  GND
* 
*******************************************************************************/

/*******************************************************************************
* Keyboard connector 5 pin female DIN
*        2
*        o
*   4 o    o 5
*   1 o    o 3
* 
* Pin 1   CLK     Clock signal
* Pin 2   DATA    Data
* Pin 3   N/C     Not connected. Reset on older keyboards
* Pin 4   GND     Ground
* Pin 5   VCC     +5V DC
*******************************************************************************/

/*******************************************************************************
* Keyboard connector 6 pin female mini DIN
*
*   5 o    o 6
*   3 o    o 4
*    1 o o 2 
*
* Pin 1   DATA    Data
* Pin 2   N/C     Not connected.
* Pin 3   GND     Ground
* Pin 4   VCC     +5V DC
* Pin 5   CLK     Clock signal
* Pin 6   N/C     Not connected.
*******************************************************************************/

#define TOP_MARGIN          30  // Number of lines before video signal starts
#define SCREEN_WIDTH        40  // 40 characters on each line.
#define SCREEN_HEIGHT       25  // 25 lines.
#define TILE_WIDTH          8   // Width of a character tile.
#define TILE_HEIGHT         10  // Height of a character tile.

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"
#include "Font8x10.h"

/* Private variables ---------------------------------------------------------*/
ErrorStatus HSEStartUpStatus;
NVIC_InitTypeDef NVIC_InitStructure;
TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
SPI_InitTypeDef SPI_InitStructure;
DMA_InitTypeDef DMA_InitStructure;
USART_InitTypeDef USART_InitStructure;
EXTI_InitTypeDef EXTI_InitStructure;
vu16 LineCount;
vu16 FrameCount;
vu8 ScreenChars[SCREEN_HEIGHT][SCREEN_WIDTH];
vu8 PixelBuff[SCREEN_WIDTH+2];

vu8 rs232buff[256];
vu8 rs232tail;
vu8 rs232head;

static u8 tmpscancode = 0;
static u8 scancode = 0;
static u8 bitcount = 11;

static u8 cx;
static u8 cy;
static u8 showcursor;

//const char msg[]={"ABC\0"};

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void TIM3_Configuration(void);
void TIM4_Configuration(void);
void SPI_Configuration(void);
void USART_Configuration(u16 Baud);
void EXTI_Configuration(void);
void MakeVideoLine(void);
void decode(u8 scancode);
void video_show_cursor();
void video_hide_cursor();
void video_scrollup();
void video_cls();
void video_cfwd();
void video_lfwd();
void video_lf();
void video_putc(char c);
void video_puts(char *str);
void video_puthex(u8 n);
void rs232_putc(char c);
void rs232_puts(char *str);
void * memmove(void *dest, void *source, u32 count);
void * memset(void *dest, u32 c, u32 count); 
static void CURSOR_INVERT() __attribute__((noinline));

/* Private functions ---------------------------------------------------------*/

/*******************************************************************************
* Function Name  : main
* Description    : Main program
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
int main(void)
{
  u16 x,y;
  u8 c;
  y=0;
  c=0;
  while (y<SCREEN_HEIGHT)
  {
    x=0;
    while (x<SCREEN_WIDTH)
    {
      ScreenChars[y][x]=c;
      c++;
      x++;
    }
    y++;
  }
  /* System clocks configuration ---------------------------------------------*/
  RCC_Configuration();
  /* NVIC configuration ------------------------------------------------------*/
  NVIC_Configuration();
  /* SPI configuration -------------------------------------------------------*/
  SPI_Configuration();
  /* USART configuration -----------------------------------------------------*/
  USART_Configuration(4800);
  /* GPIO configuration ------------------------------------------------------*/
  GPIO_Configuration();
  /* TIM3 configuration ------------------------------------------------------*/
  TIM3_Configuration();
  /* TIM4 configuration ------------------------------------------------------*/
  TIM4_Configuration();
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  video_show_cursor();

  /* Wait 200 frames */
  y=0;
  while (y<200)
  {
    x=FrameCount;
    while (x==FrameCount)
    {
    }
    y++;
  }
  video_cls();

  // /* Switch to NMEA protocol at 4800,8,N,1 */
  // rs232_puts("$PSRF100,1,4800,8,1,0*0E\r\n\0");
  /* Switch to NMEA protocol at 38400,8,N,1 */
  // rs232_puts("$PSRF100,1,38400,8,1,0*3D\r\n\0");
  // USART_Configuration(38400);
  // /* Disable GLL message */
  // rs232_puts("$PSRF103,01,00,00,01*25\r\n\0");
  // /* Disable GSA message */
  // rs232_puts("$PSRF103,02,00,00,01*26\r\n\0");
  // /* Disable GSV message */
  // rs232_puts("$PSRF103,03,00,00,01*27\r\n\0");
  // /* Disable RMC message */
  // rs232_puts("$PSRF103,04,00,00,01*20\r\n\0");
  // /* Disable VTG message */
  // rs232_puts("$PSRF103,05,00,00,01*21\r\n\0");
  /* Wait 200 frames */
  y=0;
  while (y<200)
  {
    x=FrameCount;
    while (x==FrameCount)
    {
    }
    y++;
  }
  rs232tail=rs232head;
  video_cls();

  while (1)
  {
    while (rs232tail!=rs232head)
    {
      c=rs232buff[rs232tail++];
      video_putc(c);
    }
    // if ((FrameCount & 31)==0)
    // {
      // /* Query RMC message */
      // rs232_puts("$PSRF103,04,01,00,01*21\r\n\0");
      // /* Wait until frame changed */
      // x=FrameCount;
      // while (x==FrameCount)
      // {
      // }
    // }
  }
}

static void CURSOR_INVERT()
{
  ScreenChars[cy][cx] ^= showcursor;
}

static void _video_scrollup()
{
  memmove(&ScreenChars[0],&ScreenChars[1], (SCREEN_HEIGHT-1)*SCREEN_WIDTH);
  memset(&ScreenChars[SCREEN_HEIGHT-1], 0, SCREEN_WIDTH);
}

static void _video_lfwd()
{
  cx = 0;
  if (++cy > SCREEN_HEIGHT-1)
  {
    cy = SCREEN_HEIGHT-1;
    _video_scrollup();
  }
}

static inline void _video_cfwd()
{
  if (++cx > SCREEN_WIDTH-1)
    _video_lfwd();
}

static inline void _video_putc(char c)
{
  /* If the last character printed exceeded the right boundary,
   * we have to go to a new line. */
  if (cx >= SCREEN_WIDTH) _video_lfwd();

  if (c == '\r') cx = 0;
  else if (c == '\n') _video_lfwd();
  else
  {
    ScreenChars[cy][cx] = c;
    _video_cfwd();
  }
}

/*******************************************************************************
* Function Name  : video_show_cursor
* Description    : This function shows the cursor
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_show_cursor()
{
  if (!showcursor)
  {
    showcursor = 0x80;
    CURSOR_INVERT();
  }
}

/*******************************************************************************
* Function Name  : video_hide_cursor
* Description    : This function hides the cursor
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_hide_cursor()
{
  if (showcursor)
  {
    CURSOR_INVERT();
    showcursor = 0;
  }
}

/*******************************************************************************
* Function Name  : video_scrollup
* Description    : This function scrolls the screen up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_scrollup()
{
  CURSOR_INVERT();
  _video_scrollup();
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_cls
* Description    : This function clears the screen and homes the cursor
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_cls()
{
  CURSOR_INVERT();
  memset(&ScreenChars, 0, SCREEN_HEIGHT*SCREEN_WIDTH);
  cx=0;
  cy=0;
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_cfwd
* Description    : This function 
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_cfwd()
{
  CURSOR_INVERT();
  _video_cfwd();
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_lfwd
* Description    : This function handles a crlf
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_lfwd()
{
  CURSOR_INVERT();
  cx = 0;
  if (++cy > SCREEN_HEIGHT-1)
  {
    cy = SCREEN_HEIGHT-1;
    _video_scrollup();
  }
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_lf
* Description    : This function handles a lf
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_lf()
{
  CURSOR_INVERT();
  if (++cy > SCREEN_HEIGHT-1)
  {
    cy = SCREEN_HEIGHT-1;
    _video_scrollup();
  }
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_putc
* Description    : This function prints a character
* Input          : Character
* Output         : None
* Return         : None
*******************************************************************************/
void video_putc(char c)
{
  CURSOR_INVERT();
  _video_putc(c);
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_puts
* Description    : This function prints a zero terminated string
* Input          : Zero terminated string
* Output         : None
* Return         : None
*******************************************************************************/
void video_puts(char *str)
{
  /* Characters are interpreted and printed one at a time. */
  char c;
  CURSOR_INVERT();
  while ((c = *str++))
    _video_putc(c);
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_puthex
* Description    : This function prints a byte as hex
* Input          : Byte
* Output         : None
* Return         : None
*******************************************************************************/
void video_puthex(u8 n)
{
	static char hexchars[] = "0123456789ABCDEF";
	char hexstr[5];
	hexstr[0] = hexchars[(n >> 4) & 0xF];
	hexstr[1] = hexchars[n & 0xF];
	hexstr[2] = '\r';
	hexstr[3] = '\n';
	hexstr[4] = '\0';
  video_puts(hexstr);
}

/*******************************************************************************
* Function Name  : rs232_putc
* Description    : This function transmits a character
* Input          : Character
* Output         : None
* Return         : None
*******************************************************************************/
void rs232_putc(char c)
{
  /* Wait until transmit register empty*/
  while((USART1->SR & USART_FLAG_TXE) == 0);          
  /* Transmit Data */
  USART1->DR = (u16)c;
}

/*******************************************************************************
* Function Name  : rs232_puts
* Description    : This function transmits a zero terminated string
* Input          : Zero terminated string
* Output         : None
* Return         : None
*******************************************************************************/
void rs232_puts(char *str)
{
  char c;
  /* Characters are transmitted one at a time. */
  while ((c = *str++))
    rs232_putc(c);
}

/*******************************************************************************
* Function Name  : TIM3_IRQHandler
* Description    : This function handles TIM3 global interrupt request.
*                  An interrupt is generated for each horizontal line (64uS).
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_IRQHandler(void)
{
  u16 i,j,k;
  /* Clear the IT pending Bit */
  TIM3->SR=(u16)~TIM_IT_Update;
  /* TIM4 is used to time the H-Sync (4,70uS) */
  /* Reset TIM4 count */
  TIM4->CNT=0;
  /* Enable TIM4 */
  TIM4->CR1=1;
  /* H-Sync or V-Sync low */
  GPIOA->BRR=(u16)GPIO_Pin_1;
  if (LineCount>=TOP_MARGIN && LineCount<SCREEN_HEIGHT*TILE_HEIGHT+TOP_MARGIN)
  {
    /* Make a video line. Since the SPI operates in halfword mode
       odd character first then even character stored in pixel buffer. */
    j=k=LineCount-TOP_MARGIN;
    j=j/TILE_HEIGHT;
    k=k-j*TILE_HEIGHT;
    i=0;
    while (i<SCREEN_WIDTH)
    {
      PixelBuff[i]=Font8x10[ScreenChars[j][i+1]][k];
      PixelBuff[i+1]=Font8x10[ScreenChars[j][i]][k];
      i+=2;
    }
  }
}

/*******************************************************************************
* Function Name  : TIM4_IRQHandler
* Description    : This function handles TIM4 global interrupt request.
*                  An interrupt is generated after 4,70uS for each horizontal line.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM4_IRQHandler(void)
{
  u32 tmp;
  /* Disable TIM4 */
  TIM4->CR1=0;
  /* Clear the IT pending Bit */
  TIM4->SR=(u16)~TIM_IT_Update;
  if (LineCount<303)
  {
    /* H-Sync high */
    GPIOA->BSRR=(u16)GPIO_Pin_1;
    if (LineCount>=TOP_MARGIN && LineCount<SCREEN_HEIGHT*TILE_HEIGHT+TOP_MARGIN)
    {
      /* The time it takes to init the DMA and run the loop is the Front porch */
      tmp=0;
      while (tmp<20)
      {
        tmp++;
      }
      /* Set up the DMA to keep the SPI port fed from the pixelbuffer. */
      /* Disable the selected DMA1 Channel3 */
      DMA1_Channel3->CCR &= (u32)0xFFFFFFFE;
      /* Reset DMA1 Channel3 control register */
      DMA1_Channel3->CCR  = 0;
      /* Reset interrupt pending bits for DMA1 Channel3 */
      DMA1->IFCR |= (u32)0x00000F00;

      DMA1_Channel3->CCR = (u32)DMA_DIR_PeripheralDST | DMA_Mode_Normal |
                                DMA_PeripheralInc_Disable | DMA_MemoryInc_Enable |
                                DMA_PeripheralDataSize_HalfWord | DMA_MemoryDataSize_HalfWord |
                                DMA_Priority_VeryHigh | DMA_M2M_Disable;
      /* Write to DMA1 Channel3 CNDTR */
      /* Add 1 halfword to ensure MOSI is low when transfer is done. */
      DMA1_Channel3->CNDTR = (u32)SCREEN_WIDTH/2+1;
      /* Write to DMA1 Channel3 CPAR */
      DMA1_Channel3->CPAR = (u32)0x4001300C;
      /* Write to DMA1 Channel3 CMAR */
      DMA1_Channel3->CMAR = (u32)PixelBuff;
      /* Enable DMA1 Channel3 */
      DMA1_Channel3->CCR |= (u32)0x00000001;
    }
  }
  else if (LineCount==313)
  {
    /* V-Sync high after 313-303=10 lines) */
    GPIOA->BSRR=(u16)GPIO_Pin_1;
    FrameCount++;
    LineCount=0xffff;
  }
  LineCount++;
}

/*******************************************************************************
* Function Name  : USART1_IRQHandler
* Description    : This function handles USART1 global interrupt request.
*                  An interrupt is generated when a character is recieved.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART1_IRQHandler(void)
{
  rs232buff[rs232head++]=USART1->DR;
  USART1->SR = (u16)~USART_FLAG_RXNE;
}

/*******************************************************************************
* Function Name  : EXTI9_5_IRQHandler
* Description    : This function handles External lines 9 to 5 interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void EXTI9_5_IRQHandler(void)
{
	//figure out what the keyboard is sending us
  EXTI->PR = EXTI_Line8;
	--bitcount;
	if (bitcount >= 2 && bitcount <= 9)
	{
		tmpscancode >>= 1;
		if (GPIOA->IDR & GPIO_Pin_11)
			tmpscancode |= 0x80;
	}
	else if (bitcount == 0)
	{
    scancode=tmpscancode;
		bitcount = 11;
	}
}

/*******************************************************************************
* Function Name  : RCC_Configuration
* Description    : Configures the different system clocks.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void RCC_Configuration(void)
{
  /* RCC system reset(for debug purpose) */
  RCC_DeInit();
  /* Enable HSE */
  RCC_HSEConfig(RCC_HSE_ON);
  /* Wait till HSE is ready */
  HSEStartUpStatus = RCC_WaitForHSEStartUp();
  if(HSEStartUpStatus == SUCCESS)
  {
    /* Enable Prefetch Buffer */
    FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);
    /* Flash 2 wait state */
    FLASH_SetLatency(FLASH_Latency_0);
    /* HCLK = SYSCLK */
    RCC_HCLKConfig(RCC_SYSCLK_Div1); 
    /* PCLK2 = HCLK */
    RCC_PCLK2Config(RCC_HCLK_Div1); 
    /* PCLK1 = HCLK */
    RCC_PCLK1Config(RCC_HCLK_Div1);
    /* ADCCLK = PCLK2/2 */
    RCC_ADCCLKConfig(RCC_PCLK2_Div2);
    /* PLLCLK = 8MHz * 7 = 56 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_7);
    /* Enable PLL */ 
    RCC_PLLCmd(ENABLE);
    /* Wait till PLL is ready */
    while(RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET)
    {
    }
    /* Select PLL as system clock source */
    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);
    /* Wait till PLL is used as system clock source */
    while(RCC_GetSYSCLKSource() != 0x08)
    {
    }
  }
  /* Enable peripheral clocks ------------------------------------------------*/
  /* Enable DMA1 clock */
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1 , ENABLE);	
  /* Enable GPIOA, GPIOC, SPI1 and USART1 clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOC |
                         RCC_APB2Periph_SPI1 | RCC_APB2Periph_USART1, ENABLE);
  /* Enable TIM3 and TIM4 clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4, ENABLE);
}

/*******************************************************************************
* Function Name  : GPIO_Configuration
* Description    : Configures the different GPIO ports.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void GPIO_Configuration(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* Configure PA1 as outputs H-Sync and V-Sync*/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* H-Sync and V-Sync signal High */
  GPIO_SetBits(GPIOA,GPIO_Pin_1);
	/* GPIOA Configuration:SPI1_MOSI and SPI1_SCK as alternate function push-pull */
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_5 ;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PA9 USART1 Tx as alternate function push-pull */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PA10 USART1 Rx as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Setting up for keyboard pin change interrupts. */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 | GPIO_Pin_11;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect exti */
	GPIO_EXTILineConfig(GPIO_PortSourceGPIOA, GPIO_PinSource8 );
}

/*******************************************************************************
* Function Name  : NVIC_Configuration
* Description    : Configures Vector Table base location.
*                  Configures interrupts.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void NVIC_Configuration(void)
{
  /* Set the Vector Table base location at 0x08000000 */ 
  NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0);   
  /* Enable the TIM3 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM4 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM4_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
	/* Enable USART interrupt */
	NVIC_InitStructure.NVIC_IRQChannel = USART1_IRQChannel;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);
	/* Enable the EXTI9_5 Interrupt for keyboard transmissions */
	NVIC_InitStructure.NVIC_IRQChannel	= EXTI9_5_IRQChannel;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority	= 2;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
	NVIC_InitStructure.NVIC_IRQChannelCmd	= ENABLE;
	NVIC_Init(&NVIC_InitStructure);
}

/*******************************************************************************
* Function Name  : TIM3_Configuration
* Description    : Configures TIM3 to count up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_Configuration(void)
{
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 56*64;                   // 64uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  /* Enable TIM3 Update interrupt */
  TIM_ClearITPendingBit(TIM3,TIM_IT_Update);
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : TIM4_Configuration
* Description    : Configures TIM4 to count up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM4_Configuration(void)
{
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 264;                   // 4,70uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM4, &TIM_TimeBaseStructure);
  /* Enable TIM4 Update interrupt */
  TIM_ClearITPendingBit(TIM4,TIM_IT_Update);
  TIM_ITConfig(TIM4, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : SPI_Configuration
* Description    : Configures SPI1 to output video signal
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SPI_Configuration(void)
{
	//Set up SPI port.  This acts as a pixel buffer.
	SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Tx;
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_2Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_8;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
	SPI_Init(SPI1, &SPI_InitStructure);
	SPI_Cmd(SPI1, ENABLE);
	SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Tx, ENABLE);
}

/*******************************************************************************
* Function Name  : USART_Configuration
* Description    : Configures USART1 Rx and Tx
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART_Configuration(u16 Baud)
{
  /* USART1 configured as follow:
        - BaudRate = 4800 baud  
        - Word Length = 8 Bits
        - One Stop Bit
        - No parity
        - Hardware flow control disabled
        - Receive and transmit enabled
  */
  USART_InitStructure.USART_BaudRate = Baud;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART1, &USART_InitStructure);
  /* Enable the USART Receive interrupt: this interrupt is generated when the 
     USART1 receive data register is not empty */
  USART_ITConfig(USART1, USART_IT_RXNE, ENABLE);
  /* Enable the USART2 */
  USART_Cmd(USART1, ENABLE);
}

/*******************************************************************************
* Function Name  : EXTI_Configuration
* Description    : Configures EXTI to generate interrupt on rising edge on PA8
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void EXTI_Configuration(void)
{
	/* Enable an interrupt on EXTI line 8 rising */
	EXTI_InitStructure.EXTI_Line = EXTI_Line8;
	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising;
	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
	EXTI_Init(&EXTI_InitStructure);
}

/*****END OF FILE****/
