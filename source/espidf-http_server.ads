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

   ESP_ERR_HTTPD_HANDLERS_FULL  : constant esp_err_t := 16#B001#;
   --  All slots for registering URI handlers have been consumed
   ESP_ERR_HTTPD_HANDLER_EXISTS : constant esp_err_t := 16#B002#;
   --  URI handler with same method and target URI already registered
   ESP_ERR_HTTPD_INVALID_REQ    : constant esp_err_t := 16#B003#;
   --  Invalid request pointer
   ESP_ERR_HTTPD_RESULT_TRUNC   : constant esp_err_t := 16#B004#;
   --  Result string truncated
   ESP_ERR_HTTPD_RESP_HDR       : constant esp_err_t := 16#B005#;
   --  Response header field larger than supported
   ESP_ERR_HTTPD_RESP_SEND      : constant esp_err_t := 16#B006#;
   --  Error occurred while sending response packet
   ESP_ERR_HTTPD_ALLOC_MEM      : constant esp_err_t := 16#B007#;
   --  Failed to dynamically allocate memory for resource
   ESP_ERR_HTTPD_TASK           : constant esp_err_t := 16#B008#;
   --  Failed to launch server task/thread

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
   --  HTTP Method Type wrapper over "enum http_method" available in
   --  "http_parser" library.
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
   --  Error codes sent as HTTP response in case of errors encountered during
   --  processing of an HTTP request.
   --  @enum HTTPD_500_INTERNAL_SERVER_ERROR
   --    For any unexpected errors during parsing, like unexpected state
   --    transitions, or unhandled errors.
   --  @enum HTTPD_501_METHOD_NOT_IMPLEMENTED
   --    For methods not supported by http_parser. Presently http_parser
   --    halts parsing when such methods are encountered and so the server
   --    responds with 400 Bad Request error instead.
   --  @enum HTTPD_505_VERSION_NOT_SUPPORTED
   --    When HTTP version is not 1.1 or 1.0
   --  @enum HTTPD_400_BAD_REQUEST
   --    Returned when http_parser halts parsing due to incorrect syntax of
   --    request, unsupported method in request URI or due to chunked
   --    encoding / upgrade field present in headers
   --  @enum HTTPD_401_UNAUTHORIZED
   --    This response means the client must authenticate itself to get the
   --    requested response.
   --  @enum HTTPD_403_FORBIDDEN
   --    The client does not have access rights to the content, so the server
   --    is refusing to give the requested resource. Unlike 401, the client's
   --    identity is known to the server.
   --  @enum HTTPD_404_NOT_FOUND When requested URI is not found
   --  @enum HTTPD_405_METHOD_NOT_ALLOWED
   --    When URI found, but method has no handler registered
   --  @enum HTTPD_408_REQ_TIMEOUT
   --    Intended for recv timeout. Presently it's being sent for other recv
   --    errors as well. Client should expect the server to immediately close
   --    the connection after responding with this.
   --  @enum HTTPD_411_LENGTH_REQUIRED
   --    Intended for responding to chunked encoding, which is not supported
   --    currently. Though unhandled http_parser callback for chunked request
   --    returns "400 Bad Request"
   --  @enum HTTPD_413_CONTENT_TOO_LARGE Incoming payload is too large
   --  @enum HTTPD_414_URI_TOO_LONG
   --    URI length greater than `CONFIG_HTTPD_MAX_URI_LEN`
   --  @enum HTTPD_431_REQ_HDR_FIELDS_TOO_LARGE
   --    Headers section larger than `CONFIG_HTTPD_MAX_REQ_HDR_LEN`

   HTTPD_SOCK_ERR_FAIL      : constant int := -1;
   --  Unrecoverable error while calling socket function
   HTTPD_SOCK_ERR_INVALID   : constant int := -2;
   --  Invalid arguments
   HTTPD_SOCK_ERR_TIMEOUT   : constant int := -3;
   --  Timeout/interrupted while calling socket function

   type httpd_config_t is limited private;
   --  HTTP Server Configuration Structure.
   --
   --  Objects of this type are initialized to the default configuration
   --  (`HTTPD_DEFAULT_CONFIG`) automatically.

   type httpd_handle_t is limited private;
   --  HTTP Server Instance Handle.
   --
   --  Every instance of the server will have a unique handle.

   type httpd_req_t is limited private;
   --  HTTP Request Data Structure.

   type httpd_req_handler_t is
     access function (req : in out httpd_req_t) return esp_err_t
       with Convention => C;
   --  Handler to call for supported request method. This must return
   --  `ESP_OK`, or else the underlying socket will be closed.

   type httpd_err_handler_func_t is
     access function
       (req   : in out httpd_req_t;
        error : httpd_err_code_t) return esp_err_t with Convention => C;
   --  Function prototype for HTTP error handling.
   --
   --  This function is executed upon HTTP errors generated during internal
   --  processing of an HTTP request. This is used to override the default
   --  behavior on error, which is to send HTTP error response and close the
   --  underlying socket.
   --
   --  Note:
   --    - If implemented, the server will not automatically send out HTTP
   --      error response codes, therefore, `httpd_resp_send_err` must be
   --      invoked inside this function if user wishes to generate HTTP
   --      error responses.
   --    - When invoked, the validity of `uri`, `method`, `content_len` and
   --      `user_ctx` fields of the `httpd_req_t` parameter is not
   --      guaranteed as the HTTP request may be partially received/parsed.
   --    - The function must return `ESP_OK` if underlying socket needs to
   --      be kept open. Any other value will ensure that the socket is
   --      closed. The return value is ignored when error is of type
   --      `HTTPD_500_INTERNAL_SERVER_ERROR` and the socket closed anyway.
   --  @param req HTTP request for which the error needs to be handled
   --  @param error Error type
   --  @return
   --    - `ESP_OK` if error was handled successfully
   --    - `ESP_FAIL` if failed, which indicates that the underlying socket
   --      needs to be closed

   function httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_start";
   --  Starts the web server.
   --
   --  Create an instance of HTTP server and allocate memory/resources for it
   --  depending upon the specified configuration.
   --  @param Handle
   --    Handle to newly created instance of the server. Null on error.
   --  @param Config Configuration for new instance of the server
   --  @return
   --    - `ESP_OK` if instance was created successfully
   --    - `ESP_ERR_INVALID_ARG` if argument(s) are null
   --    - `ESP_ERR_HTTPD_ALLOC_MEM` if failed to allocate memory for instance
   --    - `ESP_ERR_HTTPD_TASK` if failed to launch server task

   procedure httpd_start
     (Handle : out httpd_handle_t;
      Config : httpd_config_t);
   --  Starts the web server.
   --
   --  Create an instance of HTTP server and allocate memory/resources for it
   --  depending upon the specified configuration.
   --  @param Handle
   --    Handle to newly created instance of the server. Null on error.
   --  @param Config Configuration for new instance of the server
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if argument(s) are null
   --    - `ESP_ERR_HTTPD_ALLOC_MEM` if failed to allocate memory for instance
   --    - `ESP_ERR_HTTPD_TASK` if failed to launch server task

   function httpd_stop (handle : in out httpd_handle_t) return esp_err_t;
   --  Stops the web server.
   --
   --  Deallocates memory/resources used by an HTTP server instance and
   --  deletes it. Once deleted the handle can no longer be used for
   --  accessing the instance.
   --  @param handle
   --    Handle to server returned by `httpd_start`. It is reset to null
   --    value on success.
   --  @return
   --    - `ESP_OK` if server was stopped successfully
   --    - `ESP_ERR_INVALID_ARG` if handle argument is null

   procedure httpd_stop (handle : in out httpd_handle_t);
   --  Stops the web server.
   --
   --  Deallocates memory/resources used by an HTTP server instance and
   --  deletes it. Once deleted the handle can no longer be used for
   --  accessing the instance.
   --  @param handle
   --    Handle to server returned by `httpd_start`. It is reset to null
   --    value on success.
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if handle argument is null

   function Get_content_len (req : httpd_req_t) return size_t
     with Import, Convention => C,
          External_Name => "__ada_Get_httpd_req_t_content_len";
   --  Returns length of the request body.
   --  @param req The request
   --  @return Length of the request body

   function httpd_register_uri_handler
     (handle   : httpd_handle_t;
      uri      : ESPIDF.C_Strings.char_array_string;
      method   : httpd_method_t;
      handler  : not null httpd_req_handler_t;
      user_ctx : System.Address := System.Null_Address) return esp_err_t;
   --  Registers a URI handler.
   --
   --  Note: URI handlers can be registered in real time as long as the
   --  server handle is valid.
   --  @param handle Handle to HTTPD server instance
   --  @param uri The URI to handle
   --  @param method Method supported by the URI
   --  @param handler
   --    Handler to call for supported request method. This must return
   --    `ESP_OK`, or else the underlying socket will be closed.
   --  @param user_ctx
   --    Pointer to user context data which will be available to handler
   --  @return
   --    - `ESP_OK` if handler was registered successfully
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_HANDLERS_FULL` if no slots are left for new handler
   --    - `ESP_ERR_HTTPD_HANDLER_EXISTS` if handler with same URI and
   --      method is already registered

   procedure httpd_register_uri_handler
     (handle   : httpd_handle_t;
      uri      : ESPIDF.C_Strings.char_array_string;
      method   : httpd_method_t;
      handler  : not null httpd_req_handler_t;
      user_ctx : System.Address := System.Null_Address);
   --  Registers a URI handler.
   --
   --  Note: URI handlers can be registered in real time as long as the
   --  server handle is valid.
   --  @param handle Handle to HTTPD server instance
   --  @param uri The URI to handle
   --  @param method Method supported by the URI
   --  @param handler
   --    Handler to call for supported request method. This must return
   --    `ESP_OK`, or else the underlying socket will be closed.
   --  @param user_ctx
   --    Pointer to user context data which will be available to handler
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_HANDLERS_FULL` if no slots are left for new handler
   --    - `ESP_ERR_HTTPD_HANDLER_EXISTS` if handler with same URI and
   --      method is already registered

   function httpd_register_err_handler
     (handle      : httpd_handle_t;
      error       : httpd_err_code_t;
      handler_fn  : httpd_err_handler_func_t) return esp_err_t
     with Import, Convention => C,
          External_Name => "httpd_register_err_handler";
   --  Function for registering HTTP error handlers.
   --
   --  This function maps a handler function to any supported error code
   --  given by `httpd_err_code_t`. See prototype `httpd_err_handler_func_t`
   --  for details.
   --  @param handle HTTP server handle
   --  @param error Error type
   --  @param handler_fn
   --    User implemented handler function (pass null to unset any
   --    previously set handler)
   --  @return
   --    - `ESP_OK` if handler was registered successfully
   --    - `ESP_ERR_INVALID_ARG` if error code or server handle is invalid

   procedure httpd_register_err_handler
     (handle      : httpd_handle_t;
      error       : httpd_err_code_t;
      handler_fn  : httpd_err_handler_func_t);
   --  Function for registering HTTP error handlers.
   --
   --  This function maps a handler function to any supported error code
   --  given by `httpd_err_code_t`. See prototype `httpd_err_handler_func_t`
   --  for details.
   --  @param handle HTTP server handle
   --  @param error Error type
   --  @param handler_fn
   --    User implemented handler function (pass null to unset any
   --    previously set handler)
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if error code or server handle is invalid

   function httpd_req_get_url_query_len
     (request : in out httpd_req_t) return size_t
     with Import, Convention => C,
          External_Name => "httpd_req_get_url_query_len";
   --  Get Query string length from the request URL.
   --
   --  Note: This API is supposed to be called only from the context of a
   --  URI handler where `request` is valid.
   --  @param request The request being responded to
   --  @return
   --    - length of the query if query is found in the request URL
   --    - zero if query is not found, arguments are null, request is invalid
   --      or uri is empty

   function httpd_req_get_url_query_str
     (request : in out httpd_req_t;
      buf     : in out ESPIDF.C_Strings.char_array) return esp_err_t;
   --  Get Query string from the request URL.
   --
   --  Note:
   --    - Presently, the user can fetch the full URL query string, but
   --      decoding will have to be performed by the user. Request headers
   --      can be read using `httpd_req_get_hdr_value_str` to know the
   --      'Content-Type' (eg. Content-Type:
   --      application/x-www-form-urlencoded) and then the appropriate
   --      decoding algorithm needs to be applied.
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid
   --    - If output size is greater than input, then the value is
   --      truncated, accompanied by truncation error as return value
   --    - Prior to calling this function, one can use
   --      `httpd_req_get_url_query_len` to know the query string length
   --      beforehand and hence allocate the buffer of right size (usually
   --      query string length + 1 for null termination) for storing the
   --      query string
   --  @param request The request being responded to
   --  @param buf
   --    The buffer into which the query string will be copied (if found)
   --  @return
   --    - `ESP_OK` if query is found in the request URL and copied to buffer
   --    - `ESP_FAIL` if uri is empty
   --    - `ESP_ERR_NOT_FOUND` if query is not found
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if HTTP request pointer is invalid
   --    - `ESP_ERR_HTTPD_RESULT_TRUNC` if query string is truncated

   procedure httpd_req_get_url_query_str
     (request : in out httpd_req_t;
      buf     : in out ESPIDF.C_Strings.char_array);
   --  Get Query string from the request URL.
   --
   --  Note:
   --    - Presently, the user can fetch the full URL query string, but
   --      decoding will have to be performed by the user. Request headers
   --      can be read using `httpd_req_get_hdr_value_str` to know the
   --      'Content-Type' (eg. Content-Type:
   --      application/x-www-form-urlencoded) and then the appropriate
   --      decoding algorithm needs to be applied.
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid
   --    - If output size is greater than input, then the value is
   --      truncated, accompanied by truncation error
   --    - Prior to calling this subprogram, one can use
   --      `httpd_req_get_url_query_len` to know the query string length
   --      beforehand and hence allocate the buffer of right size (usually
   --      query string length + 1 for null termination) for storing the
   --      query string
   --  @param request The request being responded to
   --  @param buf
   --    The buffer into which the query string will be copied (if found)
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_FAIL` if uri is empty
   --    - `ESP_ERR_NOT_FOUND` if query is not found
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if HTTP request pointer is invalid
   --    - `ESP_ERR_HTTPD_RESULT_TRUNC` if query string is truncated

   function httpd_req_get_url_query_str
     (request : in out httpd_req_t;
      Buffer  : in out A0B.Buffers.Abstract_Buffer'Class) return esp_err_t;
   --  Get Query string from the request URL.
   --
   --  Note:
   --    - Presently, the user can fetch the full URL query string, but
   --      decoding will have to be performed by the user. Request headers
   --      can be read using `httpd_req_get_hdr_value_str` to know the
   --      'Content-Type' (eg. Content-Type:
   --      application/x-www-form-urlencoded) and then the appropriate
   --      decoding algorithm needs to be applied.
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid
   --    - If output size is greater than input, then the value is
   --      truncated, accompanied by truncation error as return value
   --
   --  Actual length of the `Buffer` is set to the length of the copied
   --  query string (excluding null terminator, thus it is at most one less
   --  than capacity of the `Buffer`) when `ESP_OK` or
   --  `ESP_ERR_HTTPD_RESULT_TRUNC` is returned, and to zero otherwise.
   --  @param request The request being responded to
   --  @param Buffer
   --    The buffer into which the query string will be copied (if found)
   --  @return
   --    - `ESP_OK` if query is found in the request URL and copied to buffer
   --    - `ESP_FAIL` if uri is empty
   --    - `ESP_ERR_NOT_FOUND` if query is not found
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if HTTP request pointer is invalid
   --    - `ESP_ERR_HTTPD_RESULT_TRUNC` if query string is truncated

   procedure httpd_req_get_url_query_str
     (request : in out httpd_req_t;
      Buffer  : in out A0B.Buffers.Abstract_Buffer'Class);
   --  Get Query string from the request URL.
   --
   --  Note:
   --    - Presently, the user can fetch the full URL query string, but
   --      decoding will have to be performed by the user. Request headers
   --      can be read using `httpd_req_get_hdr_value_str` to know the
   --      'Content-Type' (eg. Content-Type:
   --      application/x-www-form-urlencoded) and then the appropriate
   --      decoding algorithm needs to be applied.
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid
   --    - If output size is greater than input, then the value is
   --      truncated, accompanied by truncation error
   --
   --  Actual length of the `Buffer` is set to the length of the copied
   --  query string (excluding null terminator, thus it is at most one less
   --  than capacity of the `Buffer`) on success or truncation, and to zero
   --  otherwise.
   --  @param request The request being responded to
   --  @param Buffer
   --    The buffer into which the query string will be copied (if found)
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_FAIL` if uri is empty
   --    - `ESP_ERR_NOT_FOUND` if query is not found
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if HTTP request pointer is invalid
   --    - `ESP_ERR_HTTPD_RESULT_TRUNC` if query string is truncated

   function httpd_req_recv
     (request : in out httpd_req_t;
      buf     : System.Address;
      buf_len : size_t) return int
     with Import, Convention => C, External_Name => "httpd_req_recv";
   --  API to read content data from the HTTP request.
   --
   --  This API will read HTTP content data from the HTTP request into
   --  provided buffer. Use `Get_content_len` to know the length of data to
   --  be fetched. If content length is too large for the buffer then user
   --  may have to make multiple calls to this function, each time fetching
   --  `buf_len` number of bytes, while the pointer to content data is
   --  incremented internally by the same number.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid.
   --    - If an error is returned, the URI handler must further return an
   --      error. This will ensure that the erroneous socket is closed and
   --      cleaned up by the web server.
   --    - Presently Chunked Encoding is not supported
   --  @param request The request being responded to
   --  @param buf Pointer to a buffer that the data will be read into
   --  @param buf_len Length of the buffer
   --  @return
   --    - number of bytes read into the buffer if successful
   --    - `0` if buffer length parameter is zero or connection was closed by
   --      peer
   --    - `HTTPD_SOCK_ERR_INVALID` if arguments are invalid
   --    - `HTTPD_SOCK_ERR_TIMEOUT` if timeout/interrupted while calling
   --      socket recv
   --    - `HTTPD_SOCK_ERR_FAIL` if unrecoverable error happened while
   --      calling socket recv

   function httpd_req_recv
     (request : in out httpd_req_t;
      Buffer  : in out A0B.Buffers.Abstract_Buffer'Class) return int;
   --  API to read content data from the HTTP request.
   --
   --  This API will read HTTP content data from the HTTP request into
   --  provided buffer. Use `Get_content_len` to know the length of data to
   --  be fetched. If content length is too large for the buffer then user
   --  may have to make multiple calls to this function, each time fetching
   --  up to capacity of the `Buffer` number of bytes, while the pointer to
   --  content data is incremented internally by the same number.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid.
   --    - If an error is returned, the URI handler must further return an
   --      error. This will ensure that the erroneous socket is closed and
   --      cleaned up by the web server.
   --    - Presently Chunked Encoding is not supported
   --
   --  Wrapper around `httpd_req_recv` that accepts an `Abstract_Buffer`
   --  instead of raw address and length.
   --
   --  Actual length of the `Buffer` is set to the number of bytes read, or
   --  to zero when nothing has been read.
   --  @param request The request being responded to
   --  @param Buffer The buffer that the data will be read into
   --  @return
   --    - number of bytes read into the buffer if successful
   --    - `0` if buffer capacity is zero or connection was closed by peer
   --    - `HTTPD_SOCK_ERR_INVALID` if arguments are invalid
   --    - `HTTPD_SOCK_ERR_TIMEOUT` if timeout/interrupted while calling
   --      socket recv
   --    - `HTTPD_SOCK_ERR_FAIL` if unrecoverable error happened while
   --      calling socket recv

   function httpd_resp_set_status
     (request : in out httpd_req_t;
      status  : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_set_status";
   --  API to set the HTTP status code.
   --
   --  This API sets the status of the HTTP response to the value specified.
   --  By default, the '200 OK' response is sent as the response.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid.
   --    - This API only sets the status to this value. The status isn't
   --      sent out until any of the send APIs is executed.
   --    - Make sure that the lifetime of the status string is valid till
   --      send function is called.
   --  @param request The request being responded to
   --  @param status The HTTP status code of this response
   --  @return
   --    - `ESP_OK` if status was set successfully
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   procedure httpd_resp_set_status
     (request : in out httpd_req_t;
      status  : ESPIDF.C_Strings.const_char_ptr);
   --  API to set the HTTP status code.
   --
   --  This API sets the status of the HTTP response to the value specified.
   --  By default, the '200 OK' response is sent as the response.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `request` is valid.
   --    - This API only sets the status to this value. The status isn't
   --      sent out until any of the send APIs is executed.
   --    - Make sure that the lifetime of the status string is valid till
   --      send function is called.
   --  @param request The request being responded to
   --  @param status The HTTP status code of this response
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   function httpd_resp_set_type
     (req  : in out httpd_req_t;
      mime : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_set_type";
   --  API to set the HTTP content type.
   --
   --  This API sets the 'Content Type' field of the response. The default
   --  content type is 'text/html'.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - This API only sets the content type to this value. The type isn't
   --      sent out until any of the send APIs is executed.
   --    - Make sure that the lifetime of the type string is valid till send
   --      function is called.
   --  @param req The request being responded to
   --  @param mime The Content Type of the response
   --  @return
   --    - `ESP_OK` if content type was set successfully
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   procedure httpd_resp_set_type
     (req  : in out httpd_req_t;
      mime : ESPIDF.C_Strings.const_char_ptr);
   --  API to set the HTTP content type.
   --
   --  This API sets the 'Content Type' field of the response. The default
   --  content type is 'text/html'.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - This API only sets the content type to this value. The type isn't
   --      sent out until any of the send APIs is executed.
   --    - Make sure that the lifetime of the type string is valid till send
   --      function is called.
   --  @param req The request being responded to
   --  @param mime The Content Type of the response
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   function httpd_resp_set_hdr
     (req   : in out httpd_req_t;
      field : ESPIDF.C_Strings.const_char_ptr;
      value : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_set_hdr";
   --  API to append any additional headers.
   --
   --  This API sets any additional header fields that need to be sent in
   --  the response.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - The header isn't sent out until any of the send APIs is executed.
   --    - The maximum allowed number of additional headers is limited to
   --      value of max_resp_headers in config structure.
   --    - Make sure that the lifetime of the field value strings are valid
   --      till send function is called.
   --  @param req The request being responded to
   --  @param field The field name of the HTTP header
   --  @param value The value of this HTTP header
   --  @return
   --    - `ESP_OK` if new header was appended successfully
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if total additional headers exceed max
   --      allowed
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   procedure httpd_resp_set_hdr
     (req   : in out httpd_req_t;
      field : ESPIDF.C_Strings.const_char_ptr;
      value : ESPIDF.C_Strings.const_char_ptr);
   --  API to append any additional headers.
   --
   --  This API sets any additional header fields that need to be sent in
   --  the response.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - The header isn't sent out until any of the send APIs is executed.
   --    - The maximum allowed number of additional headers is limited to
   --      value of max_resp_headers in config structure.
   --    - Make sure that the lifetime of the field value strings are valid
   --      till send function is called.
   --  @param req The request being responded to
   --  @param field The field name of the HTTP header
   --  @param value The value of this HTTP header
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if total additional headers exceed max
   --      allowed
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   function httpd_resp_send_err
     (req   : in out httpd_req_t;
      error : httpd_err_code_t;
      msg   : ESPIDF.C_Strings.const_char_ptr) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_send_err";
   --  For sending out error code in response to HTTP request.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --    - If you wish to send additional data in the body of the response,
   --      please use the lower-level functions directly.
   --  @param req The HTTP request for which the response needs to be sent
   --  @param error Error type to send
   --  @param msg Error message string (pass null for default message)
   --  @return
   --    - `ESP_OK` if response packet was sent successfully
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   procedure httpd_resp_send_err
     (req   : in out httpd_req_t;
      error : httpd_err_code_t;
      msg   : ESPIDF.C_Strings.const_char_ptr);
   --  For sending out error code in response to HTTP request.
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --    - If you wish to send additional data in the body of the response,
   --      please use the lower-level functions directly.
   --  @param req The HTTP request for which the response needs to be sent
   --  @param error Error type to send
   --  @param msg Error message string (pass null for default message)
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   function httpd_resp_send
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_send";
   --  API to send a complete HTTP response.
   --
   --  This API will send the data as an HTTP response to the request. This
   --  assumes that you have the entire response ready in a single buffer.
   --  If you wish to send response in incremental chunks use
   --  `httpd_resp_send_chunk` instead.
   --
   --  If no status code and content-type were set, by default this will
   --  send 200 OK status code and content type as text/html. You may call
   --  the following functions before this API to configure the response
   --  headers:
   --    - `httpd_resp_set_status` - for setting the HTTP status string,
   --    - `httpd_resp_set_type` - for setting the Content Type,
   --    - `httpd_resp_set_hdr` - for appending any additional field value
   --      entries in the response header
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - Once this API is called, the request has been responded to.
   --    - No additional data can then be sent for the request.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --  @param req The request being responded to
   --  @param buf Buffer from where the content is to be fetched
   --  @param buf_len
   --    Length of the buffer, -1 (`HTTPD_RESP_USE_STRLEN`) to use length of
   --    the null terminated string
   --  @return
   --    - `ESP_OK` if response packet was sent successfully
   --    - `ESP_ERR_INVALID_ARG` if request pointer is null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if essential headers are too large for
   --      internal buffer
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request is invalid

   procedure httpd_resp_send
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t);
   --  API to send a complete HTTP response.
   --
   --  This API will send the data as an HTTP response to the request. This
   --  assumes that you have the entire response ready in a single buffer.
   --  If you wish to send response in incremental chunks use
   --  `httpd_resp_send_chunk` instead.
   --
   --  If no status code and content-type were set, by default this will
   --  send 200 OK status code and content type as text/html. You may call
   --  the following functions before this API to configure the response
   --  headers:
   --    - `httpd_resp_set_status` - for setting the HTTP status string,
   --    - `httpd_resp_set_type` - for setting the Content Type,
   --    - `httpd_resp_set_hdr` - for appending any additional field value
   --      entries in the response header
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - Once this API is called, the request has been responded to.
   --    - No additional data can then be sent for the request.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --  @param req The request being responded to
   --  @param buf Buffer from where the content is to be fetched
   --  @param buf_len
   --    Length of the buffer, -1 (`HTTPD_RESP_USE_STRLEN`) to use length of
   --    the null terminated string
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if request pointer is null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if essential headers are too large for
   --      internal buffer
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request is invalid

   function httpd_resp_send_chunk
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t) return esp_err_t
     with Import, Convention => C, External_Name => "httpd_resp_send_chunk";
   --  API to send one HTTP chunk.
   --
   --  This API will send the data as an HTTP response to the request. This
   --  API will use chunked-encoding and send the response in the form of
   --  chunks. If you have the entire response contained in a single buffer,
   --  please use `httpd_resp_send` instead.
   --
   --  If no status code and content-type were set, by default this will
   --  send 200 OK status code and content type as text/html. You may call
   --  the following functions before this API to configure the response
   --  headers:
   --    - `httpd_resp_set_status` - for setting the HTTP status string,
   --    - `httpd_resp_set_type` - for setting the Content Type,
   --    - `httpd_resp_set_hdr` - for appending any additional field value
   --      entries in the response header
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - When you are finished sending all your chunks, you must call this
   --      function with `buf_len` as 0.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --  @param req The request being responded to
   --  @param buf Pointer to a buffer that stores the data
   --  @param buf_len
   --    Length of the buffer, -1 (`HTTPD_RESP_USE_STRLEN`) to use length of
   --    the null terminated string
   --  @return
   --    - `ESP_OK` if response packet chunk was sent successfully
   --    - `ESP_ERR_INVALID_ARG` if request pointer is null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if essential headers are too large for
   --      internal buffer
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   procedure httpd_resp_send_chunk
     (req     : in out httpd_req_t;
      buf     : System.Address;
      buf_len : ssize_t);
   --  API to send one HTTP chunk.
   --
   --  This API will send the data as an HTTP response to the request. This
   --  API will use chunked-encoding and send the response in the form of
   --  chunks. If you have the entire response contained in a single buffer,
   --  please use `httpd_resp_send` instead.
   --
   --  If no status code and content-type were set, by default this will
   --  send 200 OK status code and content type as text/html. You may call
   --  the following functions before this API to configure the response
   --  headers:
   --    - `httpd_resp_set_status` - for setting the HTTP status string,
   --    - `httpd_resp_set_type` - for setting the Content Type,
   --    - `httpd_resp_set_hdr` - for appending any additional field value
   --      entries in the response header
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - When you are finished sending all your chunks, you must call this
   --      subprogram with `buf_len` as 0.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --  @param req The request being responded to
   --  @param buf Pointer to a buffer that stores the data
   --  @param buf_len
   --    Length of the buffer, -1 (`HTTPD_RESP_USE_STRLEN`) to use length of
   --    the null terminated string
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if request pointer is null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if essential headers are too large for
   --      internal buffer
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   function httpd_resp_send_chunk
     (req    : in out httpd_req_t;
      Buffer : A0B.Buffers.Abstract_Buffer'Class) return esp_err_t;
   --  API to send one HTTP chunk.
   --
   --  This API will send the data as an HTTP response to the request. This
   --  API will use chunked-encoding and send the response in the form of
   --  chunks. If you have the entire response contained in a single buffer,
   --  please use `httpd_resp_send` instead.
   --
   --  If no status code and content-type were set, by default this will
   --  send 200 OK status code and content type as text/html. You may call
   --  the following functions before this API to configure the response
   --  headers:
   --    - `httpd_resp_set_status` - for setting the HTTP status string,
   --    - `httpd_resp_set_type` - for setting the Content Type,
   --    - `httpd_resp_set_hdr` - for appending any additional field value
   --      entries in the response header
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - When you are finished sending all your chunks, you must call this
   --      function with empty `Buffer`.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --  @param req The request being responded to
   --  @param Buffer
   --    The buffer that stores the data. Actual length of the buffer's data
   --    is sent.
   --  @return
   --    - `ESP_OK` if response packet chunk was sent successfully
   --    - `ESP_ERR_INVALID_ARG` if request pointer is null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if essential headers are too large for
   --      internal buffer
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   procedure httpd_resp_send_chunk
     (req    : in out httpd_req_t;
      Buffer : A0B.Buffers.Abstract_Buffer'Class);
   --  API to send one HTTP chunk.
   --
   --  This API will send the data as an HTTP response to the request. This
   --  API will use chunked-encoding and send the response in the form of
   --  chunks. If you have the entire response contained in a single buffer,
   --  please use `httpd_resp_send` instead.
   --
   --  If no status code and content-type were set, by default this will
   --  send 200 OK status code and content type as text/html. You may call
   --  the following functions before this API to configure the response
   --  headers:
   --    - `httpd_resp_set_status` - for setting the HTTP status string,
   --    - `httpd_resp_set_type` - for setting the Content Type,
   --    - `httpd_resp_set_hdr` - for appending any additional field value
   --      entries in the response header
   --
   --  Note:
   --    - This API is supposed to be called only from the context of a URI
   --      handler where `req` is valid.
   --    - When you are finished sending all your chunks, you must call this
   --      subprogram with empty `Buffer`.
   --    - Once this API is called, all request headers are purged, so
   --      request headers need be copied into separate buffers if they are
   --      required later.
   --  @param req The request being responded to
   --  @param Buffer
   --    The buffer that stores the data. Actual length of the buffer's data
   --    is sent.
   --  @raise ESPIDF_Error raised on error:
   --    - `ESP_ERR_INVALID_ARG` if request pointer is null
   --    - `ESP_ERR_HTTPD_RESP_HDR` if essential headers are too large for
   --      internal buffer
   --    - `ESP_ERR_HTTPD_RESP_SEND` if error happened in raw send
   --    - `ESP_ERR_HTTPD_INVALID_REQ` if request pointer is invalid

   function httpd_query_key_value
     (qry      : ESPIDF.C_Strings.const_char_ptr;
      key      : ESPIDF.C_Strings.const_char_ptr;
      val      : ESPIDF.C_Strings.char_ptr;
      val_size : size_t) return esp_err_t
     with Import, Convention => C,
          External_Name => "httpd_query_key_value";
   --  Helper function to get a URL query tag from a query string of the
   --  type param1=val1&param2=val2.
   --
   --  Note:
   --    - The components of URL query string (keys and values) are not
   --      URLdecoded. The user must check for 'Content-Type' field in the
   --      request headers and then depending upon the specified encoding
   --      (URLencoded or otherwise) apply the appropriate decoding
   --      algorithm.
   --    - If actual value size is greater than `val_size`, then the value is
   --      truncated, accompanied by truncation error as return value.
   --  @param qry Pointer to query string
   --  @param key The key to be searched in the query string
   --  @param val
   --    Pointer to the buffer into which the value will be copied if the key
   --    is found
   --  @param val_size Size of the user buffer `val`
   --  @return
   --    - `ESP_OK` if key is found in the URL query string and copied to
   --      buffer
   --    - `ESP_ERR_NOT_FOUND` if key is not found
   --    - `ESP_ERR_INVALID_ARG` if arguments are null
   --    - `ESP_ERR_HTTPD_RESULT_TRUNC` if value string is truncated

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
