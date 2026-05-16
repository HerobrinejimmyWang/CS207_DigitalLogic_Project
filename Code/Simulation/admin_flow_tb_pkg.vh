`ifndef ADMIN_FLOW_TB_PKG_VH
`define ADMIN_FLOW_TB_PKG_VH

`timescale 1ns / 1ps
`include "../Design/admin_mode_defs.vh"

// Shared abstract event encoding expected from input_event_router.
localparam [2:0] EV_DIGIT   = `EV_DIGIT;
localparam [2:0] EV_PREV    = `EV_PREV;
localparam [2:0] EV_BACK    = `EV_BACK;
localparam [2:0] EV_HOME    = `EV_HOME;
localparam [2:0] EV_NEXT    = `EV_NEXT;
localparam [2:0] EV_CLEAR   = `EV_CLEAR;
localparam [2:0] EV_CONFIRM = `EV_CONFIRM;

// Shared numeric_input_buffer input modes.
localparam [2:0] BUF_MODE_SINGLE_ID     = `INPUT_MODE_SINGLE_ID;
localparam [2:0] BUF_MODE_AMOUNT        = `INPUT_MODE_AMOUNT;
localparam [2:0] BUF_MODE_PRICE         = `INPUT_MODE_PRICE;
localparam [2:0] BUF_MODE_STOCK         = `INPUT_MODE_STOCK;
localparam [2:0] BUF_MODE_PASSWORD_BCD2 = `INPUT_MODE_PASSWORD_BCD2;

// main_mode_fsm encoding expected by the verification environment.
localparam [2:0] MODE_MAIN_MENU = 3'd0;
localparam [2:0] MODE_SALE      = 3'd1;
localparam [2:0] MODE_AUTH      = 3'd2;
localparam [2:0] MODE_ADMIN     = 3'd3;
localparam [2:0] MODE_ALARM     = 3'd4;

// auth_engine state encoding expected by the verification environment.
localparam [2:0] AUTH_INPUT         = `AUTH_STATE_INPUT;
localparam [2:0] AUTH_CHECK         = `AUTH_STATE_CHECK;
localparam [2:0] AUTH_FAIL_DISPLAY  = `AUTH_STATE_FAIL_DISPLAY;
localparam [2:0] AUTH_SUCCESS       = `AUTH_STATE_SUCCESS;
localparam [2:0] AUTH_ERROR_DISPLAY = `AUTH_STATE_ERROR_DISPLAY;

// admin_engine state encoding expected by the verification environment.
localparam [3:0] ADMIN_MENU             = `ADMIN_STATE_MENU;
localparam [3:0] VIEW_ITEMS             = `ADMIN_STATE_VIEW_ITEMS;
localparam [3:0] SET_PRICE_SELECT_ITEM  = `ADMIN_STATE_SET_PRICE_SELECT_ITEM;
localparam [3:0] SET_PRICE_INPUT        = `ADMIN_STATE_SET_PRICE_INPUT;
localparam [3:0] SET_PRICE_SUCCESS      = `ADMIN_STATE_SET_PRICE_SUCCESS;
localparam [3:0] ADD_STOCK_SELECT_ITEM  = `ADMIN_STATE_ADD_STOCK_SELECT_ITEM;
localparam [3:0] ADD_STOCK_INPUT        = `ADMIN_STATE_ADD_STOCK_INPUT;
localparam [3:0] ADD_STOCK_SUCCESS      = `ADMIN_STATE_ADD_STOCK_SUCCESS;
localparam [3:0] TOGGLE_SELECT_ITEM     = `ADMIN_STATE_TOGGLE_SELECT_ITEM;
localparam [3:0] TOGGLE_SUCCESS         = `ADMIN_STATE_TOGGLE_SUCCESS;
localparam [3:0] VIEW_TOTAL             = `ADMIN_STATE_VIEW_TOTAL;

// error_manager / engine-visible error code encoding used by the tests.
localparam [3:0] ERR_INVALID_INPUT  = `ERR_INVALID_INPUT;
localparam [3:0] ERR_ITEM_OFF       = 4'd3;
localparam [3:0] ERR_NO_STOCK       = 4'd4;
localparam [3:0] ERR_NOT_ENOUGH     = 4'd5;
localparam [3:0] ERR_WRONG_PASSWORD = `ERR_WRONG_PASSWORD;

`endif
