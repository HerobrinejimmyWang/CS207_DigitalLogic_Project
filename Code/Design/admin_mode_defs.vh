`ifndef ADMIN_MODE_DEFS_VH
`define ADMIN_MODE_DEFS_VH

// Shared event encodings from input_event_router.
`define EV_DIGIT      3'd0
`define EV_PREV       3'd1
`define EV_BACK       3'd2
`define EV_HOME       3'd3
`define EV_NEXT       3'd4
`define EV_CLEAR      3'd5
`define EV_CONFIRM    3'd6

// Shared numeric_input_buffer modes.
// IDLE is used internally by the shared buffer mux so menu digits do not
// accidentally enter the numeric buffer while AUTH/ADMIN are on non-input pages.
`define INPUT_MODE_SINGLE_ID      3'd0
`define INPUT_MODE_AMOUNT         3'd1
`define INPUT_MODE_PRICE          3'd2
`define INPUT_MODE_STOCK          3'd3
`define INPUT_MODE_PASSWORD_BCD2  3'd4
`define INPUT_MODE_IDLE           3'd7

// Shared auth_engine state encodings.
`define AUTH_STATE_INPUT          3'd0
`define AUTH_STATE_CHECK          3'd1
`define AUTH_STATE_FAIL_DISPLAY   3'd2
`define AUTH_STATE_SUCCESS        3'd3
`define AUTH_STATE_ERROR_DISPLAY  3'd4

// Shared main mode encodings.
`define MODE_MAIN_MENU 3'd0
`define MODE_SALE      3'd1
`define MODE_AUTH      3'd2
`define MODE_ADMIN     3'd3
`define MODE_ALARM     3'd4

// Shared sale_engine state encodings.
`define SALE_STATE_SHOW_LIST       4'd0
`define SALE_STATE_INPUT_MONEY     4'd1
`define SALE_STATE_DISPENSE        4'd2
`define SALE_STATE_WAIT_TAKE       4'd3
`define SALE_STATE_SUCCESS         4'd4
`define SALE_STATE_TIMEOUT_REFUND  4'd5
`define SALE_STATE_ERROR_DISPLAY   4'd6

// Shared admin_engine state encodings.
`define ADMIN_STATE_MENU                    4'd0
`define ADMIN_STATE_VIEW_ITEMS              4'd1
`define ADMIN_STATE_SET_PRICE_SELECT_ITEM   4'd2
`define ADMIN_STATE_SET_PRICE_INPUT         4'd3
`define ADMIN_STATE_SET_PRICE_SUCCESS       4'd4
`define ADMIN_STATE_ADD_STOCK_SELECT_ITEM   4'd5
`define ADMIN_STATE_ADD_STOCK_INPUT         4'd6
`define ADMIN_STATE_ADD_STOCK_SUCCESS       4'd7
`define ADMIN_STATE_TOGGLE_SELECT_ITEM      4'd8
`define ADMIN_STATE_TOGGLE_SUCCESS          4'd9
`define ADMIN_STATE_VIEW_TOTAL              4'd10

// Shared admin function menu encodings.
`define ADMIN_FUNC_VIEW_ITEMS   3'd1
`define ADMIN_FUNC_SET_PRICE    3'd2
`define ADMIN_FUNC_ADD_STOCK    3'd3
`define ADMIN_FUNC_TOGGLE       3'd4
`define ADMIN_FUNC_VIEW_TOTAL   3'd5

// Shared error codes.
`define ERR_NONE             4'd0
`define ERR_INVALID_INPUT    4'd1
`define ERR_WRONG_PASSWORD   4'd2
`define ERR_ITEM_OFF         4'd3
`define ERR_NO_STOCK         4'd4
`define ERR_NOT_ENOUGH       4'd5

`endif
