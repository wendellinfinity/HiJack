/**
 *
 */

/**
 * Author: Thomas Schmid
 */

module HiJackAppM
{
  uses {
      interface Boot;
      interface Leds;

      interface Timer<TMilli> as ADCTimer;

      interface Resource as UartResource;
      interface UartByte;
      interface UartStream;

      interface HiJack;
  }

  provides {
      interface Msp430UartConfigure;
  }

}
implementation
{

    uint32_t samplePeriod;
    uint8_t uartByteTx;
    uint8_t uartByteRx;
    uint8_t busy;

    msp430_uart_union_config_t uart_config = {
      {
          /* this works for 3 sample steps on the iPhone
         ubr: 0x0002, // 15000bps with 32768 clock
         umctl: 0x84, // 15000bps with 32768 clock
         ssel: 0x01,  // select ACLK
         */
          /* could work but need faster comparators. This is for iPhone 1
           * sample ber symbol, fastest possible.
           * potentially possible with ACLK if 40kHz crystal is used.
         ubr: 0x0019, // 39840bps with 1MHz clock
         umctl: 0x10, // 39840bps with 1MHz clock
         ssel: 0x02,  // select SMCLK at 1MHz?
           */
          /* for iphone 2 samples. Does not work with 32kHz...
         ubr: 0x0001, // 21845bps with 32768 clock
         umctl: 0x55, // 21848bps with 32768 clock
         ssel: 0x01,  // select ACLK at 32kHz?
         */
          /* iphone 2 samples with 1MHz clock works.
           */
         ubr: 0x002D, // 22050bps with 1MHz clock
         umctl: 0x92, // 22050bps with 1MHz clock
         ssel: 0x02,  // select SMCLK at 1MHz?
          /* iphone 3 samples with 1MHz clock works.
         ubr: 0x0044, // 14700bps with 1MHz clock
         umctl: 0x00, // 14700bps with 1MHz clock
         ssel: 0x02,  // select SMCLK at 1MHz?
           */
         pena: 0,    // parity disabled
         pev: 0,     // parity odd
         spb: 0,     // one stop bits
         clen: 1,    // character length 8 bit
         listen: 0,  // no loopback
         mm: 0,      // slave
         ckpl: 0,    // clock polarity, inactive is low, data at rising
         urxse: 0,   // rx start-edge detection disabled
         urxeie: 1,  //
         urxwie: 0,
         utxe : 1,   // enable tx module
         urxe : 1    // enable rx module
      }
    };

    async command msp430_uart_union_config_t* Msp430UartConfigure.getConfig()
    {
        // return the UART configuration, set to 300bps using the 32kHz clock
        // (ACLK)
        return &uart_config;
    }



    event void Boot.booted()
    {
        atomic
        {
            busy = 0;
        }

        call UartResource.request();
    }

    event void UartResource.granted()
    {
        call UartStream.enableReceiveInterrupt(); // enable byte rx interrupt
    }

    async event void UartStream.receivedByte( uint8_t byte)
    {
        if(!busy)
        {
            busy = 1;
            call HiJack.send(byte);
        }
    }

    event void ADCTimer.fired()
    {
    }

    async event void HiJack.sendDone( uint8_t byte, error_t error )
    {
        atomic
        {
            busy = 0;
        }
    }

    async event void HiJack.receive( uint8_t byte) {
        call UartByte.send(byte);
    }

    async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error )
    {

    }

    async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error )
    {

    }

}

