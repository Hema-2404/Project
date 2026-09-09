`timescale 1ns/1ps
module exit_poll_top (
    input  wire        clk,
    input  wire        rst_btn,
    input  wire        next_btn,
    input  wire        action_btn,
    input  wire        clear_btn,
    input  wire [2:0]  party_sel,

    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire        hsync,
    output wire        vsync,

    output wire [3:0]  an,
    output wire [7:0]  seg,
    output wire [15:0] led
);
    localparam integer CLK_HZ  = 50_000_000;
    localparam integer COUNT_W = 8;

    wire rst = rst_btn;

  
    reg pix_phase;
    always @(posedge clk) begin
        if (rst) pix_phase <= 1'b0;
        else     pix_phase <= ~pix_phase;
    end
    wire pix_ce = pix_phase;

 
    wire next_clean, action_clean, clear_clean;

    debounce #(.CLK_HZ(CLK_HZ)) db_next   (.clk(clk),.rst(rst),.noisy_in(next_btn),  .clean_out(next_clean));
    debounce #(.CLK_HZ(CLK_HZ)) db_action (.clk(clk),.rst(rst),.noisy_in(action_btn),.clean_out(action_clean));
    debounce #(.CLK_HZ(CLK_HZ)) db_clear  (.clk(clk),.rst(rst),.noisy_in(clear_btn), .clean_out(clear_clean));

    wire next_pulse, action_pulse, clear_pulse;  // ← internal wires only

    edge_detect ed_next   (.clk(clk),.rst(rst),.sig(next_clean),  .rising_pulse(next_pulse));
    edge_detect ed_action (.clk(clk),.rst(rst),.sig(action_clean),.rising_pulse(action_pulse));
    edge_detect ed_clear  (.clk(clk),.rst(rst),.sig(clear_clean), .rising_pulse(clear_pulse));

    wire [1:0] mode;
    wire       accept_action;  // ← internal wire only
    wire       cast_done;      // ← internal wire only

    exit_poll_fsm fsm (
        .clk          (clk),
        .rst          (rst),
        .next_pulse   (next_pulse),
        .action_pulse (action_pulse),
        .mode         (mode),
        .accept_action(accept_action),
        .cast_done    (cast_done)
    );

 
    wire predict_pulse = action_pulse & accept_action & (mode == 2'd1);
    wire vote_pulse    = action_pulse & accept_action & (mode == 2'd2);

   
    wire [COUNT_W-1:0] pd, pa, pt, pn, po;
    wire [COUNT_W-1:0] vd, va, vt, vn, vo;

    poll_counters #(.COUNT_W(COUNT_W)) counters (
        .clk           (clk),
        .rst           (rst),
        .clear         (clear_pulse),
        .predict_pulse (predict_pulse),
        .vote_pulse    (vote_pulse),
        .party_sel     (party_sel),
        .pred_dmk(pd),.pred_admk(pa),.pred_tvk(pt),.pred_ntk(pn),.pred_other(po),
        .vote_dmk(vd),.vote_admk(va),.vote_tvk(vt),.vote_ntk(vn),.vote_other(vo)
    );


    wire [2:0]         pred_winner, vote_winner;
    wire [COUNT_W-1:0] pred_max, vote_max;

    winner_logic #(.COUNT_W(COUNT_W)) w_pred (
        .c0(pd),.c1(pa),.c2(pt),.c3(pn),.c4(po),
        .winner(pred_winner),.max_count(pred_max)
    );
    winner_logic #(.COUNT_W(COUNT_W)) w_vote (
        .c0(vd),.c1(va),.c2(vt),.c3(vn),.c4(vo),
        .winner(vote_winner),.max_count(vote_max)
    );

   
    wire [9:0] vga_x, vga_y;
    wire       vga_active;

    vga_sync_640x480 vga_sync (
        .clk(clk),.pix_ce(pix_ce),.rst(rst),
        .x(vga_x),.y(vga_y),
        .hsync(hsync),.vsync(vsync),.active(vga_active)
    );

    poll_renderer #(.COUNT_W(COUNT_W)) renderer (
        .x(vga_x),.y(vga_y),.active(vga_active),
        .mode(mode),
        .pred_winner(pred_winner),.vote_winner(vote_winner),
        .pred_dmk(pd),.pred_admk(pa),.pred_tvk(pt),.pred_ntk(pn),.pred_other(po),
        .vote_dmk(vd),.vote_admk(va),.vote_tvk(vt),.vote_ntk(vn),.vote_other(vo),
        .r(vga_r),.g(vga_g),.b(vga_b)
    );


    seg7_controller #(.CLK_HZ(CLK_HZ)) seg7 (
        .clk(clk),.rst(rst),.mode(mode),
        .pred_winner(pred_winner),.vote_winner(vote_winner),
        .pred_max(pred_max),.vote_max(vote_max),
        .an(an),.seg(seg)
    );


    reg [COUNT_W-1:0] sel_pred_count, sel_vote_count, display_count;

    always @(*) begin
        case (party_sel)
            3'd0: begin sel_pred_count = pd; sel_vote_count = vd; end
            3'd1: begin sel_pred_count = pa; sel_vote_count = va; end
            3'd2: begin sel_pred_count = pt; sel_vote_count = vt; end
            3'd3: begin sel_pred_count = pn; sel_vote_count = vn; end
            default: begin sel_pred_count = po; sel_vote_count = vo; end
        endcase
    end

    always @(*) begin
        case (mode)
            2'd1:    display_count = sel_pred_count;
            2'd2:    display_count = sel_vote_count;
            2'd3:    display_count = vote_max;
            default: display_count = 8'd0;
        endcase
    end


    reg [3:0] bcd_hundreds, bcd_tens, bcd_units;
    integer i;
    reg [19:0] shift;

    always @(*) begin
        shift = {12'b0, display_count};
        for (i = 0; i < 8; i = i + 1) begin
            if (shift[11:8]  >= 4'd5) shift[11:8]  = shift[11:8]  + 4'd3;
            if (shift[15:12] >= 4'd5) shift[15:12] = shift[15:12] + 4'd3;
            if (shift[19:16] >= 4'd5) shift[19:16] = shift[19:16] + 4'd3;
            shift = shift << 1;
        end
        bcd_hundreds = shift[19:16];
        bcd_tens     = shift[15:12];
        bcd_units    = shift[11:8];
    end

 
    reg [23:0] blink_cnt;
    always @(posedge clk) begin
        if (rst) blink_cnt <= 0;
        else     blink_cnt <= blink_cnt + 1'b1;
    end
    wire blink = blink_cnt[23];
    wire match = (pred_winner == vote_winner);

 
    assign led[3:0]  = (mode == 2'd0) ? 4'b0000 : bcd_units;
    assign led[7:4]  = (mode == 2'd0) ? 4'b0000 : bcd_tens;
    assign led[11:8] = (mode == 2'd0) ? 4'b0000 : bcd_hundreds;
    assign led[12]   = accept_action;
    assign led[13]   = cast_done;
    assign led[14]   = (mode == 2'd2);
    assign led[15]   = (mode == 2'd3) & match & blink;

endmodule
