/*
 *  Copyright (C) 2026, Vadim Godunko
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "esp_http_server.h"

int __ada_sizeof_httpd_config_t = sizeof(httpd_config_t);
int __ada_sizeof_httpd_req_t    = sizeof(httpd_req_t);

void __ada_HTTPD_DEFAULT_CONFIG(httpd_config_t *cfg)
{
    *cfg = (httpd_config_t)HTTPD_DEFAULT_CONFIG();
}

size_t __ada_Get_httpd_req_t_content_len(httpd_req_t *req)
{
    return req->content_len;
}

esp_err_t __ada_httpd_register_uri_handler(httpd_handle_t handle, const char* uri, httpd_method_t method, esp_err_t (*handler)(httpd_req_t*), void* user_ctx)
{
    httpd_uri_t uri_handler =
    {
        .uri      = uri,
        .method   = method,
        .handler  = handler,
        .user_ctx = user_ctx
    };

    return httpd_register_uri_handler(handle, &uri_handler);
}