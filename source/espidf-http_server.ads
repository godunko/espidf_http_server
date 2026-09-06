--
--  Copyright (C) 2026, Vadim Godunko
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Extensions_Allowed (On);
--  Aspect `Finalizable` is used to initialize objects automaically

private with System.Storage_Elements;

package ESPIDF.HTTP_Server is

   type httpd_config_t is limited private;

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

end ESPIDF.HTTP_Server;
