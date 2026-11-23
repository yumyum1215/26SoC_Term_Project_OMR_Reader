#include "xil_io.h"
#include "xparameters.h"

#define BUTTONS_DATA XPAR_AXI_GPIO_0_BASEADDR
#define SERVO_DATA   XPAR_AXI_SERVO_GPIO_BASEADDR
#define BUTTON_MASK  0x0FU

int main(void)
{
    u32 previous = BUTTON_MASK;
    Xil_Out32(SERVO_DATA, 0U);

    for (;;) {
        const u32 buttons = Xil_In32(BUTTONS_DATA) & BUTTON_MASK;
        const u32 pressed = previous & ~buttons;
        previous = buttons;

        /* Active-low buttons. A repeated edge writes the same position. */
        if (pressed & 0x08U) {
            Xil_Out32(SERVO_DATA, 0U);
        } else if (pressed & 0x01U) {
            Xil_Out32(SERVO_DATA, 1500U);
        } else if (pressed & 0x02U) {
            Xil_Out32(SERVO_DATA, 1400U);
        } else if (pressed & 0x04U) {
            Xil_Out32(SERVO_DATA, 1600U);
        }
    }
}
