#!/bin/bash
{
  "${PREFIX}/bin/jupyter-nbextensions_configurator" enable --sys-prefix
} >>"${PREFIX}/.messages.txt" 2>&1
