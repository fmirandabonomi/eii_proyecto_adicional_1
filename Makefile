prefijo        ?= sim
dir_fuentes    ?= src
dir_resultados ?= resultados
dir_trabajo    ?= build

fuentes    := $(abspath $(dir_fuentes))
resultados := $(abspath $(dir_resultados))
trabajo    := $(abspath $(dir_trabajo))
arch_cf    := $(trabajo)/work-obj08.cf
sims 	   := $(basename $(notdir $(wildcard $(fuentes)/$(prefijo)_*.vhd)))
ops 	   := --std=08

blancos := $(patsubst $(prefijo)_%,%,$(sims))

arch_fuente = $(wildcard $(fuentes)/*.vhd)

arch_producidos = $(wildcard $(resultados)/*.*) $(wildcard $(trabajo)/*.*)

.PHONY: all clean $(blancos)

help:
	@echo -e "Uso:\n\n"\
  "   make nuevo_<entidad> : crea desde plantilla la entidad <entidad> en el archivo src/<entidad>.vhd y una simulación para la misma en src/sim_<entidad>.vhd\n"\
	"    make <entidad> : ejecuta la simulación definida en sim_<entidad>.vhd\n"\
	"    make clean : borra todos los archivos generados\n"\
	"    make diagrama..<entidad> : genera un diagrama para la entidad <entidad> [requiere netlistsvg]\n"\
	"    make sintesis..<entidad> : realiza la síntesis lógica para FPGA hx4k de la entidad <entidad>. Requiere el archivo de especificación de pines <entidad>.pcf\n"\
	"    make carga..<entidad> : carga en la FPGA hx4k el bitmap generado por make sintesis..<entidad>.\n\n"

all : $(blancos)

ifeq ($(arch_producidos),)
clean :
else
clean :
	rm  $(arch_producidos)
endif

$(trabajo):
	mkdir $(trabajo)
$(resultados): | $(trabajo)
	mkdir $(resultados)
$(arch_cf): $(arch_fuente) | $(resultados)
	cd $(trabajo) && ghdl -i $(ops) $(arch_fuente)

netlistsvg = $(let nsvg,$(shell which netlistsvg),$(if $(wildcard $(nsvg).cmd),$(nsvg).cmd,$(nsvg)))

define plantilla =
$(1): $(arch_cf)
	cd $(trabajo) && ghdl -m $(ops) $(2)
	cd $(trabajo) && ghdl -r $(ops) $(2) --wave=$(resultados)/$(1).ghw

ifneq ($(netlistsvg),)
diagrama..$(1): $(arch_cf)
	cd $(trabajo) && ghdl -m $(ops) $(1)
	cd $(trabajo) && ghdl --synth $(ops) --out=verilog $(1) > $(1).v
	cd $(trabajo) && yosys -q -p "prep -top $(1) ; write_json -compat-int $(1).json" $(1).v
	cd $(trabajo) && $(netlistsvg) $(1).json -o $(resultados)/$(1).svg
else
diagrama..$(1):
	@echo Falta netlistsvg, no es posible generar diagrama
endif

sintesis..$(1): $(arch_cf) $(dir_fuentes)/$(1).pcf
	cd $(trabajo) && ghdl -m $(ops) $(1)
	cd $(trabajo) && ghdl --synth $(ops) --out=verilog $(1) > $(1).v
	cd $(trabajo) && yosys -q -p "read_verilog $(1).v ; synth_ice40 -json sintesis_$(1).json -top $(1)" -l sintesis_$(1).json.log
	cd $(trabajo) && nextpnr-ice40 --hx4k --json sintesis_$(1).json --pcf ../$(dir_fuentes)/$(1).pcf --package tq144 --asc $(1).asc --log $(1).pnr_log
	cd $(trabajo) && icepack $(1).asc ../$(dir_resultados)/$(1).bin

carga..$(1): $(dir_resultados)/$(1).bin
	cd $(resultados) && iceprog $(1).bin
endef

$(foreach blanco,$(blancos),$(eval $(call plantilla,$(blanco),$(prefijo)_$(blanco))))

define plantilla_nuevo_sim =
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.finish;

entity sim_$(1) is
end sim_$(1);

architecture sim of sim_$(1) is
  component $(1) is
    port (
      A : in  std_logic;
      B : in  std_logic;
      Y : out std_logic
    );
  end component; -- $(1)
  signal entradas : std_logic_vector (1 downto 0);
  signal salida : std_logic;
begin
  -- Dispositivo bajo prueba
  dut : $(1) port map (A=>entradas(1),B=>entradas(0),Y=>salida);

  excitaciones: process
  begin
    for i in 0 to (2**entradas'length)-1 loop
      entradas <= std_logic_vector(to_unsigned(i,entradas'length));
      wait for 1 ns;
    end loop;
    wait for 1 ns; -- Espera extra antes de salir
    finish;
  end process; -- excitaciones
end sim;
endef

define plantilla_nuevo_ent = 
library IEEE;
use IEEE.std_logic_1164.all;

entity $(1) is
  port (
    A : in  std_logic;
    B : in  std_logic;
    Y : out std_logic
  );
end $(1);

architecture arch of $(1) is
begin
  Y <= A and B;
end arch;
endef


nuevoent = $(patsubst nuevo_%,%,$@)
narchent = $(addsuffix .vhd,$(addprefix $(fuentes)/,$(nuevoent)))
narchsim = $(addsuffix .vhd,$(addprefix $(fuentes)/sim_,$(nuevoent)))
preexistente = $(nuevoent) preexistente, omitido
creado       = $(nuevoent) creado con ejemplo $(file >$(narchent),$(call plantilla_nuevo_ent,$(nuevoent)))$(file >$(narchsim),$(call plantilla_nuevo_sim,$(nuevoent)))

nuevo_%:
	echo $(if $(wildcard $(narchent) $(narchsim)),$(preexistente),$(creado))