/* GPIO */
void gpio_set_dir(unsigned int );
void gpio_write(unsigned int );
unsigned int gpio_read(); 
void gpio_pull (unsigned char );
void gpio_im(unsigned int );

/* UART */
int uart_init(unsigned int , unsigned int );
int uart_puts(unsigned int , unsigned char *, unsigned int );
int uart_gets(unsigned int , unsigned char *, unsigned int );

/* SPI */
int spi_init(unsigned int , unsigned char , unsigned char , unsigned char );
unsigned int spi_status(unsigned int );
unsigned char spi_read(unsigned int );
int spi_write(unsigned int , unsigned char );
int spi_start(unsigned int );
int spi_end(unsigned int );

/* i2c */
int i2c_init(unsigned int , unsigned int );
int i2c_send(unsigned int , unsigned char , unsigned char );

/* PWM */
int pwm_init(unsigned int, unsigned int, unsigned int, unsigned int);
int pwm_enable(unsigned int);
int pwm_disable(unsigned int);

/* Timer */
int tmr_init(unsigned int, unsigned int , unsigned int);
int tmr_enable(unsigned int);
int tmr_disable(unsigned int);
int tmr_wait(unsigned int);
int tmr_ei(unsigned int);
int tmr_di(unsigned int);
int tmr_clrov(unsigned int);
int tmr_read(unsigned n);