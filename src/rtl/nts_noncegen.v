//======================================================================
//
// nts_noncegen.v
// --------------
// key memory for the NTS engine. Supports four separate keys,
// with key usage counters.
//
//
// Author: Joachim Strombergson
//
// Copyright (c) 2019, Netnod Internet Exchange i Sverige AB (Netnod).
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

module nts_noncegen(
                    input wire           clk,
                    input wire           areset,

                    // API access
                    input wire           cs,
                    input wire           we,
                    input wire  [7 : 0]  address,
                    input wire  [31 : 0] write_data,
                    output wire [31 : 0] read_data,

                    // Client access
                    input wire           get_nonce,
                    output wire [63 : 0] nonce,
                    output wire          nonce_valid,
                    output wire          ready
                   );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
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
  localparam ADDR_KEY3          = 8'h13;

  localparam ADDR_LABEL         = 8'h20;

  localparam ADDR_CTR0          = 8'h30;
  localparam ADDR_CTR1          = 8'h31;

  localparam ADDR_CONTEXT0      = 8'h40;
  localparam ADDR_CONTEXT5      = 8'h45;


  localparam CORE_NAME0   = 32'h6e6f6e63; // nonc
  localparam CORE_NAME1   = 32'h6567656e; // egen
  localparam CORE_VERSION = 32'h302e3132; // "0.12"


  localparam DEFAULT_COMP_ROUNDS  = 4'h2;
  localparam DEFAULT_FINAL_ROUNDS = 4'h4;


  localparam CTRL_IDLE     = 4'h0;
  localparam CTRL_INIT     = 4'h1;
  localparam CTRL_M0       = 4'h2;
  localparam CTRL_M1       = 4'h3;
  localparam CTRL_M2       = 4'h4;
  localparam CTRL_M3       = 4'h5;
  localparam CTRL_FINALIZE = 4'h6;
  localparam CTRL_DONE     = 4'h7;
  localparam CTRL_DISABLED = 4'h8;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] key [0 : 3];
  reg          key_we;

  reg [31 : 0] ctx [0 : 5];
  reg          ctx_we;

  reg [15 : 0] label_reg;
  reg          label_we;

  reg [31 : 0] ctr0_reg;
  reg [31 : 0] ctr0_new;
  reg          ctr0_we;

  reg [15 : 0] ctr1_reg;
  reg [15 : 0] ctr1_new;
  reg          ctr1_we;

  reg [3 : 0]  comp_rounds_reg;
  reg [3 : 0]  final_rounds_reg;

  reg [63 : 0] mutate_reg;
  reg [63 : 0] mutate_new;
  reg          mutate_we;
  reg          mutate_set;
  reg          mutate_rst;

  reg [63 : 0] nonce_reg;
  reg          nonce_we;

  reg          nonce_valid_reg;
  reg          nonce_valid_new;
  reg          nonce_valid_we;

  reg          enable_reg;
  reg          enable_we;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [3 : 0]  noncegen_ctrl_reg;
  reg [3 : 0]  noncegen_ctrl_new;
  reg          noncegen_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]   tmp_read_data;

  reg            ctr_rst;
  reg            ctr_inc;

  reg            config_we;

  reg [1 : 0]    message_ctrl;

  reg            siphash_initalize;
  reg            siphash_compress;
  reg            siphash_finalize;
  wire           siphash_long;
  wire [127 : 0] siphash_key;
  reg  [63 : 0]  siphash_mi;
  wire           siphash_ready;
  wire [127 : 0] siphash_word;
  wire           siphash_word_valid;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data   = tmp_read_data;
  assign nonce       = nonce_reg;
  assign nonce_valid = nonce_valid_reg;
  assign ready       = ready_reg;

  assign siphash_key  = {key[0], key[1], key[2], key[3]};
  assign siphash_long = 1'h1;


  //----------------------------------------------------------------
  // SipHash core instance.
  //----------------------------------------------------------------
  siphash_core core(
                    .clk(clk),
                    .areset(areset),
                    .initalize(siphash_initalize),
                    .compress(siphash_compress),
                    .finalize(siphash_finalize),
                    .long(siphash_long),
                    .compression_rounds(comp_rounds_reg),
                    .final_rounds(final_rounds_reg),
                    .key(siphash_key),
                    .mi(siphash_mi),
                    .ready(siphash_ready),
                    .siphash_word(siphash_word),
                    .siphash_word_valid(siphash_word_valid)
                   );


  //----------------------------------------------------------------
  // reg_update
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or posedge areset)
    begin : reg_update
      integer i;

      if (areset)
        begin
          for (i = 0 ; i < 4 ; i = i + 1)
            key[i] <= 32'h0;

          for (i = 0 ; i < 6 ; i = i + 1)
            ctx[i] <= 32'h0;

          label_reg         <= 16'h0;
          ctr0_reg          <= 32'h0;
          ctr1_reg          <= 16'h0;
          comp_rounds_reg   <= DEFAULT_COMP_ROUNDS;
          final_rounds_reg  <= DEFAULT_FINAL_ROUNDS;
          enable_reg        <= 1'h0;
          mutate_reg        <= 64'h0;
          nonce_reg         <= 64'h0;
          nonce_valid_reg   <= 1'h0;
          ready_reg         <= 1'h0;
          noncegen_ctrl_reg <= CTRL_IDLE;
        end

      else
        begin
          if (key_we)
            key[address[1 : 0]] <= write_data;

          if (ctx_we)
            ctx[address[2 : 0]] <= write_data;

          if (label_we)
            label_reg <= write_data[15 : 0];

          if (ctr0_we)
            ctr0_reg <= ctr0_new;

          if (ctr1_we)
            ctr1_reg <= ctr1_new;

          if (config_we)
            begin
              comp_rounds_reg  <= write_data[CONFIG_COMP_BIT3 : CONFIG_COMP_BIT0];
              final_rounds_reg <= write_data[CONFIG_FINAL_BIT3 : CONFIG_FINAL_BIT0];
            end

          if (mutate_we)
            mutate_reg <= mutate_new;

          if (nonce_we)
            nonce_reg <= siphash_word[127 : 64];

          if (nonce_valid_we)
            nonce_valid_reg <= nonce_valid_new;

          if (ready_we)
            ready_reg <= ready_new;

          if (enable_we)
            enable_reg <= write_data[CTRL_ENABLE_BIT];

          if (noncegen_ctrl_we)
            noncegen_ctrl_reg <= noncegen_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api
  //----------------------------------------------------------------
  always @*
    begin : api
      ctr_rst       = 1'h0;
      key_we        = 1'h0;
      ctx_we        = 1'h0;
      label_we      = 1'h0;
      config_we     = 1'h0;
      enable_we     = 1'h0;
      tmp_read_data = 32'h0;

      if (cs)
        begin
          if (we)
            begin
              case (address)
                ADDR_CTRL:   enable_we = 1'h1;
                ADDR_CONFIG: config_we = 1'h1;
                ADDR_LABEL:  label_we  = 1'h1;
                ADDR_CTR0:   ctr_rst   = 1'h1;
                ADDR_CTR1:   ctr_rst   = 1'h1;
                default:
                  begin
                  end
              endcase // case (address)

              if ((address >= ADDR_KEY0) && (address <= ADDR_KEY3))
                key_we = 1'h1;

              if ((address >= ADDR_CONTEXT0) && (address <= ADDR_CONTEXT5))
                ctx_we = 1'h1;
            end // if (we)

          else
            begin
              case (address)
                ADDR_NAME0:   tmp_read_data = CORE_NAME0;
                ADDR_NAME1:   tmp_read_data = CORE_NAME1;
                ADDR_VERSION: tmp_read_data = CORE_VERSION;
                ADDR_CTRL:    tmp_read_data = {31'h0, enable_reg};
                ADDR_STATUS:  tmp_read_data = {31'h0, ready_reg};
                ADDR_LABEL:   tmp_read_data = {16'h0, label_reg};
                ADDR_CTR0:    tmp_read_data = ctr0_reg;
                ADDR_CTR1:    tmp_read_data = {16'h0, ctr1_reg};
                default:
                  begin
                  end
              endcase // case (address)

              if ((address >= ADDR_KEY0) && (address <= ADDR_KEY3))
                tmp_read_data = key[address[1 : 0]];

              if ((address >= ADDR_CONTEXT0) && (address <= ADDR_CONTEXT5))
                tmp_read_data = ctx[address[2 : 0]];
            end // else: !if(we)
        end
    end // api


  //----------------------------------------------------------------
  // message_logic
  // Generate the message words including mutation.
  //----------------------------------------------------------------
  always @*
    begin : message_logic
      mutate_new = 64'h0;
      mutate_we  = 1'h0;

      if (mutate_set)
        begin
          mutate_new = siphash_word[63 : 0];
          mutate_we  = 1'h1;
        end

      if (mutate_rst)
        begin
          mutate_new = 64'h0;
          mutate_we  = 1'h1;
        end

      case (message_ctrl)
        0: siphash_mi = {ctx[0], ctx[1]} ^ mutate_reg;
        1: siphash_mi = {ctx[2], ctx[3]};
        2: siphash_mi = {label_reg, ctr1_reg, ctr0_reg};
        3: siphash_mi = {ctx[4], ctx[5]};
        default:
          begin
          end
      endcase // case (message_ctrl)
    end


  //----------------------------------------------------------------
  // ctr_logic
  //----------------------------------------------------------------
  always @*
    begin : ctr_logic
      ctr0_new =  32'h0;
      ctr0_we  =  1'h0;
      ctr1_new =  16'h0;
      ctr1_we  =  1'h0;

      if (ctr_rst)
        begin
          ctr0_new =  32'h0;
          ctr0_we  =  1'h1;
          ctr1_new =  16'h0;
          ctr1_we  =  1'h1;
        end

      if (ctr_inc)
        begin
          if (ctr0_reg == 32'hffffffff)
            begin
              ctr0_new = 32'h0;
              ctr0_we  =  1'h1;
              ctr1_new = ctr1_reg + 1'h1;
              ctr1_we  =  1'h1;
            end
          else
            begin
              ctr0_new = ctr0_reg + 1'h1;
              ctr0_we  =  1'h1;
            end
        end
    end


  //----------------------------------------------------------------
  // noncegen_ctrl
  //----------------------------------------------------------------
  always @*
    begin : noncegen_ctrl
      ctr_inc           = 1'h0;
      siphash_initalize = 1'h0;
      siphash_compress  = 1'h0;
      siphash_finalize  = 1'h0;
      message_ctrl      = 2'h0;
      mutate_rst        = 1'h0;
      mutate_set        = 1'h0;
      nonce_we          = 1'h0;
      nonce_valid_new   = 1'h0;
      nonce_valid_we    = 1'h0;
      ready_new         = 1'h0;
      ready_we          = 1'h0;
      noncegen_ctrl_new = CTRL_IDLE;
      noncegen_ctrl_we  = 1'h0;

      case (noncegen_ctrl_reg)
        CTRL_IDLE:
          begin
            if (!enable_reg)
              begin
                ready_new         = 1'h0;
                ready_we          = 1'h1;
                nonce_valid_new   = 1'h0;
                nonce_valid_we    = 1'h1;
                noncegen_ctrl_new = CTRL_DISABLED;
                noncegen_ctrl_we  = 1'h1;
              end
            else
              begin
                if (get_nonce)
                  begin
                    ready_new         = 1'h0;
                    ready_we          = 1'h1;
                    nonce_valid_new   = 1'h0;
                    nonce_valid_we    = 1'h1;
                    noncegen_ctrl_new = CTRL_INIT;
                    noncegen_ctrl_we  = 1'h1;
                  end
              end
          end

        CTRL_INIT:
          begin
            siphash_initalize = 1'h1;
            noncegen_ctrl_new = CTRL_M0;
            noncegen_ctrl_we  = 1'h1;
          end

        CTRL_M0:
          begin
            if (siphash_ready)
              begin
                message_ctrl      = 2'h0;
                siphash_compress  = 1'h1;
                noncegen_ctrl_new = CTRL_M1;
                noncegen_ctrl_we  = 1'h1;
              end
          end

        CTRL_M1:
          begin
            message_ctrl = 2'h0;

            if (siphash_ready)
              begin
                message_ctrl      = 2'h1;
                siphash_compress  = 1'h1;
                noncegen_ctrl_new = CTRL_M2;
                noncegen_ctrl_we  = 1'h1;
              end
          end

        CTRL_M2:
          begin
            message_ctrl = 2'h1;

            if (siphash_ready)
              begin
                message_ctrl      = 2'h2;
                siphash_compress  = 1'h1;
                noncegen_ctrl_new = CTRL_M3;
                noncegen_ctrl_we  = 1'h1;
              end
          end

        CTRL_M3:
          begin
            message_ctrl = 2'h2;

            if (siphash_ready)
              begin
                message_ctrl      = 2'h3;
                siphash_compress  = 1'h1;
                noncegen_ctrl_new = CTRL_FINALIZE;
                noncegen_ctrl_we  = 1'h1;
              end
          end

        CTRL_FINALIZE:
          begin
            message_ctrl = 2'h3;

            if (siphash_ready)
              begin
                message_ctrl      = 2'h3;
                siphash_finalize  = 1'h1;
                noncegen_ctrl_new = CTRL_DONE;
                noncegen_ctrl_we  = 1'h1;
              end
          end

        CTRL_DONE:
          begin
            if (siphash_ready)
              begin
                if (siphash_word_valid)
                  begin
                    ctr_inc           = 1'h1;
                    mutate_set        = 1'h1;
                    nonce_we          = 1'h1;
                    nonce_valid_new   = 1'h1;
                    nonce_valid_we    = 1'h1;
                    ready_new         = 1'h1;
                    ready_we          = 1'h1;
                    noncegen_ctrl_new = CTRL_IDLE;
                    noncegen_ctrl_we  = 1'h1;
                  end
                else
                  begin
                  end
              end
          end

        CTRL_DISABLED:
          begin
            if (enable_reg)
              begin
                mutate_rst        = 1'h1;
                nonce_valid_new   = 1'h0;
                nonce_valid_we    = 1'h1;
                ready_new         = 1'h1;
                ready_we          = 1'h1;
                noncegen_ctrl_new = CTRL_IDLE;
                noncegen_ctrl_we  = 1'h1;
              end
          end

        default:
          begin
          end
      endcase // case (keymem_ctrl_reg)
    end // block: noncegen_ctrl

endmodule // nts_noncegen

//======================================================================
// EOF nts_noncegen.v
//======================================================================
