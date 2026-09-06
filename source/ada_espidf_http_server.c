/*
 *  Copyright (C) 2026, Vadim Godunko
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

#include "esp_http_server.h"

int __ada_sizeof_httpd_config_t = sizeof(httpd_config_t);

void __ada_HTTPD_DEFAULT_CONFIG(httpd_config_t *cfg)
{
    *cfg = (httpd_config_t)HTTPD_DEFAULT_CONFIG();
}
