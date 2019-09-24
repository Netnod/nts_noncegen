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
  localparam DEBUG     = 0;
  localparam DEBUG_MEM = 1;

  localparam CLK_HALF_PERIOD = 1;
  localparam CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  localparam TIMEOUT_CYCLES = 100000000;


  localparam ADDR_NAME0         = 8'h00;
  localparam ADDR_NAME1         = 8'h01;
  localparam ADDR_VERSION       = 8'h02;

  localparam ADDR_CTRL          = 8'h08;
  localparam CTRL_ENABLE_BIT    = 0;

  localparam ADDR_STATUS        = 8'h09;
  localparam STATUS_READY_BIT   = 0;

  localparam ADDR_CONFIG        = 8'h0a;
  localparam CONFIG_COMP_BIT0   = 0;
  localparam CONFIG_COMP_BIT3   = 3;
  localparam CONFIG_FINAL_BIT0  = 8;
  localparam CONFIG_FINAL_BIT3  = 11;

  localparam ADDR_KEY0          = 8'h10;
  localparam ADDR_KEY1          = 8'h11;
  localparam ADDR_KEY2          = 8'h12;
  localparam ADDR_KEY3          = 8'h13;

  localparam ADDR_LABEL         = 8'h20;

  localparam ADDR_CTR0          = 8'h30;
  localparam ADDR_CTR1          = 8'h31;

  localparam ADDR_CONTEXT0      = 8'h40;
  localparam ADDR_CONTEXT1      = 8'h41;
  localparam ADDR_CONTEXT2      = 8'h42;
  localparam ADDR_CONTEXT3      = 8'h43;
  localparam ADDR_CONTEXT4      = 8'h44;
  localparam ADDR_CONTEXT5      = 8'h45;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;
  reg           tc_correct;

  reg [31 : 0]  read_data;

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
      $display("cs: 0x%01x, we: 0x%01x, addr: 0x%02x",
               dut_cs, dut_we, dut_address);
      $display("read_data: 0x%08x, write_data: 0x%08x",
               dut_read_data, dut_write_data);
      $display("get_nonce: 0x%01x, nonce: 0x%016x",
               dut_get_nonce, dut_nonce);
      $display("ready: 0x%01x", dut_ready);
      $display("");

      $display("Internal state:");
      $display("key0: 0x%08x, key1: 0x%08x, key2: 0x%08x, key3: 0x%08x",
               dut.key[0], dut.key[1], dut.key[2], dut.key[3]);
      $display("ctx0: 0x%08x, ctx1: 0x%08x, ctx2: 0x%08x, ctx3: 0x%08x",
               dut.ctx[0], dut.ctx[1], dut.ctx[2], dut.ctx[3]);
      $display("ctx4: 0x%08x, ctx5: 0x%08x", dut.ctx[4], dut.ctx[5]);
      $display("ctr0: 0x%08x, ctr1: 0x%04x, label: 0x%08x",
               dut.ctr0_reg, dut.ctr1_reg, dut.label_reg);
      $display("mutate: 0x%08x", dut.mutate_reg);
      $display("");

      $display("SipHash:");
      $display("ready: 0x%01x, init: 0x%01x, compress: 0x%01x, finalize: 0x%01x",
               dut.siphash_ready, dut.siphash_initalize,
               dut.siphash_compress, dut.siphash_finalize);
      $display("key:  0x%032x", dut.siphash_key);
      $display("mi:   0x%016x", dut.siphash_mi);
      $display("word: 0x%032x", dut.siphash_word);
      $display("");

      $display("Control:");
      $display("ctrl_reg: 0x%02x, ctrl_new: 0x%02x, ctrl_we: 0x%01x",
               dut.noncegen_ctrl_reg, dut.noncegen_ctrl_new, dut.noncegen_ctrl_we);
      $display("enable: 0x%01x", dut.enable_reg);
      $display("\n");
    end
  endtask // dump_dut_state


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

      dut_cs         = 1'h0;
      dut_we         = 1'h0;
      dut_address    = 8'h0;
      dut_write_data = 32'h0;
      dut_get_nonce  = 1'h0;
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
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      dut_address = address;
      dut_write_data = word;
      dut_cs = 1;
      dut_we = 1;
      #(1 * CLK_PERIOD);
      dut_cs = 0;
      dut_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0]  address);
    begin
      dut_address = address;
      dut_cs = 1;
      dut_we = 0;
      #(CLK_PERIOD);
      read_data = dut_read_data;
      dut_cs = 0;

      if (DEBUG)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      #(4 * CLK_PERIOD);

      $display("TB: Resetting dut.");
      tb_reset = 1;
      #(2 * CLK_PERIOD);
      tb_reset = 0;
      #(2 * CLK_PERIOD);
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // tc1_setup
  //
  // Write to API registers to setup the dut.
  //----------------------------------------------------------------
  task tc1_setup;
    begin : tc1_setup
      inc_tc_ctr();
      tb_debug = 1;
      $display("TC1: Setup the state of the dut.");

      write_word(ADDR_KEY0, 32'h11111111);
      write_word(ADDR_KEY1, 32'h22222222);
      write_word(ADDR_KEY2, 32'h33333333);
      write_word(ADDR_KEY3, 32'h44444444);

      write_word(ADDR_CONTEXT0, 32'h01010101);
      write_word(ADDR_CONTEXT1, 32'h02020202);
      write_word(ADDR_CONTEXT2, 32'h03030303);
      write_word(ADDR_CONTEXT3, 32'h04040404);
      write_word(ADDR_CONTEXT4, 32'h05050505);
      write_word(ADDR_CONTEXT5, 32'h06060606);

      write_word(ADDR_LABEL, 32'hdeadbeef);

      #(2 * CLK_PERIOD);
      tb_debug = 0;
    end
  endtask // tc1_setup


  //----------------------------------------------------------------
  // tc2_generate
  //
  // Setup and then enable the generator. Then generate a few words.
  //----------------------------------------------------------------
  task tc2_generate;
    begin : tc2_generate
      inc_tc_ctr();
      tb_debug = 1;
      $display("TC2: Generate nonce words.");

      write_word(ADDR_KEY0, 32'h11111111);
      write_word(ADDR_KEY1, 32'h22222222);
      write_word(ADDR_KEY2, 32'h33333333);
      write_word(ADDR_KEY3, 32'h44444444);

      write_word(ADDR_CONTEXT0, 32'h01010101);
      write_word(ADDR_CONTEXT1, 32'h02020202);
      write_word(ADDR_CONTEXT2, 32'h03030303);
      write_word(ADDR_CONTEXT3, 32'h04040404);
      write_word(ADDR_CONTEXT4, 32'h05050505);
      write_word(ADDR_CONTEXT5, 32'h06060606);

      write_word(ADDR_LABEL, 32'h0000beef);

      write_word(ADDR_CTRL, 32'h1);


      #(2 * CLK_PERIOD);
      $display("TC2: Trying to start generation of first nonce.");
      dut_get_nonce = 1'h1;
      #(2 * CLK_PERIOD);
      dut_get_nonce = 1'h0;

      while(!dut_ready)
        #(CLK_PERIOD);

      $display("TC2: Generation of first nonce should be completed.");


      #(2 * CLK_PERIOD);
      $display("TC2: Trying to start generation of second nonce.");
      dut_get_nonce = 1'h1;
      #(2 * CLK_PERIOD);
      dut_get_nonce = 1'h0;

      while(!dut_ready)
        #(CLK_PERIOD);

      $display("TC2: Generation of second nonce should be completed.");


      #(2 * CLK_PERIOD);
      $display("TC2: Trying to start generation of third nonce.");
      dut_get_nonce = 1'h1;
      #(2 * CLK_PERIOD);
      dut_get_nonce = 1'h0;

      while(!dut_ready)
        #(CLK_PERIOD);

      $display("TC2: Generation of third nonce should be completed.");

      #(10 * CLK_PERIOD);

      tb_debug = 0;
    end
  endtask // tc2_generate


  //----------------------------------------------------------------
  // tc3_dump_data
  //
  // Setup and then enable the generator. Then generate a few words.
  //----------------------------------------------------------------
  task tc3_dump_data;
    begin : tc3_dump_data
      integer num_nonces;
      integer fd;
      integer i;

      tb_debug = 0;
      num_nonces = 10000;

      inc_tc_ctr();
      $display("TC3: Dump %d nonces", num_nonces);

      // Open file for writing.
      fd = $fopen ("noncedata.bin", "wb");

      // Set key, label context.
      write_word(ADDR_KEY0, 32'h11111111);
      write_word(ADDR_KEY1, 32'h22222222);
      write_word(ADDR_KEY2, 32'h33333333);
      write_word(ADDR_KEY3, 32'h44444444);

      write_word(ADDR_CONTEXT0, 32'h01010101);
      write_word(ADDR_CONTEXT1, 32'h02020202);
      write_word(ADDR_CONTEXT2, 32'h03030303);
      write_word(ADDR_CONTEXT3, 32'h04040404);
      write_word(ADDR_CONTEXT4, 32'h05050505);
      write_word(ADDR_CONTEXT5, 32'h06060606);

      write_word(ADDR_LABEL, 32'h0000beef);

      write_word(ADDR_CTRL, 32'h1);


      for (i = 0 ; i < num_nonces ; i = i + 1)
        begin
          dut_get_nonce = 1'h1;
          #(2 * CLK_PERIOD);
          dut_get_nonce = 1'h0;

          while(!dut_ready)
            #(CLK_PERIOD);

          $fwrite(fd, "%c%c%c%c%c%c%c%c",
                  dut_nonce[63 : 56], dut_nonce[55 : 48],
                  dut_nonce[47 : 40], dut_nonce[39 : 32],
                  dut_nonce[31 : 24], dut_nonce[23 : 16],
                  dut_nonce[15 : 08], dut_nonce[07 : 00]);

          if (i % 1000 == 0)
            $display("Generated nonce %d", i);
        end
      $fclose(fd);
      $display("TC3: Dump %d nonces completed.", num_nonces);
    end
  endtask // tc3_dump_data


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

//      tc1_setup();
//      tc2_generate();
      tc3_dump_data();

      display_test_results();

      $display("*** nts_noncegen simulation completed. ***");
      $finish;
    end // main

endmodule // tb_nts_noncegen

//======================================================================
// EOF tb_nts_noncegen.v
//======================================================================
