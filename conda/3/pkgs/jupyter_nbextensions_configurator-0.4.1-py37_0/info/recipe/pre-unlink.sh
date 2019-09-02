#!/bin/bash
{
  "${PREFIX}/bin/jupyter-nbextensions_configurator" disable --sys-prefix
} >>"${PREFIX}/.messages.txt" 2>&1
