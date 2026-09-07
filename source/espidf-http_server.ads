--
--  Copyright (C) 2026, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Extensions_Allowed (On);
--  Aspect `Finalizable` is used to initialize objects automaically

with System;
private with System.Storage_Elements;

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

   type httpd_config_t is limited private;

   type httpd_handle_t is limited private;

   type httpd_req_t is limited private;

   type httpd_uri_t is limited private;

   type httpd_req_handler_t is
     access function (req : in out httpd_req_t) return esp_err_t
       with Convention => C;

   function httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_start";

   procedure httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t);

   function Create
     (uri      : ESPIDF.C_Strings.const_char_ptr;
      method   : httpd_method_t;
      handler  : not null httpd_req_handler_t;
      user_ctx : System.Address := System.Null_Address) return httpd_uri_t;
   --  Initialize object of `httpd_uri_t` to process requests.

   function httpd_register_uri_handler
     (handle      : httpd_handle_t;
      uri_handler : httpd_uri_t) return esp_err_t
        with Import, Convention => C,
             External_Name => "httpd_register_uri_handler";

   procedure httpd_register_uri_handler
     (handle      : httpd_handle_t;
      uri_handler : httpd_uri_t);

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

   sizeof_httpd_uri_t : constant int
      with Import, Convention => C,
           Link_Name => "__ada_sizeof_httpd_uri_t";

   type httpd_uri_t_Storage is
     new System.Storage_Elements.Storage_Array
       (1 .. System.Storage_Elements.Storage_Count
               (sizeof_httpd_uri_t)) with Convention => C;

   type httpd_uri_t is limited record
      Storage : httpd_uri_t_Storage := (others => 0);
   end record;

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
