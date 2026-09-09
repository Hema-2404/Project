`timescale 1ns/1ps

module poll_counters #(
    parameter COUNT_W = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  clear,
    input  wire                  predict_pulse,
    input  wire                  vote_pulse,
    input  wire [2:0]            party_sel,

    output reg  [COUNT_W-1:0]    pred_dmk,
    output reg  [COUNT_W-1:0]    pred_admk,
    output reg  [COUNT_W-1:0]    pred_tvk,
    output reg  [COUNT_W-1:0]    pred_ntk,
    output reg  [COUNT_W-1:0]    pred_other,

    output reg  [COUNT_W-1:0]    vote_dmk,
    output reg  [COUNT_W-1:0]    vote_admk,
    output reg  [COUNT_W-1:0]    vote_tvk,
    output reg  [COUNT_W-1:0]    vote_ntk,
    output reg  [COUNT_W-1:0]    vote_other
);

    always @(posedge clk) begin
        if (rst == 1'b1 || clear == 1'b1) begin
            // Reset all counters
            pred_dmk   <= {COUNT_W{1'b0}};
            pred_admk  <= {COUNT_W{1'b0}};
            pred_tvk   <= {COUNT_W{1'b0}};
            pred_ntk   <= {COUNT_W{1'b0}};
            pred_other <= {COUNT_W{1'b0}};
            vote_dmk   <= {COUNT_W{1'b0}};
            vote_admk  <= {COUNT_W{1'b0}};
            vote_tvk   <= {COUNT_W{1'b0}};
            vote_ntk   <= {COUNT_W{1'b0}};
            vote_other <= {COUNT_W{1'b0}};
        end else begin

          
            if (predict_pulse == 1'b1) begin
                case (party_sel)
                    3'd0: pred_dmk   <= pred_dmk   + 1'b1;
                    3'd1: pred_admk  <= pred_admk  + 1'b1;
                    3'd2: pred_tvk   <= pred_tvk   + 1'b1;
                    3'd3: pred_ntk   <= pred_ntk   + 1'b1;
                    3'd4: pred_other <= pred_other + 1'b1;
                    default: begin end  // >=5: silently ignore
                endcase
            end

      
            if (vote_pulse == 1'b1) begin
                case (party_sel)
                    3'd0: vote_dmk   <= vote_dmk   + 1'b1;
                    3'd1: vote_admk  <= vote_admk  + 1'b1;
                    3'd2: vote_tvk   <= vote_tvk   + 1'b1;
                    3'd3: vote_ntk   <= vote_ntk   + 1'b1;
                    3'd4: vote_other <= vote_other + 1'b1;
                    default: begin end
                endcase
            end

        end
    end

endmodule
