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
