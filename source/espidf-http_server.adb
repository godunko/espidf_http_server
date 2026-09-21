--
--  Copyright (C) 2026, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with ESPIDF.Ada_ESP_Check_Error;

package body ESPIDF.HTTP_Server is

   ------------
   -- Create --
   ------------

   function Create
     (uri      : ESPIDF.C_Strings.const_char_ptr;
      method   : httpd_method_t;
      handler  : not null httpd_req_handler_t;
      user_ctx : System.Address := System.Null_Address) return httpd_uri_t
   is
      procedure Internal
        (Storage   : System.Address;
         uri       : ESPIDF.C_Strings.const_char_ptr;
         method    : httpd_method_t;
         handler   : not null httpd_req_handler_t;
         user_ctx  : System.Address)
        with Import, Convention => C,
             External_Name => "__ada_httpd_uri_t_create";

   begin
      return Result : httpd_uri_t do
         Internal (Result.Storage'Address, uri, method, handler, user_ctx);
      end return;
   end Create;

   --------------------------------
   -- httpd_register_err_handler --
   --------------------------------

   procedure httpd_register_err_handler
     (handle      : httpd_handle_t;
      error       : httpd_err_code_t;
      handler_fn  : httpd_err_handler_func_t) is
   begin
      Ada_ESP_Check_Error
        (httpd_register_err_handler (handle, error, handler_fn));
   end httpd_register_err_handler;

   --------------------------------
   -- httpd_register_uri_handler --
   --------------------------------

   procedure httpd_register_uri_handler
     (handle      : httpd_handle_t;
      uri_handler : httpd_uri_t) is
   begin
      Ada_ESP_Check_Error (httpd_register_uri_handler (handle, uri_handler));
   end httpd_register_uri_handler;

   --------------------
   -- httpd_req_recv --
   --------------------

   function httpd_req_recv
     (request : in out httpd_req_t;
      Buffer  : in out A0B.Buffers.Abstract_Buffer'Class) return int
   is
      Length : int;

   begin
      Buffer.Set_Actual_Length (0);
      Length :=
        httpd_req_recv (request, Buffer.Address, size_t (Buffer.Capacity));

      if Length > 0 then
         Buffer.Set_Actual_Length (A0B.Buffers.Storage_Count (Length));
      end if;

      return Length;
   end httpd_req_recv;

   ---------------------
   -- httpd_resp_send --
   ---------------------

   procedure httpd_resp_send
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t) is
   begin
      Ada_ESP_Check_Error (httpd_resp_send (req, buf, buf_len));
   end httpd_resp_send;

   ---------------------------
   -- httpd_resp_send_chunk --
   ---------------------------

   procedure httpd_resp_send_chunk
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t) is
   begin
      Ada_ESP_Check_Error (httpd_resp_send_chunk (req, buf, buf_len));
   end httpd_resp_send_chunk;

   ---------------------------
   -- httpd_resp_send_chunk --
   ---------------------------

   function httpd_resp_send_chunk
     (req    : in out httpd_req_t;
      Buffer : A0B.Buffers.Abstract_Buffer'Class) return esp_err_t is
   begin
      return
        httpd_resp_send_chunk (req, Buffer.Address, ssize_t (Buffer.Length));
   end httpd_resp_send_chunk;

   ---------------------------
   -- httpd_resp_send_chunk --
   ---------------------------

   procedure httpd_resp_send_chunk
     (req    : in out httpd_req_t;
      Buffer : A0B.Buffers.Abstract_Buffer'Class) is
   begin
      Ada_ESP_Check_Error (httpd_resp_send_chunk (req, Buffer));
   end httpd_resp_send_chunk;

   -------------------------
   -- httpd_resp_send_err --
   -------------------------

   procedure httpd_resp_send_err
     (req   : in out httpd_req_t;
      error : httpd_err_code_t;
      msg   : ESPIDF.C_Strings.const_char_ptr) is
   begin
      Ada_ESP_Check_Error (httpd_resp_send_err (req, error, msg));
   end httpd_resp_send_err;

   ------------------------
   -- httpd_resp_set_hdr --
   ------------------------

   procedure httpd_resp_set_hdr
     (req   : in out httpd_req_t;
      field : ESPIDF.C_Strings.const_char_ptr;
      value : ESPIDF.C_Strings.const_char_ptr) is
   begin
      Ada_ESP_Check_Error (httpd_resp_set_hdr (req, field, value));
   end httpd_resp_set_hdr;

   ---------------------------
   -- httpd_resp_set_status --
   ---------------------------

   procedure httpd_resp_set_status
     (request : in out httpd_req_t;
      status  : ESPIDF.C_Strings.const_char_ptr) is
   begin
      Ada_ESP_Check_Error (httpd_resp_set_status (request, status));
   end httpd_resp_set_status;

   -------------------------
   -- httpd_resp_set_type --
   -------------------------

   procedure httpd_resp_set_type
     (req  : in out httpd_req_t;
      mime : ESPIDF.C_Strings.const_char_ptr) is
   begin
      Ada_ESP_Check_Error (httpd_resp_set_type (req, mime));
   end httpd_resp_set_type;

   -----------------
   -- httpd_start --
   -----------------

   procedure httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t) is
   begin
      Ada_ESP_Check_Error (httpd_start (Handle, Config));
   end httpd_start;

   ----------------
   -- httpd_stop --
   ----------------

   function httpd_stop (handle : in out httpd_handle_t) return esp_err_t is
      function Imported
        (handle : httpd_handle_t) return esp_err_t
        with Import, Convention => C, External_Name => "httpd_stop";

   begin
      return Result : constant esp_err_t := Imported (handle) do
         if Result = ESP_OK then
            handle := httpd_handle_t (System.Null_Address);
         end if;
      end return;
   end httpd_stop;

   ----------------
   -- httpd_stop --
   ----------------

   procedure httpd_stop (handle : in out httpd_handle_t) is
   begin
      Ada_ESP_Check_Error (httpd_stop (handle));
   end httpd_stop;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out httpd_config_t) is

      procedure Imported (config : out httpd_config_t)
        with Import, Convention => C,
             External_Name => "__ada_HTTPD_DEFAULT_CONFIG";

   begin
      Imported (Self);
   end Initialize;

end ESPIDF.HTTP_Server;
