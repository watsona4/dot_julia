#!/usr/bin/env julia

using DropboxSDK

# Execute the command
exit_code = DropboxSDK.DropboxCLI.main(Base.ARGS)
exit(exit_code)
