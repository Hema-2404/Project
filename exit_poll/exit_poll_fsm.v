`timescale 1ns/1ps
module exit_poll_fsm (
    input  wire       clk,
    input  wire       rst,          
    input  wire       next_pulse,  
    input  wire       action_pulse,  
    output reg  [1:0] mode,          
    output wire       accept_action, 
    output reg        cast_done      
);
    
    localparam IDLE    = 2'd0;
    localparam PREDICT = 2'd1;
    localparam VOTE    = 2'd2;
    localparam RESULT  = 2'd3;

   
    assign accept_action = (mode == PREDICT || mode == VOTE) && !cast_done;

   
    always @(posedge clk) begin
        if (rst)
            cast_done <= 1'b0;
        else if (action_pulse && accept_action)
            cast_done <= 1'b1;
        else if (next_pulse)
            cast_done <= 1'b0;   
    end


    always @(posedge clk) begin
        if (rst) begin
            mode <= IDLE;
        end else if (next_pulse && !cast_done) begin
            case (mode)
                IDLE    : mode <= PREDICT;
                PREDICT : mode <= VOTE;
                VOTE    : mode <= RESULT;
                RESULT  : mode <= PREDICT;  
                default : mode <= IDLE;
            endcase
        end
    end

endmodule
