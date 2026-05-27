`timescale 1ns / 1ps

`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         pc_en,
    input         rf_we,
    input         jal,
    input         jalr,
    input         branch,
    input         alu_src,
    input  [ 2:0] rf_wb_src,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] d_rdata,
    output [31:0] instr_addr,
    output [31:0] d_addr,
    output [31:0] d_wdata
);

    logic [31:0] alu_result, imm_data, alu_rs2_data;
    logic [31:0] rf_wb_data, auipc, j_type;
    logic b_taken;
    // decoder
    logic [31:0]
        i_dec_rs1, o_dec_rs1, i_dec_rs2, o_dec_rs2, i_dec_imm, o_dec_imm;
    //execute
    logic [31:0] o_exe_rs2, o_exe_alu_result;
    // mem
    logic [31:0] o_mem_d_rdata;
    // write back to register file

    assign d_addr  = o_exe_alu_result;
    assign d_wdata = o_exe_rs2;

    // fetch, Execute
    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .pc_en          (pc_en),
        .b_taken        (b_taken),
        .branch         (branch),
        .jal            (jal),
        .jalr           (jalr),
        .imm_data       (o_dec_imm),
        .rs1            (o_dec_rs1),
        .program_counter(instr_addr),
        .pc_4_out       (j_type),
        .pc_imm_out     (auipc)
    );

    // decode
    register_file U_REG_FILE (
        .clk  (clk),
        // .rst  (rst),
        .RA1  (instr_data[19:15]),
        .RA2  (instr_data[24:20]),
        .WA   (instr_data[11:7]),
        .rf_we(rf_we),
        .Wdata(rf_wb_data),
        .RD1  (i_dec_rs1),
        .RD2  (i_dec_rs2)
    );

    imm_extender U_IMM_EXTENDER (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    // decode output register
    register U_DEC_REG_RS1 (
        .clk     (clk),
        .rst     (rst),
        .data_in (i_dec_rs1),
        .data_out(o_dec_rs1)
    );

    register U_DEC_REG_RS2 (
        .clk     (clk),
        .rst     (rst),
        .data_in (i_dec_rs2),
        .data_out(o_dec_rs2)
    );

    register U_DEC_IMM_EXT (
        .clk     (clk),
        .rst     (rst),
        .data_in (imm_data),
        .data_out(o_dec_imm)
    );

    // execute
    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0    (o_dec_rs2),    // sel 0
        .in1    (o_dec_imm),    // sel 1
        .mux_sel(alu_src),
        .out_mux(alu_rs2_data)
    );

    alu U_ALU (
        .rd1        (o_dec_rs1),
        .rd2        (alu_rs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result),
        .b_taken    (b_taken)
    );

    // execute register for ALU result, RS2
    register U_EXE_ALU_RESULT (
        .clk     (clk),
        .rst     (rst),
        .data_in (alu_result),
        .data_out(o_exe_alu_result)  // to d_addr
    );

    register U_EXE_REG_RS2 (
        .clk     (clk),
        .rst     (rst),
        .data_in (o_dec_rs2),  // from alu result
        .data_out(o_exe_rs2)   // to Data Mem_Wdata
    );

    // MEM to WB
    register U_MEM_REG_DRDATA (
        .clk     (clk),
        .rst     (rst),
        .data_in (d_rdata),       // from alu result
        .data_out(o_mem_d_rdata)  // to Data Mem_Wdata
    );

    // Write Back to Register File
    // to register file
    mux_5x1 U_WB_MUX (
        .in0    (alu_result),     // from ALU Result, because of process with execute state
        .in1(o_mem_d_rdata),  // from data memory
        .in2(o_dec_imm),  // from imm extend, for LUI
        .in3(auipc),  // from pc + imm extend, for AUIPC
        .in4(j_type),  // from pc + 4, for JAL/JALR
        .mux_sel(rf_wb_src),
        .out_mux(rf_wb_data)
    );

endmodule

module mux_5x1 (
    input        [31:0] in0,      // sel 0
    input        [31:0] in1,      // sel 1
    input        [31:0] in2,      // sel 2
    input        [31:0] in3,      // sel 3
    input        [31:0] in4,      // sel 4
    input        [ 2:0] mux_sel,
    output logic [31:0] out_mux
);

    always_comb begin
        case (mux_sel)
            3'b000:  out_mux = in0;
            3'b001:  out_mux = in1;
            3'b010:  out_mux = in2;
            3'b011:  out_mux = in3;
            3'b100:  out_mux = in4;
            default: out_mux = 32'hxxxx;
        endcase
    end

endmodule

module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);

    always_comb begin
        imm_data = 32'b0;
        case (instr_data[6:0])  // opcode
            `B_TYPE: begin
                imm_data = {
                    {19{instr_data[31]}},
                    instr_data[31],  // imm bit 12
                    instr_data[7],  // imm bit 11
                    instr_data[30:25],  // imm bit 10:5
                    instr_data[11:8],  // imm bit 4:1
                    1'b0
                };
            end
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
            `I_TYPE, `I_L_TYPE: begin  // load
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `LUI_TYPE, `AUIPC_TYPE: begin
                imm_data = {instr_data[31:12], 12'b0};
            end
            `JAL_TYPE: begin
                imm_data = {
                    {11{instr_data[31]}},
                    instr_data[31],  // imm bit 20
                    instr_data[19:12],  // imm bit 19:12
                    instr_data[20],  // imm bit 11
                    instr_data[30:21],  // imm bit 10:1
                    1'b0
                };
            end
            `JALR_TYPE: begin
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
        endcase
    end

endmodule

module register_file (
    input         clk,
    // input         rst,
    input  [ 4:0] RA1,    // instruction code RS1
    input  [ 4:0] RA2,    // instruction code RS2
    input  [ 4:0] WA,     // instruction code RD
    input  [31:0] Wdata,  // instruction code rf_we  
    input         rf_we,  // registerfile write enable
    output [31:0] RD1,    // register file RS1 output
    output [31:0] RD2     // register file RS2 output
);

    logic [31:0] register_file[1:31];  // x0 must have zero value

`ifdef SIMULATION
    initial begin
        for (int i = 0; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif

    always_ff @(posedge clk) begin
        if (rf_we) begin
            register_file[WA] = Wdata;
        end
    end

    // output CL
    assign RD1 = (RA1 != 0) ? register_file[RA1] : 0;
    assign RD2 = (RA2 != 0) ? register_file[RA2] : 0;

endmodule

module alu (
    input        [31:0] rd1,          // RS1
    input        [31:0] rd2,          // RS2
    input        [ 3:0] alu_control,  // funct7[5], funct3 : 4bit
    output logic [31:0] alu_result,   // alu_result
    output logic        b_taken
);

    always_comb begin
        alu_result = 32'b0;
        case (alu_control)
            `ADD: alu_result = rd1 + rd2;  // add rd = rs1 + rs2
            `SUB: alu_result = rd1 - rd2;  // sub rd = rs1 - rs2
            `SLL: alu_result = rd1 << rd2[4:0];  // sll rd = rs1 << rs2
            `SLT:
            alu_result = ($signed(rd1) < $signed(rd2)) ? 1 :
                0;  // slt rd = (rs1 < rs2)?1:0, zero-extends
            `SLTU:
            alu_result = (rd1 < rd2) ? 1 : 0;  // sltu rd = (rs1 < rs2)?1:0
            `XOR: alu_result = rd1 ^ rd2;  // xor rd = rs1 ^ rs2
            `SRL: alu_result = rd1 >> rd2[4:0];  // srl rd = rs1 >> rs2
            `SRA:
            alu_result = $signed(rd1) >>> rd2[4:0]
                ;  // sra rd = rs1 >> rs2, msb extention, arithmetic right shift
            `OR: alu_result = rd1 | rd2;  // or rd = rs1 | rs2
            `AND: alu_result = rd1 & rd2;  // and rd = rs1 & rs2
        endcase
    end

    always_comb begin
        b_taken = 0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) b_taken = 1;  // true : pc = pc + imm
                else b_taken = 0;  // false : pc = pc + 4
            end
            `BNE: begin
                if (rd1 != rd2) b_taken = 1;  // true : pc = pc + imm
                else b_taken = 0;  // false : pc = pc + 4
            end
            `BLT: begin
                if (rd1 < rd2) b_taken = 1;  // true : pc = pc + imm
                else b_taken = 0;  // false : pc = pc + 4
            end
            `BGE: begin
                if (rd1 >= rd2) b_taken = 1;  // true : pc = pc + imm
                else b_taken = 0;  // false : pc = pc + 4
            end
            `BLTU: begin
                if ($signed(rd1) < $signed(rd2))
                    b_taken = 1;  // true : pc = pc + imm
                else b_taken = 0;  // false : pc = pc + 4
            end
            `BGEU: begin
                if ($signed(rd1) >= $signed(rd2))
                    b_taken = 1;  // true : pc = pc + imm
                else b_taken = 0;  // false : pc = pc + 4
            end
        endcase
    end
endmodule

module program_counter (
    input               clk,
    input               rst,
    input               pc_en,            // from Control unit for PC register
    input               b_taken,          // from alu for B-type
    input               branch,           // from control unit for B-type
    input               jal,
    input               jalr,
    input        [31:0] imm_data,
    input        [31:0] rs1,
    //input        [31:0] instr_addr,
    output logic [31:0] program_counter,
    output logic [31:0] pc_4_out,         // for JAL type, pc +4
    output logic [31:0] pc_imm_out        // for AUIPC type, pc + imm
);

    logic [31:0] pc_next, pc_jtype, o_exe_pcnext;

    // execute
    // jalr mux
    mux_2x1 PC_JTYPE_MUX (
        .in0    (program_counter),  // sel 0
        .in1    (rs1),              // sel 1
        .mux_sel(jalr),
        .out_mux(pc_jtype)
    );

    pc_alu U_PC_IMM (
        .a         (imm_data),
        .b         (pc_jtype),
        .pc_alu_out(pc_imm_out)
    );

    pc_alu U_PC_4 (
        .a         (32'd4),
        .b         (program_counter),
        .pc_alu_out(pc_4_out)
    );

    mux_2x1 PC_NEXT_MUX (
        .in0    (pc_4_out),                  // sel 0
        .in1    (pc_imm_out),                // sel 1
        .mux_sel(jal | (b_taken & branch)),
        .out_mux(pc_next)
    );

    register U_PCNEXT_REG (
        .clk     (clk),
        .rst     (rst),
        .data_in (pc_next),
        .data_out(o_exe_pcnext)
    );

    // fetch
    register_en U_PC_REG (
        .clk     (clk),
        .rst     (rst),
        .en      (pc_en),
        .data_in (o_exe_pcnext),
        .data_out(program_counter)
    );

endmodule

module register (
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;

endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);

    assign pc_alu_out = a + b;

endmodule

module mux_2x1 (
    input        [31:0] in0,      // sel 0
    input        [31:0] in1,      // sel 1
    input               mux_sel,
    output logic [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;

endmodule

module register_en (
    input         clk,
    input         rst,
    input         en,
    input  [31:0] data_in,
    output [31:0] data_out
);
    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            if (en) begin
                register <= data_in;
            end
        end
    end

    assign data_out = register;

endmodule
