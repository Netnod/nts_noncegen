#===================================================================
#
# Makefile
# --------
# Makefile for building the nts_noncegen and top level simulation.
#
#
# Author: Joachim Strombergson
#
# Copyright (c) 2019, Netnod Internet Exchange i Sverige AB (Netnod).
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#===================================================================
SIPHASH_SRC_PATH = ../../siphash/src/rtl
SIPHASH_SRC = $(SIPHASH_SRC_PATH)/siphash_core.v

TOP_SRC = ../src/rtl/nts_noncegen.v $(SIPHASH_SRC)
TOP_TB_SRC = ../src/tb/tb_nts_noncegen.v

CC = iverilog
CC_FLAGS = -Wall

LINT = verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME


all: top.sim


top.sim: $(TOP_SRC) $(TOP_TB_SRC)
	$(CC) $(CC_FLAGS) -o top.sim  $(TOP_TB_SRC) $(TOP_SRC)


lint:  $(TOP_SRC)
	$(LINT) $(LINT_FLAGS) $(TOP_SRC)


clean:
	rm -f *.sim

help:
	@echo "Build system for simulation of nts_noncegen"
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "top.sim:      Build top level simulation target."
	@echo "lint:         Lint all rtl source files."
	@echo "clean:        Delete all built files."


#===================================================================
# EOF Makefile
#===================================================================
