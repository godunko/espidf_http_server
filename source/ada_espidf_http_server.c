/*
 *  Copyright (C) 2026, Vadim Godunko
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "esp_http_server.h"

int __ada_sizeof_httpd_config_t = sizeof(httpd_config_t);
int __ada_sizeof_httpd_req_t    = sizeof(httpd_req_t);
int __ada_sizeof_httpd_uri_t    = sizeof(httpd_uri_t);

void __ada_HTTPD_DEFAULT_CONFIG(httpd_config_t *cfg)
{
    *cfg = (httpd_config_t)HTTPD_DEFAULT_CONFIG();
}

void __ada_httpd_uri_t_create(void* storage, const char* uri, httpd_method_t method, esp_err_t (*handler)(httpd_req_t*), void* user_ctx)
{
    httpd_uri_t* result = (httpd_uri_t*)storage;
    *result = (httpd_uri_t){
        .uri      = uri,
        .method   = method,
        .handler  = handler,
        .user_ctx = user_ctx
    };
}