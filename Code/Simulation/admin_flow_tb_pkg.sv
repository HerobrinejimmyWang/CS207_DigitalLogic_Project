package admin_flow_tb_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  // Shared abstract event encoding expected from input_event_router.
  localparam logic [2:0] EV_DIGIT   = 3'd0;
  localparam logic [2:0] EV_PREV    = 3'd1;
  localparam logic [2:0] EV_BACK    = 3'd2;
  localparam logic [2:0] EV_HOME    = 3'd3;
  localparam logic [2:0] EV_NEXT    = 3'd4;
  localparam logic [2:0] EV_CLEAR   = 3'd5;
  localparam logic [2:0] EV_CONFIRM = 3'd6;

  // Shared numeric_input_buffer input modes.
  localparam logic [2:0] BUF_MODE_SINGLE_ID     = 3'd0;
  localparam logic [2:0] BUF_MODE_AMOUNT        = 3'd1;
  localparam logic [2:0] BUF_MODE_PRICE         = 3'd2;
  localparam logic [2:0] BUF_MODE_STOCK         = 3'd3;
  localparam logic [2:0] BUF_MODE_PASSWORD_BCD2 = 3'd4;

  // main_mode_fsm encoding expected by the verification environment.
  localparam logic [2:0] MODE_MAIN_MENU = 3'd0;
  localparam logic [2:0] MODE_SALE      = 3'd1;
  localparam logic [2:0] MODE_AUTH      = 3'd2;
  localparam logic [2:0] MODE_ADMIN     = 3'd3;
  localparam logic [2:0] MODE_ALARM     = 3'd4;

  // auth_engine state encoding expected by the verification environment.
  localparam logic [2:0] AUTH_INPUT         = 3'd0;
  localparam logic [2:0] AUTH_CHECK         = 3'd1;
  localparam logic [2:0] AUTH_FAIL_DISPLAY  = 3'd2;
  localparam logic [2:0] AUTH_SUCCESS       = 3'd3;
  localparam logic [2:0] AUTH_ERROR_DISPLAY = 3'd4;

  // admin_engine state encoding expected by the verification environment.
  localparam logic [3:0] ADMIN_MENU             = 4'd0;
  localparam logic [3:0] VIEW_ITEMS             = 4'd1;
  localparam logic [3:0] SET_PRICE_SELECT_ITEM  = 4'd2;
  localparam logic [3:0] SET_PRICE_INPUT        = 4'd3;
  localparam logic [3:0] SET_PRICE_SUCCESS      = 4'd4;
  localparam logic [3:0] ADD_STOCK_SELECT_ITEM  = 4'd5;
  localparam logic [3:0] ADD_STOCK_INPUT        = 4'd6;
  localparam logic [3:0] ADD_STOCK_SUCCESS      = 4'd7;
  localparam logic [3:0] TOGGLE_SELECT_ITEM     = 4'd8;
  localparam logic [3:0] TOGGLE_SUCCESS         = 4'd9;
  localparam logic [3:0] VIEW_TOTAL             = 4'd10;

  // error_manager / engine-visible error code encoding used by the tests.
  localparam logic [3:0] ERR_INVALID_INPUT  = 4'd0;
  localparam logic [3:0] ERR_ITEM_OFF       = 4'd1;
  localparam logic [3:0] ERR_NO_STOCK       = 4'd2;
  localparam logic [3:0] ERR_NOT_ENOUGH     = 4'd3;
  localparam logic [3:0] ERR_WRONG_PASSWORD = 4'd4;
endpackage
