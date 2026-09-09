`timescale 1ns/1ps

module poll_renderer #(
    parameter COUNT_W = 8
)(
    input  wire [9:0]           x,
    input  wire [9:0]           y,
    input  wire                 active,
    input  wire [1:0]           mode,
    input  wire [2:0]           pred_winner,
    input  wire [2:0]           vote_winner,

    input  wire [COUNT_W-1:0]   pred_dmk,
    input  wire [COUNT_W-1:0]   pred_admk,
    input  wire [COUNT_W-1:0]   pred_tvk,
    input  wire [COUNT_W-1:0]   pred_ntk,
    input  wire [COUNT_W-1:0]   pred_other,

  
    input  wire [COUNT_W-1:0]   vote_dmk,
    input  wire [COUNT_W-1:0]   vote_admk,
    input  wire [COUNT_W-1:0]   vote_tvk,
    input  wire [COUNT_W-1:0]   vote_ntk,
    input  wire [COUNT_W-1:0]   vote_other,

    output reg  [3:0]           r,
    output reg  [3:0]           g,
    output reg  [3:0]           b
);
    // Mode constants
    localparam IDLE    = 2'd0;
    localparam PREDICT = 2'd1;
    localparam VOTE    = 2'd2;
    localparam RESULT  = 2'd3;

  
    function in_rect;
        input [9:0] px, py, x0, y0, w, h;
        begin
            in_rect = (px >= x0) && (px < x0 + w) &&
                      (py >= y0) && (py < y0 + h);
        end
    endfunction

    wire [9:0] bw_pred_dmk   = ({1'b0, pred_dmk,   1'b0} > 10'd510) ? 10'd510 : {1'b0, pred_dmk,   1'b0};
    wire [9:0] bw_pred_admk  = ({1'b0, pred_admk,  1'b0} > 10'd510) ? 10'd510 : {1'b0, pred_admk,  1'b0};
    wire [9:0] bw_pred_tvk   = ({1'b0, pred_tvk,   1'b0} > 10'd510) ? 10'd510 : {1'b0, pred_tvk,   1'b0};
    wire [9:0] bw_pred_ntk   = ({1'b0, pred_ntk,   1'b0} > 10'd510) ? 10'd510 : {1'b0, pred_ntk,   1'b0};
    wire [9:0] bw_pred_other = ({1'b0, pred_other, 1'b0} > 10'd510) ? 10'd510 : {1'b0, pred_other, 1'b0};

    wire [9:0] bw_vote_dmk   = ({1'b0, vote_dmk,   1'b0} > 10'd510) ? 10'd510 : {1'b0, vote_dmk,   1'b0};
    wire [9:0] bw_vote_admk  = ({1'b0, vote_admk,  1'b0} > 10'd510) ? 10'd510 : {1'b0, vote_admk,  1'b0};
    wire [9:0] bw_vote_tvk   = ({1'b0, vote_tvk,   1'b0} > 10'd510) ? 10'd510 : {1'b0, vote_tvk,   1'b0};
    wire [9:0] bw_vote_ntk   = ({1'b0, vote_ntk,   1'b0} > 10'd510) ? 10'd510 : {1'b0, vote_ntk,   1'b0};
    wire [9:0] bw_vote_other = ({1'b0, vote_other, 1'b0} > 10'd510) ? 10'd510 : {1'b0, vote_other, 1'b0};

  
    always @(*) begin
        if (!active) begin
            r = 4'h0; g = 4'h0; b = 4'h0;
        end else begin
           
            r = 4'hF; g = 4'hF; b = 4'hF;

           
            if (in_rect(x, y, 10'd40, 10'd420, 10'd560, 10'd40)) begin
                if (mode == RESULT) begin
                    if (pred_winner == vote_winner) begin
                        r = 4'h0; g = 4'h7; b = 4'h4; // green
                    end else begin
                        r = 4'h8; g = 4'h0; b = 4'h0; // maroon
                    end
                end else begin
                    r = 4'hE; g = 4'hE; b = 4'hE;     // light grey
                end
            end

            
            if (in_rect(x, y, 10'd40, 10'd250, 10'd560, 10'd2)) begin
                r = 4'h0; g = 4'h0; b = 4'h4;
            end

          
            if (in_rect(x, y, 10'd50, 10'd270, 10'd60, 10'd18)) begin r=4'hF; g=4'h4; b=4'h4; end // DMK
            if (in_rect(x, y, 10'd50, 10'd295, 10'd60, 10'd18)) begin r=4'h3; g=4'hB; b=4'h3; end // ADMK
            if (in_rect(x, y, 10'd50, 10'd320, 10'd60, 10'd18)) begin r=4'hF; g=4'hB; b=4'h0; end // TVK
            if (in_rect(x, y, 10'd50, 10'd345, 10'd60, 10'd18)) begin r=4'h9; g=4'h1; b=4'h1; end // NTK
            if (in_rect(x, y, 10'd50, 10'd370, 10'd60, 10'd18)) begin r=4'h7; g=4'h7; b=4'h7; end // Other

          
            if (bw_vote_dmk   > 0 && in_rect(x, y, 10'd130, 10'd270, bw_vote_dmk,   10'd18)) begin r=4'hD; g=4'h0; b=4'h0; end
            if (bw_vote_admk  > 0 && in_rect(x, y, 10'd130, 10'd295, bw_vote_admk,  10'd18)) begin r=4'h0; g=4'h8; b=4'h0; end
            if (bw_vote_tvk   > 0 && in_rect(x, y, 10'd130, 10'd320, bw_vote_tvk,   10'd18)) begin r=4'hD; g=4'h8; b=4'h0; end
            if (bw_vote_ntk   > 0 && in_rect(x, y, 10'd130, 10'd345, bw_vote_ntk,   10'd18)) begin r=4'h7; g=4'h0; b=4'h0; end
            if (bw_vote_other > 0 && in_rect(x, y, 10'd130, 10'd370, bw_vote_other, 10'd18)) begin r=4'h4; g=4'h4; b=4'h4; end

            
            if (in_rect(x, y, 10'd40, 10'd70, 10'd560, 10'd2)) begin
                r = 4'h0; g = 4'h0; b = 4'h4;
            end

            if (in_rect(x, y, 10'd50, 10'd90,  10'd60, 10'd18)) begin r=4'hF; g=4'h4; b=4'h4; end // DMK
            if (in_rect(x, y, 10'd50, 10'd115, 10'd60, 10'd18)) begin r=4'h3; g=4'hB; b=4'h3; end // ADMK
            if (in_rect(x, y, 10'd50, 10'd140, 10'd60, 10'd18)) begin r=4'hF; g=4'hB; b=4'h0; end // TVK
            if (in_rect(x, y, 10'd50, 10'd165, 10'd60, 10'd18)) begin r=4'h9; g=4'h1; b=4'h1; end // NTK
            if (in_rect(x, y, 10'd50, 10'd190, 10'd60, 10'd18)) begin r=4'h7; g=4'h7; b=4'h7; end // Other

            
            if (bw_pred_dmk   > 0 && in_rect(x, y, 10'd130, 10'd90,  bw_pred_dmk,   10'd18)) begin r=4'hF; g=4'h4; b=4'h4; end
            if (bw_pred_admk  > 0 && in_rect(x, y, 10'd130, 10'd115, bw_pred_admk,  10'd18)) begin r=4'h3; g=4'hB; b=4'h3; end
            if (bw_pred_tvk   > 0 && in_rect(x, y, 10'd130, 10'd140, bw_pred_tvk,   10'd18)) begin r=4'hF; g=4'hB; b=4'h0; end
            if (bw_pred_ntk   > 0 && in_rect(x, y, 10'd130, 10'd165, bw_pred_ntk,   10'd18)) begin r=4'h9; g=4'h1; b=4'h1; end
            if (bw_pred_other > 0 && in_rect(x, y, 10'd130, 10'd190, bw_pred_other, 10'd18)) begin r=4'h7; g=4'h7; b=4'h7; end

          
            if (in_rect(x, y, 10'd0, 10'd0, 10'd640, 10'd48)) begin
                case (mode)
                    IDLE    : begin r=4'h1; g=4'h1; b=4'h3; end // dark navy
                    PREDICT : begin r=4'h0; g=4'h2; b=4'h7; end // deep blue
                    VOTE    : begin r=4'h0; g=4'h5; b=4'h3; end // dark green
                    RESULT  : begin r=4'h7; g=4'h0; b=4'h0; end // dark maroon
                    default : begin r=4'h1; g=4'h1; b=4'h3; end
                endcase
            end
        end
    end
endmodule
