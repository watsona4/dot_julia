from IPython.terminal.prompts import Prompts, Token


class JuliaModePrompt(Prompts):

    def in_prompt_tokens(self):
        return [
            (Token.Prompt, "ipy "),
            (Token.PromptNum, str(self.shell.execution_count)),
            (Token.Prompt, "> "),
        ]

    def out_prompt_tokens(self):
        return []
