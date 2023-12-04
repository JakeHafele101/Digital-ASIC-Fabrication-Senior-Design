#!/bin/sh
# NC wires break gate level simulation because they are not declared as wires. This adds them.

# Execute from root

fix() {
  grep -E -o '_NC[0-9]+' $1 | sed 's|\(.*\)| wire \1;|' > tmp.wires
  echo "$\n? wire ? r tmp.wires\nw" | ed $1
}

cd verilog/gl
fix user_project_wrapper.v
fix user_proj_final.v