`timescale 1ns/1ps
module edge_detect (
    input  wire clk,
    input  wire rst,
    input  wire sig,
    output wire rising_pulse   // one cycle HIGH on rising edge of sig
);
    reg sig_d;
    always @(posedge clk) begin
        if (rst) sig_d <= 1'b0;
        else     sig_d <= sig;
    end
    assign rising_pulse = sig & ~sig_d;
endmodule
