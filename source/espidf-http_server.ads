--
--  Copyright (C) 2026, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Extensions_Allowed (On);
--  Aspect `Finalizable` is used to initialize objects automaically

with System;
private with System.Storage_Elements;

with A0B.Buffers;

with ESPIDF.C_Strings;

package ESPIDF.HTTP_Server is

   type httpd_method_t is
     (DELETE,
      GET,
      HEAD,
      POST,
      PUT,
      CONNECT,
      OPTIONS,
      TRACE,
      COPY,
      LOCK,
      MKCOL,
      MOVE,
      PROPFIND,
      PROPPATCH,
      SEARCH,
      UNLOCK,
      BIND,
      REBIND,
      UNBIND,
      ACL,
      REPORT,
      MKACTIVITY,
      CHECKOUT,
      MERGE,
      MSEARCH,
      NOTIFY,
      SUBSCRIBE,
      UNSUBSCRIBE,
      PATCH,
      PURGE,
      MKCALENDAR,
      LINK,
      UNLINK) with Convention => C;
   for httpd_method_t use
     (DELETE      => 0,
      GET         => 1,
      HEAD        => 2,
      POST        => 3,
      PUT         => 4,
      CONNECT     => 5,
      OPTIONS     => 6,
      TRACE       => 7,
      COPY        => 8,
      LOCK        => 9,
      MKCOL       => 10,
      MOVE        => 11,
      PROPFIND    => 12,
      PROPPATCH   => 13,
      SEARCH      => 14,
      UNLOCK      => 15,
      BIND        => 16,
      REBIND      => 17,
      UNBIND      => 18,
      ACL         => 19,
      REPORT      => 20,
      MKACTIVITY  => 21,
      CHECKOUT    => 22,
      MERGE       => 23,
      MSEARCH     => 24,
      NOTIFY      => 25,
      SUBSCRIBE   => 26,
      UNSUBSCRIBE => 27,
      PATCH       => 28,
      PURGE       => 29,
      MKCALENDAR  => 30,
      LINK        => 31,
      UNLINK      => 32);

   type httpd_err_code_t is
     (HTTPD_500_INTERNAL_SERVER_ERROR,
      HTTPD_501_METHOD_NOT_IMPLEMENTED,
      HTTPD_505_VERSION_NOT_SUPPORTED,
      HTTPD_400_BAD_REQUEST,
      HTTPD_401_UNAUTHORIZED,
      HTTPD_403_FORBIDDEN,
      HTTPD_404_NOT_FOUND,
      HTTPD_405_METHOD_NOT_ALLOWED,
      HTTPD_408_REQ_TIMEOUT,
      HTTPD_411_LENGTH_REQUIRED,
      HTTPD_413_CONTENT_TOO_LARGE,
      HTTPD_414_URI_TOO_LONG,
      HTTPD_431_REQ_HDR_FIELDS_TOO_LARGE) with Convention => C;

   HTTPD_SOCK_ERR_FAIL      : constant int := -1;
   HTTPD_SOCK_ERR_INVALID   : constant int := -2;
   HTTPD_SOCK_ERR_TIMEOUT   : constant int := -3;

   type httpd_config_t is limited private;

   type httpd_handle_t is limited private;

   type httpd_req_t is limited private;

   type httpd_req_handler_t is
     access function (req : in out httpd_req_t) return esp_err_t
       with Convention => C;

   type httpd_err_handler_func_t is
     access function
       (req   : in out httpd_req_t;
        error : httpd_err_code_t) return esp_err_t with Convention => C;

   function httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_start";

   procedure httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t);

   function httpd_stop (handle : in out httpd_handle_t) return esp_err_t;

   procedure httpd_stop (handle : in out httpd_handle_t);

   function Get_content_len (req : httpd_req_t) return size_t
     with Import, Convention => C,
          External_Name => "__ada_Get_httpd_req_t_content_len";

   function httpd_register_uri_handler
     (handle   : httpd_handle_t;
      uri      : ESPIDF.C_Strings.char_array_string;
      method   : httpd_method_t;
      handler  : not null httpd_req_handler_t;
      user_ctx : System.Address := System.Null_Address) return esp_err_t;

   procedure httpd_register_uri_handler
     (handle   : httpd_handle_t;
      uri      : ESPIDF.C_Strings.char_array_string;
      method   : httpd_method_t;
      handler  : not null httpd_req_handler_t;
      user_ctx : System.Address := System.Null_Address);

   function httpd_register_err_handler
     (handle      : httpd_handle_t;
      error       : httpd_err_code_t;
      handler_fn  : httpd_err_handler_func_t) return esp_err_t
     with Import, Convention => C,
          External_Name => "httpd_register_err_handler";

   procedure httpd_register_err_handler
     (handle      : httpd_handle_t;
      error       : httpd_err_code_t;
      handler_fn  : httpd_err_handler_func_t);

   function httpd_req_get_url_query_len
     (request : in out httpd_req_t) return size_t
     with Import, Convention => C,
          External_Name => "httpd_req_get_url_query_len";

   function httpd_req_recv
     (request : in out httpd_req_t;
      buf     : System.Address;
      buf_len : size_t) return int
     with Import, Convention => C, External_Name => "httpd_req_recv";

   function httpd_req_recv
     (request : in out httpd_req_t;
      Buffer  : in out A0B.Buffers.Abstract_Buffer'Class) return int;
   --  Wrapper around `httpd_req_recv` that accepts an `Abstract_Buffer`
   --  instead of raw address and length.

   function httpd_resp_set_status
     (request : in out httpd_req_t;
      status  : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_set_status";

   procedure httpd_resp_set_status
     (request : in out httpd_req_t;
      status  : ESPIDF.C_Strings.const_char_ptr);

   function httpd_resp_set_type
     (req  : in out httpd_req_t;
      mime : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_set_type";

   procedure httpd_resp_set_type
     (req  : in out httpd_req_t;
      mime : ESPIDF.C_Strings.const_char_ptr);

   function httpd_resp_set_hdr
     (req   : in out httpd_req_t;
      field : ESPIDF.C_Strings.const_char_ptr;
      value : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_set_hdr";

   procedure httpd_resp_set_hdr
     (req   : in out httpd_req_t;
      field : ESPIDF.C_Strings.const_char_ptr;
      value : ESPIDF.C_Strings.const_char_ptr);

   function httpd_resp_send_err
     (req   : in out httpd_req_t;
      error : httpd_err_code_t;
      msg   : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_send_err";

   procedure httpd_resp_send_err
     (req   : in out httpd_req_t;
      error : httpd_err_code_t;
      msg   : ESPIDF.C_Strings.const_char_ptr);

   function httpd_resp_send
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_send";

   procedure httpd_resp_send
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t);

   function httpd_resp_send_chunk
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_send_chunk";

   procedure httpd_resp_send_chunk
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t);

   function httpd_resp_send_chunk
     (req    : in out httpd_req_t;
      Buffer : A0B.Buffers.Abstract_Buffer'Class) return esp_err_t;

   procedure httpd_resp_send_chunk
     (req    : in out httpd_req_t;
      Buffer : A0B.Buffers.Abstract_Buffer'Class);

   function httpd_query_key_value
     (qry      : ESPIDF.C_Strings.const_char_ptr;
      key      : ESPIDF.C_Strings.const_char_ptr;
      val      : ESPIDF.C_Strings.char_ptr;
      val_size : size_t) return esp_err_t
     with Import, Convention => C,
          External_Name => "httpd_query_key_value";

private

   sizeof_httpd_config_t : constant int
      with Import, Convention => C,
           Link_Name => "__ada_sizeof_httpd_config_t";

   type httpd_config_t_Storage is
     new System.Storage_Elements.Storage_Array
       (1 .. System.Storage_Elements.Storage_Count
               (sizeof_httpd_config_t)) with Convention => C;

   procedure Initialize (Self : in out httpd_config_t);

   type httpd_config_t is limited record
      Storage : httpd_config_t_Storage := (others => 0);
   end record
     with Convention => C,
          Finalizable =>
            (Initialize           => Initialize,
             Relaxed_Finalization => True);

   type httpd_handle_t is new System.Address;

   sizeof_httpd_req_t : constant int
      with Import, Convention => C,
           Link_Name => "__ada_sizeof_httpd_req_t";

   type httpd_req_t_Storage is
     new System.Storage_Elements.Storage_Array
       (1 .. System.Storage_Elements.Storage_Count
               (sizeof_httpd_req_t)) with Convention => C;

   type httpd_req_t is limited record
      Storage : httpd_req_t_Storage := (others => 0);
   end record;

end ESPIDF.HTTP_Server;
