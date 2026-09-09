`timescale 1ns/1ps

module password_lock_system #(
    parameter PW0 = 4'd1,
    parameter PW1 = 4'd2,
    parameter PW2 = 4'd3,
    parameter PW3 = 4'd4,
    parameter MAX_ATTEMPTS = 3,
    parameter ERROR_TICKS  = 1
)(
    input        clk,
    input        rst,

    input        digit_valid,
    input  [3:0] digit,

    input        enter,
    input        clear,
    input        lock_cmd,

    output reg   unlocked,
    output reg   alarm,
    output reg   error,

    output reg [2:0] state_dbg
);

    localparam S_LOCKED     = 3'b000;
    localparam S_DIGIT1     = 3'b001;
    localparam S_DIGIT2     = 3'b010;
    localparam S_DIGIT3     = 3'b011;
    localparam S_WAIT_ENTER = 3'b100;
    localparam S_UNLOCKED   = 3'b101;
    localparam S_ERROR      = 3'b110;
    localparam S_ALARM      = 3'b111;

    reg [2:0] state, next_state;

   

    reg [3:0] entered0;
    reg [3:0] entered1;
    reg [3:0] entered2;
    reg [2:0] attempts;
    reg [31:0] error_count;

  

    always @(posedge clk) begin

        if (rst) begin
            state       <= S_LOCKED;

            entered0    <= 4'd0;
            entered1    <= 4'd0;
            entered2    <= 4'd0;

            attempts    <= 3'd0;
            error_count <= 32'd0;
        end

        else begin

            state <= next_state;
            if (state == S_LOCKED) begin

                if (digit_valid && digit == PW0) begin
                    entered0 <= digit;
                end

            end

            else if (state == S_DIGIT1) begin

                if (digit_valid) begin
                    entered1 <= digit;
                end

            end

            else if (state == S_DIGIT2) begin

                if (digit_valid) begin
                    entered2 <= digit;
                end

            end

            if (state != S_ERROR) begin
                error_count <= 32'd0;
            end

            else begin
                if (error_count < ERROR_TICKS)
                    error_count <= error_count + 1'b1;
            end

            if (state == S_ERROR &&
                next_state == S_LOCKED) begin

                if (attempts < MAX_ATTEMPTS)
                    attempts <= attempts + 1'b1;
            end

            if (state == S_ALARM && clear) begin
                attempts <= 3'd0;
            end

        end
    end


    always @(*) begin

        // Default: remain in current state
        next_state = state;

        case (state)

    

            S_LOCKED: begin

                if (digit_valid) begin

                    if (digit == PW0)
                        next_state = S_DIGIT1;
                    else
                        next_state = S_ERROR;

                end

            end


            S_DIGIT1: begin

                if (enter) begin
                    // Enter before all digits are entered
                    next_state = S_ERROR;
                end

                else if (digit_valid) begin

                    if (digit == PW1)
                        next_state = S_DIGIT2;
                    else
                        next_state = S_ERROR;

                end

            end



            S_DIGIT2: begin

                if (enter) begin
                    next_state = S_ERROR;
                end

                else if (digit_valid) begin

                    if (digit == PW2)
                        next_state = S_DIGIT3;
                    else
                        next_state = S_ERROR;

                end

            end



            S_DIGIT3: begin

                if (enter) begin
                    next_state = S_ERROR;
                end

                else if (digit_valid) begin

                    if (digit == PW3)
                        next_state = S_WAIT_ENTER;
                    else
                        next_state = S_ERROR;

                end

            end


            S_WAIT_ENTER: begin

                if (enter)
                    next_state = S_UNLOCKED;

            end


            S_UNLOCKED: begin

                if (lock_cmd)
                    next_state = S_LOCKED;

            end


            S_ERROR: begin

                if (error_count >= ERROR_TICKS - 1) begin

                    if (attempts + 1 >= MAX_ATTEMPTS)
                        next_state = S_ALARM;
                    else
                        next_state = S_LOCKED;

                end

            end


            S_ALARM: begin

                if (clear)
                    next_state = S_LOCKED;

            end


            default: begin
                next_state = S_LOCKED;
            end

        endcase

    end


    always @(*) begin

        // Default outputs
        unlocked  = 1'b0;
        alarm     = 1'b0;
        error     = 1'b0;

        case (state)

            S_UNLOCKED: begin
                unlocked = 1'b1;
            end

            S_ERROR: begin
                error = 1'b1;
            end

            S_ALARM: begin
                alarm = 1'b1;
            end

            default: begin
                unlocked = 1'b0;
                alarm    = 1'b0;
                error    = 1'b0;
            end

        endcase

    end
    always @(*) begin
        state_dbg = state;
    end

endmodule
