`timescale 1ns/1ps

module seg7_controller #(
    parameter integer CLK_HZ = 50_000_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] mode,
    input  wire [2:0] pred_winner,   // 0-4
    input  wire [2:0] vote_winner,   // 0-4
    input  wire [7:0] pred_max,      // count of predicted winner
    input  wire [7:0] vote_max,      // count of actual winner

    output reg  [3:0] an,    // digit anodes, active-LOW, one-hot-0
    output reg  [7:0] seg    // {dp,g,f,e,d,c,b,a}, active-LOW
);
    // ---- Mode constants ----
    localparam IDLE    = 2'd0;
    localparam PREDICT = 2'd1;
    localparam VOTE    = 2'd2;
    localparam RESULT  = 2'd3;

    // ---- Scan divider: 1 ms per digit ----
    localparam integer SCAN_DIV = CLK_HZ / 1000;  // 50,000 @ 50 MHz
    localparam SD_W = $clog2(SCAN_DIV + 1);

    reg [SD_W-1:0] scan_cnt;
    reg [1:0]      digit_sel;  // 0=rightmost an[0] .. 3=leftmost an[3]

    always @(posedge clk) begin
        if (rst) begin
            scan_cnt  <= 0;
            digit_sel <= 0;
        end else begin
            if (scan_cnt == SCAN_DIV - 1) begin
                scan_cnt  <= 0;
                digit_sel <= digit_sel + 1'b1;
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    // ---- 7-segment encoding (active-low, common-anode) ----
    // seg[7:0] = {dp, g, f, e, d, c, b, a}
    function [7:0] enc7;
        input [3:0] d;
        case (d)
            4'h0: enc7 = 8'hC0;
            4'h1: enc7 = 8'hF9;
            4'h2: enc7 = 8'hA4;
            4'h3: enc7 = 8'hB0;
            4'h4: enc7 = 8'h99;
            4'h5: enc7 = 8'h92;
            4'h6: enc7 = 8'h82;
            4'h7: enc7 = 8'hF8;
            4'h8: enc7 = 8'h80;
            4'h9: enc7 = 8'h90;
            default: enc7 = 8'hFF; // blank
        endcase
    endfunction

    // Special glyphs
    localparam SEG_P     = 8'h8C;
    localparam SEG_V     = 8'hC1;
    localparam SEG_E     = 8'h86;
    localparam SEG_BLANK = 8'hFF;
    localparam SEG_DASH  = 8'hBF;

    // Party number 1-5 encoding (winner_index + 1)
    function [7:0] party_digit;
        input [2:0] idx;
        case (idx)
            3'd0: party_digit = enc7(4'd1);
            3'd1: party_digit = enc7(4'd2);
            3'd2: party_digit = enc7(4'd3);
            3'd3: party_digit = enc7(4'd4);
            3'd4: party_digit = enc7(4'd5);
            default: party_digit = SEG_BLANK;
        endcase
    endfunction

    // ---- Determine what each digit position should show ----
    // Digit 3 (left) = an[3], Digit 0 (right) = an[0]
    reg [7:0] d3, d2, d1, d0;

    always @(*) begin
        case (mode)
            IDLE: begin
                d3 = SEG_BLANK; d2 = SEG_BLANK;
                d1 = SEG_BLANK; d0 = SEG_BLANK;
            end
            PREDICT: begin
                d3 = SEG_P;
                d2 = party_digit(pred_winner);
                d1 = enc7(pred_max[7:4]);
                d0 = enc7(pred_max[3:0]);
            end
            VOTE: begin
                d3 = SEG_V;
                d2 = party_digit(vote_winner);
                d1 = enc7(vote_max[7:4]);
                d0 = enc7(vote_max[3:0]);
            end
            RESULT: begin
                d3 = SEG_E;
                d2 = party_digit(vote_winner);       // vote winner
                d1 = party_digit(pred_winner);       // pred winner
                // match flag: 1 if same, 0 if different
                d0 = (pred_winner == vote_winner) ? enc7(4'd1) : enc7(4'd0);
            end
            default: begin
                d3 = SEG_BLANK; d2 = SEG_BLANK;
                d1 = SEG_BLANK; d0 = SEG_BLANK;
            end
        endcase
    end

    // ---- Mux to active digit ----
    always @(posedge clk) begin
        if (rst) begin
            an  <= 4'hF;
            seg <= SEG_BLANK;
        end else begin
            case (digit_sel)
                2'd0: begin an <= 4'b1110; seg <= d0; end  // digit 0 active
                2'd1: begin an <= 4'b1101; seg <= d1; end  // digit 1 active
                2'd2: begin an <= 4'b1011; seg <= d2; end  // digit 2 active
                2'd3: begin an <= 4'b0111; seg <= d3; end  // digit 3 active
            endcase
        end
    end
endmodule
