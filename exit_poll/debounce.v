`timescale 1ns/1ps
module debounce #(
    parameter integer CLK_HZ   = 50_000_000,
    parameter integer STABLE_MS = 20
)(
    input  wire clk,
    input  wire rst,
    input  wire noisy_in,
    output reg  clean_out
);
    localparam integer MAX_CNT = (CLK_HZ / 1000) * STABLE_MS;
    localparam CNT_W = $clog2(MAX_CNT + 1);

    reg [CNT_W-1:0] cnt;
    reg             sync0, sync1;

    always @(posedge clk) begin
        if (rst) begin sync0 <= 0; sync1 <= 0; end
        else     begin sync0 <= noisy_in; sync1 <= sync0; end
    end

    always @(posedge clk) begin
        if (rst) begin
            cnt       <= 0;
            clean_out <= 0;
        end else if (sync1 != clean_out) begin
            if (cnt == MAX_CNT - 1) begin
                clean_out <= sync1;
                cnt       <= 0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end else begin
            cnt <= 0;
        end
    end
endmodule
