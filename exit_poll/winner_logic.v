`timescale 1ns/1ps
// ============================================================
// winner_logic.v
// Purely combinational 5-way maximum finder.
// Tie-break: lower index wins (DMK < ADMK < TVK < NTK < Other).
// Instantiated twice: once for predictions, once for votes.
// ============================================================
module winner_logic #(
    parameter COUNT_W = 8
)(
    input  wire [COUNT_W-1:0] c0,   // DMK
    input  wire [COUNT_W-1:0] c1,   // ADMK
    input  wire [COUNT_W-1:0] c2,   // TVK
    input  wire [COUNT_W-1:0] c3,   // NTK
    input  wire [COUNT_W-1:0] c4,   // Other

    output reg  [2:0]         winner,
    output reg  [COUNT_W-1:0] max_count
);
    always @(*) begin
        // Start with party 0 (DMK)
        winner    = 3'd0;
        max_count = c0;

        // Strict greater-than keeps lower index on tie
        if (c1 > max_count) begin winner = 3'd1; max_count = c1; end
        if (c2 > max_count) begin winner = 3'd2; max_count = c2; end
        if (c3 > max_count) begin winner = 3'd3; max_count = c3; end
        if (c4 > max_count) begin winner = 3'd4; max_count = c4; end
    end
endmodule
