`timescale 1ns / 1ps

`include "define.vh"

module rv32i_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] d_rdata,
    output [31:0] instr_addr,
    output        d_we,
    output [ 2:0] o_funct3,
    output [31:0] d_addr,
    output [31:0] d_wdata
);

    logic pc_en, rf_we, branch, alu_src, jal, jalr;
    logic [2:0] rf_wb_src;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .pc_en      (pc_en),              // for multi cycle fetch : pc
        .rf_we      (rf_we),
        .jal        (jal),
        .jalr       (jalr),
        .branch     (branch),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .rf_wb_src  (rf_wb_src),
        .o_funct3   (o_funct3),
        .d_we       (d_we)
    );

    rv32i_datapath U_DATAPATH (.*);

endmodule

module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       pc_en,
    output logic       rf_we,
    output logic       jal,
    output logic       jalr,
    output logic       branch,
    output logic       alu_src,
    output logic [3:0] alu_control,
    output logic [2:0] rf_wb_src,
    output logic [2:0] o_funct3,
    output logic       d_we
);

    typedef enum logic [3:0] {
        FETCH,
        DECODE,
        EXECUTE,
        EXE_R,
        EXE_I,
        EXE_S,
        EXE_B,
        EXE_IL,
        EXE_J,
        EXE_JR,
        EXE_U,
        EXE_UPC,
        MEM,
        MEM_S,
        MEM_IL,
        WB
    } state_e;

    state_e c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    // next CL
    always_comb begin
        n_state = c_state;
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    `JALR_TYPE, `JAL_TYPE, `AUIPC_TYPE, `LUI_TYPE, `B_TYPE, `I_TYPE, `R_TYPE: begin
                        n_state = FETCH;
                    end
                    `S_TYPE: begin
                        n_state = MEM;
                    end
                    `I_L_TYPE: begin
                        n_state = MEM;
                    end
                endcase
            end
            MEM: begin
                case (opcode)
                    `S_TYPE: begin
                        n_state = FETCH;
                    end
                    `I_L_TYPE: begin
                        n_state = WB;
                    end
                endcase
            end
            WB: begin
                n_state = FETCH;
            end
        endcase
    end

    // output CL
    always_comb begin
        pc_en       = 1'b0;
        rf_we       = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        branch      = 1'b0;
        alu_src     = 1'b0;
        alu_control = 4'b0000;
        rf_wb_src   = 3'b000;
        o_funct3    = 3'b000;  // for S type, IL type
        d_we        = 1'b0;  // for S type, IL type
        case (c_state)
            FETCH: begin
                pc_en = 1'b1;
            end
            DECODE: begin
            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        rf_we       = 1'b1;  
                        alu_src     = 1'b0;
                        alu_control = {funct7[5], funct3};
                    end
                    `I_TYPE: begin
                        rf_we   = 1'b1;
                        alu_src = 1'b1;
                        if (funct3 == 3'b101)
                            alu_control = {funct7[5], funct3};  // SRLI, SRAI
                        else alu_control = {1'b0, funct3};
                    end
                    `B_TYPE: begin
                        branch      = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {1'b0, funct3};
                    end
                    `S_TYPE: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;  // add for dwaddr
                    end
                    `I_L_TYPE: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;  // add for dwaddr
                    end
                    `LUI_TYPE: begin
                        rf_we = 1'b1;
                        rf_wb_src = 3'b010;
                    end
                    `AUIPC_TYPE: begin
                        rf_we = 1'b1;
                        rf_wb_src = 3'b011;
                    end
                    `JAL_TYPE: begin
                        rf_we     = 1'b1;
                        jal       = 1'b1;
                        jalr      = 1'b0;  // JAL
                        rf_wb_src = 3'b100;
                    end
                    `JALR_TYPE: begin
                        rf_we     = 1'b1;
                        jal       = 1'b1;
                        jalr      = 1'b1;  // JALR
                        rf_wb_src = 3'b100;
                    end
                endcase
            end
            MEM: begin
                if (opcode == `S_TYPE) d_we = 1'b1;
                o_funct3 = funct3;
            end
            WB: begin
                // I_L type
                rf_we     = 1'b1;  // next state FETCH
                rf_wb_src = 3'b001;
            end
        endcase
    end

    //     always_comb begin
    //         rf_we       = 1'b0;
    //         jal         = 1'b0;
    //         jalr        = 1'b0;
    //         branch      = 1'b0;
    //         alu_src     = 1'b0;
    //         alu_control = 4'b0000;
    //         rf_wb_src   = 3'b000;
    //         o_funct3    = 3'b000;
    //         d_we        = 1'b0;
    //         case (opcode)
    //             `R_TYPE: begin  // R-type, to write register file, alu_control == {funct7[5], funct3}
    //                 rf_we       = 1'b1;
    //                 jal         = 1'b0;
    //                 jalr        = 1'b0;
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b0;
    //                 alu_control = {funct7[5], funct3};
    //                 rf_wb_src   = 3'b000;
    //                 o_funct3    = 3'b000;
    //                 d_we        = 1'b0;
    //             end
    //             `B_TYPE: begin
    //                 rf_we       = 1'b0;
    //                 jal         = 1'b0;
    //                 jalr        = 1'b0;
    //                 branch      = 1'b1;
    //                 alu_src     = 1'b0;
    //                 alu_control = {1'b0, funct3};
    //                 rf_wb_src   = 3'b000;
    //                 o_funct3    = 3'b000;
    //                 d_we        = 1'b0;
    //             end
    //             `S_TYPE: begin
    //                 rf_we       = 1'b0;
    //                 jal         = 1'b0;
    //                 jalr        = 1'b0;
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b1;
    //                 alu_control = 4'b0000;
    //                 rf_wb_src   = 3'b000;
    //                 o_funct3    = funct3;
    //                 d_we        = 1'b1;
    //             end
    //             `I_L_TYPE: begin
    //                 rf_we       = 1'b1;
    //                 jal         = 1'b0;
    //                 jalr        = 1'b0;
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b1;
    //                 alu_control = 4'b0000;
    //                 rf_wb_src   = 3'b001;
    //                 o_funct3    = funct3;
    //                 d_we        = 1'b0;
    //             end
    //             `I_TYPE: begin
    //                 rf_we   = 1'b1;
    //                 jal     = 1'b0;
    //                 jalr    = 1'b0;
    //                 branch  = 1'b0;
    //                 alu_src = 1'b1;
    //                 if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
    //                 else alu_control = {1'b0, funct3};
    //                 rf_wb_src = 3'b000;
    //                 o_funct3  = 3'b000;
    //                 d_we      = 1'b0;
    //             end
    //             `LUI_TYPE: begin
    //                 rf_we       = 1'b1;
    //                 jal         = 1'b0;
    //                 jalr        = 1'b0;
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b0;
    //                 alu_control = 4'b0000;
    //                 rf_wb_src   = 3'b010;  // lui
    //                 o_funct3    = 3'b000;
    //                 d_we        = 1'b0;
    //             end
    //             `AUIPC_TYPE: begin
    //                 rf_we       = 1'b1;
    //                 jal         = 1'b0;
    //                 jalr        = 1'b0;
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b0;
    //                 alu_control = 4'b0000;
    //                 rf_wb_src   = 3'b011;  // auipc
    //                 o_funct3    = 3'b000;
    //                 d_we        = 1'b0;
    //             end
    //             `JAL_TYPE: begin
    //                 rf_we       = 1'b1;
    //                 jal         = 1'b1;
    //                 jalr        = 1'b0;  // JAL
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b0;
    //                 alu_control = 4'b0000;
    //                 rf_wb_src   = 3'b100;
    //                 o_funct3    = 3'b000;
    //                 d_we        = 1'b0;
    //             end
    //             `JALR_TYPE: begin
    //                 rf_we       = 1'b1;
    //                 jal         = 1'b1;
    //                 jalr        = 1'b1;  // JALR
    //                 branch      = 1'b0;
    //                 alu_src     = 1'b0;
    //                 alu_control = 4'b0000;
    //                 rf_wb_src   = 3'b100;
    //                 o_funct3    = 3'b000;
    //                 d_we        = 1'b0;
    //             end
    //         endcase
    //     end

endmodule
