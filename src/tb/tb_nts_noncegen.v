//======================================================================
//
// tb_nts_noncegen.v
// -----------------
// Testbench for NTS noncegen.
//
//
// Author: Joachim Strombergson
//
// Copyright (c) 2019, The Swedish Post and Telecom Authority (PTS)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module tb_nts_noncegen();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam DEBUG     = 1;
  localparam DEBUG_MEM = 1;

  localparam CLK_HALF_PERIOD = 1;
  localparam CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  localparam TIMEOUT_CYCLES = 10000;

  reg [127 : 0] testreg;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;
  reg           tc_correct;

  reg           tb_debug;
  reg           tb_clk;
  reg           tb_reset;

  reg           dut_cs;
  reg           dut_we;
  reg  [7 : 0]  dut_address;
  reg  [31 : 0] dut_write_data;
  wire [31 : 0] dut_read_data;
  reg           dut_get_nonce;
  wire [63 : 0] dut_nonce;
  wire          dut_ready;


  //----------------------------------------------------------------
  // Instantiations.
  //----------------------------------------------------------------
  nts_noncegen dut(
                   .clk(tb_clk),
                   .areset(tb_reset),
                   .cs(dut_cs),
                   .we(dut_we),
                   .address(dut_address),
                   .write_data(dut_write_data),
                   .read_data(dut_read_data),
                   .get_nonce(dut_get_nonce),
                   .nonce(dut_nonce),
                   .ready(dut_ready)
                  );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      #(CLK_PERIOD);
      cycle_ctr = cycle_ctr + 1;

      if (cycle_ctr == TIMEOUT_CYCLES)
        begin
          $display("Timout reached after %d cycles before simulation ended.",
                   cycle_ctr);
          $stop;
        end

      if (tb_debug)
        dump_dut_state();
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("\n");
      $display("cycle:  0x%016x", cycle_ctr);
      $display("Inputs and outputs:");
      $display("");

      $display("Control:");
      $display("\n");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("TB: Resetting dut.");
      tb_reset = 1;
      #(2 * CLK_PERIOD);
      tb_reset = 0;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_results()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_results;
    begin
      $display("");
      if (error_ctr == 0)
        begin
          $display("%02d test completed. All test cases completed successfully.", tc_ctr);
        end
      else
        begin
          $display("%02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_results


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr = 0;
      error_ctr = 0;
      tc_ctr    = 0;

      tb_clk    = 1'h0;
      tb_reset  = 1'h0;
      tb_debug  = 1'h1;

      dut_cs = 1'h0;
      dut_we = 1'h0;

    end
  endtask // init_sim


  //----------------------------------------------------------------
  // inc_tc_ctr
  //----------------------------------------------------------------
  task inc_tc_ctr;
    tc_ctr = tc_ctr + 1;
  endtask // inc_tc_ctr


  //----------------------------------------------------------------
  // inc_error_ctr
  //----------------------------------------------------------------
  task inc_error_ctr;
    error_ctr = error_ctr + 1;
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // pause_finish()
  //
  // Pause for a given number of cycles and then finish sim.
  //----------------------------------------------------------------
  task pause_finish(input [31 : 0] num_cycles);
    begin
      $display("Pausing for %04d cycles and then finishing hard.", num_cycles);
      #(num_cycles * CLK_PERIOD);
      $finish;
    end
  endtask // pause_finish


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for the ready flag to be set in dut.
  //----------------------------------------------------------------
  task wait_ready;
    begin : wready
      while (dut_ready == 0)
        #(CLK_PERIOD);
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // tc1_reset_state
  //
  // Check that registers in the dut are being correctly reset.
  //----------------------------------------------------------------
  task tc1_reset_state;
    begin : tc1
      inc_tc_ctr();
      tb_debug = 1;
      $display("TC1: Check that the dut registers are correctly reset.");
      #(2 * CLK_PERIOD);
      reset_dut();
      #(2 * CLK_PERIOD);
      tb_debug = 0;
    end
  endtask // tc1_reset_state


  //----------------------------------------------------------------
  // main
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : main
      $display("*** Simulation of nts_noncegen started ***");
      $display("");

      init_sim();
      reset_dut();

      display_test_results();

      $display("*** nts_noncegen simulation completed. ***");
      $finish;
    end // main

endmodule // tb_nts_noncegen

//======================================================================
// EOF tb_nts_noncegen.v
//======================================================================
