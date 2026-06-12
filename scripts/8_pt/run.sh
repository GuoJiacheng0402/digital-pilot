#!/bin/sh
rm -rf reports log wst parasitics_command.log
mkdir -p reports log
if [ -n "$LC_DIR" ] && [ -z "$SYNOPSYS_LC_ROOT" ]; then
  export SYNOPSYS_LC_ROOT="$LC_DIR"
fi
pt_shell -f tcl/pt_wst.tcl | tee -i log/pt_wst.log
