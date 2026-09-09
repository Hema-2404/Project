`timescale 1ns/1ps

module vga_sync_640x480 (
    input  wire clk,
    input  wire pix_ce,
    input  wire rst,
    output reg [9:0] x,
    output reg [9:0] y,
    output wire hsync,
    output wire vsync,
    output wire active
);

    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else if (pix_ce) begin
            if (x == 799) begin
                x <= 0;
                if (y == 524) y <= 0;
                else y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end

    assign hsync = ~(x >= 656 && x < 752);
    assign vsync = ~(y >= 490 && y < 492);
    assign active = (x < 640 && y < 480);

endmodule
