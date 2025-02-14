# Proyecto Adicional 1 - Sencillo microcontrolador RISC-V

Electrónica II para Ingeniería Electrónica. 2024

## Objetivos

- Modificar el núcleo del proyecto 10 para implementar las instrucciones lui y auipc
- Definir espacio de direcciones, mapa de memoria y bus de computadora
- Integrar en un microcontrolador el núcleo desarrollado en el proyecto 10 con un bus incluyendo además de la memoria de programa y datos, cuatro puertos de entrada y cuatro puertos de salida.
  - Utilizar para memoria las direcciones 0x00000000 a 0x7FFFFFFF
  - Utilizar para IO las direcciones 0x80000000 a 0xFFFFFFFF
  - Cada pin de entrada o salida se representa por un registro de 32 bit con alineación de palabra (el bus del proyecto 10 no permite acceso a byte ni media palabra). Un valor de 1 corresponderá al estado ALTO y un 0 al estado BAJO del pin.
  - En los pines de entrada se utilizará un sincronizador de dos flip-flop.
- Realizar la síntesis lógica y configurar una placa EDU-CIAA-FPGA con el microcontrolador desarrollado. Para ello deberás instalar OSS CAD Suite de YosysHQ

## Entregables

Repositorio git con la descripción de hardware desarrollada.
Un informe que presente lo siguiente:

Un informe con la siguiente estructura:

- *Título*
- *Autor*
- *Resumen*
- *Introducción* Presentar los conceptos de bus de computadora, espacio de direcciones y mapa de memoria. Presentar los objetivos del proyecto.
- *Desarrollo* Presentar el mapa de memoria desarrollado y un detalle de los registros de control de entrada/salida.
- *Resultados* Explicar los cambios realizados sobre el proyecto 10, el diseño del bus de computadora y el microcontrolador. Presentar los resultados de simulación y pruebas sobre hardware.
- *Conclusiones* Concluir, en base a los resultados obtenidos, sobre el cumplimiento de los objetivos.
- *Referencias*

## Programas de prueba:

### Parpadeo con retardo (para ejecutar en placa)

Código C

~~~C
#include <stdint.h>
int main(void)
{
    volatile uint32_t *const o0 = (void*)0x80000010;
    for(;;)
    {
        *o0 = ! *o0;
        for(int i=0;i<(12000000-8)/9;++i) ;
    }
}
~~~

Listado ensamblador

~~~asm
00000000 <main>:
    0:         80000737        lui x14 0x80000
    4:         001466b7        lui x13 0x146
00000008 <L3>:
    8:         01072783        lw x15 16 x14
    c:         0017b793        sltiu x15 x15 1
    10:        00f72823        sw x15 16 x14
    14:        85468793        addi x15 x13 -1964
00000018 <L2>:
    18:        fff78793        addi x15 x15 -1
    1c:        fe079ee3        bne x15 x0 -4 <L2>
    20:        fe9ff06f        jal x0 -24 <L3>
~~~

Archivo parpadeo_con_retardo.mem:

~~~hex
80000737
001466b7
01072783
0017b793
00f72823
85468793
fff78793
fe079ee3
fe9ff06f
~~~

### Parpadeo sin retardo (para ejecutar en simulador)

Código C

~~~C
#include <stdint.h>
int main(void)
{
    volatile uint32_t *const o0 = (void*)0x80000010;
    for(;;)
    {
        *o0 = ! *o0;
    }
}
~~~

Listado Ensamblador

~~~asm
00000000 <main>:
    0:         80000737        lui x14 0x80000
00000004 <L2>:
    4:         01072783        lw x15 16 x14
    8:         0017b793        sltiu x15 x15 1
    c:         00f72823        sw x15 16 x14
    10:        ff5ff06f        jal x0 -12 <L2>
~~~

Archivo parpadeo_sin_retardo.mem:

~~~hex
80000737
01072783
0017b793
00f72823
ff5ff06f
~~~