library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package util_sim is
    -- Ejemplo de uso:
    -- ~~~
    -- estimulo : process
    --   variable aleatorio : aleatorio_t;
    -- begin
    --   for i in 1 to 1000 loop
    --     entradaA <= aleatorio.genera_vector(32);
    --     entradaB <= aleatorio.genera_vector(32);
    --     resta    <= aleatorio.genera_bit;
    --     wait for 1 ns;
    --   end loop;
    --   wait for 1 ns;
    --   finish;
    -- end process;
    -- ~~~
    type aleatorio_t is protected
        -- La semilla es el estado del generador de numeros pseudoaleatorios,
        -- la secuencia generada depende de la semilla. No es necesario
        -- configurarla salvo que se quiera una secuencia distinta
        procedure establece_semilla(
            semilla_1: in integer range 1 to 2147483562;
            semilla_2: in integer range 1 to 2147483398);
        -- Genera un bit aleatorio ('1' o '0')
        impure function genera_bit return std_logic;
        -- Genera un vector de n bits aleatorio (cualquier combinación posible)
        impure function genera_vector(nbits : positive) return std_logic_vector;
        -- Genera un vector de n bits en base a un entero aleatorio
        impure function genera_vector_en_rango(val_min : integer;val_max : integer; nbits : positive) return std_logic_vector;
    end protected aleatorio_t;
end package ;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package body util_sim is
    type aleatorio_t is protected body 
        variable s1,s2 : positive := 1999;
        procedure establece_semilla(
            semilla_1: in integer range 1 to 2147483562;
            semilla_2: in integer range 1 to 2147483398) is
        begin
            s1 := semilla_1;
            s2 := semilla_2;
        end procedure;
        impure function get_value return real is
            variable a : real;
        begin
            uniform(s1,s2,a);
            return a;
        end function;

        impure function genera_bit return std_logic is
        begin
            if get_value > 0.5 then
                return '1';
            else
                return '0';
            end if;
        end function;

        impure function genera_vector (nbits : positive) return std_logic_vector is
            constant Nt : positive := nbits;
            constant Nx : natural := Nt/31;
            constant Nr : natural := Nt mod 31;
            variable valor : std_logic_vector (Nt-1 downto 0);
        begin
            valor := (others=>'0');
            if Nx > 0 then
                for i in 0 to Nx-1 loop
                    valor(i*31+30 downto i*31) := std_logic_vector(to_unsigned(integer(floor(get_value*2.0**31)),31));
                end loop;
            end if;
            if Nr > 0 then
                valor(Nx*31+Nr-1 downto Nx*31) := std_logic_vector(to_unsigned(integer(floor(get_value*2.0**Nr)),Nr));
            end if;
            return valor;
        end function;
        impure function genera_entero (val_min : integer;val_max : integer) return integer is
            variable a: real;
        begin
            a := get_value;
            return integer(floor(a*real(val_max+1)+(1.0-a)*real(val_min)));
        end function;
        impure function genera_vector_en_rango(val_min : integer;val_max : integer; nbits : positive) return std_logic_vector is
        begin
            if val_min < 0 then
                return std_logic_vector(to_signed(genera_entero(val_min,val_max),nbits));
            else
                return std_logic_vector(to_unsigned(genera_entero(val_min,val_max),nbits));
            end if;
        end function;
    end protected body aleatorio_t;

end package body;