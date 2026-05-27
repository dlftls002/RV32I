`timescale 1ns / 1ps

module data_mem (
    input               clk,
    input               d_we,
    input        [ 2:0] i_funct3,
    input        [31:0] d_addr,
    input        [31:0] d_wdata,
    output logic [31:0] d_rdata
);
    // // byte address
    // logic [7:0] data_mem[0:31];

    // always_ff @(posedge clk, posedge rst) begin
    //     if (rst) begin

    //     end else begin
    //         if (d_we) begin
    //             data_mem[d_waddr+0] <= d_wdata[7:0];
    //             data_mem[d_waddr+1] <= d_wdata[15:8];
    //             data_mem[d_waddr+2] <= d_wdata[23:16];
    //             data_mem[d_waddr+3] <= d_wdata[31:24];
    //         end
    //     end
    // end

    // assign d_rdata = {
    //     data_mem[d_waddr],
    //     data_mem[d_waddr+1],
    //     data_mem[d_waddr+2],
    //     data_mem[d_waddr+3]
    // };

    // word address
    // logic [31:0] data_mem[0:31];
    logic [31:0] data_mem[0:255];

    // S type
    always_ff @(posedge clk) begin
        if (d_we) begin
            if (i_funct3 == 3'b010) begin  // SW
                data_mem[d_addr[31:2]] <= d_wdata;
            end
            if (i_funct3 == 3'b001) begin  // SH
                case (d_addr[1])
                    1'b0:  // 0
                    data_mem[d_addr[31:2]] <= {
                        data_mem[d_addr[31:2]][31:16], d_wdata[15:0]
                    };
                    1'b1:  // 2
                    data_mem[d_addr[31:2]] <= {
                        d_wdata[15:0], data_mem[d_addr[31:2]][15:0]
                    };
                endcase
            end
            if (i_funct3 == 3'b000) begin  // SB
                case (d_addr[1:0])
                    2'b00:  // 0
                    data_mem[d_addr[31:2]] <= {
                        data_mem[d_addr[31:2]][31:8], d_wdata[7:0]
                    };
                    2'b01:  // 1
                    data_mem[d_addr[31:2]] <= {
                        data_mem[d_addr[31:2]][31:16],
                        d_wdata[7:0],
                        data_mem[d_addr[31:2]][7:0]
                    };
                    2'b10:  // 2
                    data_mem[d_addr[31:2]] <= {
                        data_mem[d_addr[31:2]][31:24],
                        d_wdata[7:0],
                        data_mem[d_addr[31:2]][15:0]
                    };
                    2'b11:  // 3
                    data_mem[d_addr[31:2]] <= {
                        d_wdata[7:0], data_mem[d_addr[31:2]][23:0]
                    };
                endcase
            end
        end
    end

    // I_L type
    always_comb begin
        d_rdata = 32'b0;    // delect latch
        if (!d_we) begin
            if (i_funct3 == 3'b010) begin  // LW
                d_rdata = data_mem[d_addr[31:2]];
            end
            if (i_funct3 == 3'b001) begin  // LH
                case (d_addr[1:0])
                    2'b00: d_rdata = {{16{data_mem[d_addr[31:2]][15]}}, data_mem[d_addr[31:2]][15:0]};
                    2'b10: d_rdata = {{16{data_mem[d_addr[31:2]][31]}}, data_mem[d_addr[31:2]][31:16]};
                endcase
            end
            if (i_funct3 == 3'b000) begin  // LB
                case (d_addr[1:0])
                    2'b00: d_rdata = {{24{data_mem[d_addr[31:2]][7]}},  data_mem[d_addr[31:2]][7:0]};
                    2'b01: d_rdata = {{24{data_mem[d_addr[31:2]][15]}}, data_mem[d_addr[31:2]][15:8]};
                    2'b10: d_rdata = {{24{data_mem[d_addr[31:2]][23]}}, data_mem[d_addr[31:2]][23:16]};
                    2'b11: d_rdata = {{24{data_mem[d_addr[31:2]][31]}}, data_mem[d_addr[31:2]][31:24]};
                endcase
            end
            if (i_funct3 == 3'b101) begin  // LHU
                case (d_addr[1:0])
                    2'b00: d_rdata = {16'b0, data_mem[d_addr[31:2]][15:0]};
                    2'b10: d_rdata = {16'b0, data_mem[d_addr[31:2]][31:16]};
                endcase
            end
            if (i_funct3 == 3'b100) begin  // LBU
                case (d_addr[1:0])
                    2'b00: d_rdata = {24'b0, data_mem[d_addr[31:2]][7:0]};
                    2'b01: d_rdata = {24'b0, data_mem[d_addr[31:2]][15:8]};
                    2'b10: d_rdata = {24'b0, data_mem[d_addr[31:2]][23:16]};
                    2'b11: d_rdata = {24'b0, data_mem[d_addr[31:2]][31:24]};
                endcase
            end
        end
    end

    // assign d_rdata = data_mem[d_addr[31:2]];

endmodule
